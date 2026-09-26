# Architecture

This document describes the architecture of the RAG system. The [README](README.md) covers the project overview, setup, and current status.

## System Architecture

```text
                              macOS
                                │
                 ┌──────────────┴──────────────┐
                 │                             │
              Ollama                        Colima
                 │                             │
          Local AI models                 Docker / n8n
                 │                             │
          ┌──────┴──────┐              ┌──────┴──────┐
          │             │              │             │
       Qwen3       Nomic Embed      RAG - Chat   RAG - Ingest
          │             │              │             │
          │             │           AI Agent         │
          │             │              │             │
          └─────────────┼──────────────┼─────────────┘
                        │              │
                        │              ▼
                        │       Supabase PostgreSQL
                        │       + pgvector
                        │              │
                        │       ┌──────┴──────┐
                        │       │             │
                        │    Vectors      Chat Memory
                        │
                        └── local inference
```

**Local:** Ollama, n8n, Docker/Colima, Python, and source documents.

**Cloud:** Supabase PostgreSQL/pgvector, document vectors, and chat memory.

Ollama performs LLM inference and embedding generation locally. Supabase provides the persistent database and vector storage.

## RAG Chat Workflow

```text
User question
      │
      ▼
   AI Agent
   ┌──┼──────────────┐
   │  │              │
   ▼  ▼              ▼
Ollama  Chat       Supabase
Qwen3   Memory     Vector Store
   │                   │
   │             Ollama Embeddings
   │                   │
   └─────────┬─────────┘
             ▼
          Answer
```

The AI Agent uses:

- `qwen3:1.7b` for local answer generation
- `nomic-embed-text` for local query embeddings
- Supabase Vector Store for retrieval
- PostgreSQL-backed chat memory

The current retrieval limit is **2 chunks**.

## Document Ingestion

```text
Local PDF
   │
   ▼
n8n Data Loader
   │
   ├── Load & split
   │
   ▼
Ollama / nomic-embed-text
   │
   │ embeddings
   ▼
Supabase pgvector
```

The ingestion workflow:

1. Reads PDFs from the local `documents/` directory.
2. Uses the filename as `source` metadata.
3. Removes existing chunks for that source.
4. Loads and splits the document.
5. Generates embeddings locally.
6. Stores chunks and embeddings in Supabase.

Re-ingesting a document replaces its existing chunks, preventing duplicate vectors. Multiple documents can coexist in the same vector store.

Example metadata:

```json
{
  "source": "document.pdf"
}
```

## Retrieval

```text
Question
   │
   ▼
Ollama / nomic-embed-text
   │
   │ query embedding
   ▼
Supabase / pgvector
   │
   │ similarity search
   ▼
Relevant chunks
   │
   ▼
AI Agent
   │
   ▼
Ollama / qwen3:1.7b
   │
   ▼
Answer
```

The `documents` table contains:

- text content
- JSON metadata
- 768-dimensional embeddings

The `match_documents` function performs the vector similarity search used by the Supabase Vector Store.

## Chat Memory

n8n uses PostgreSQL-backed chat memory:

```text
Chat Trigger
     ↓
  AI Agent
     ↓
Postgres Chat Memory
     ↓
Supabase PostgreSQL
```

Conversation history is therefore stored in Supabase rather than locally.

## Models

### Chat

```text
qwen3:1.7b
```

Current configuration:

- thinking disabled
- concise 3–5 bullet responses

### Embeddings

```text
nomic-embed-text
```

Embedding dimension: **768**

Other models tested during development:

| Model        | Approx. RAG time | Result                              |
| ------------ | ---------------: | ----------------------------------- |
| Llama 3.1 8B |     ~5 min 5 sec | Correct retrieval and summarization |
| Llama 3.2 3B |    ~2 min 26 sec | Correct retrieval and summarization |
| Qwen3 1.7B   |           ~2 min | Usable retrieval and answer         |

After disabling thinking and reducing retrieval from 4 to 2 chunks, Qwen3 executions were approximately **34–40 seconds**, with roughly **1,100–1,300 tokens** on the development machine.

These figures are development measurements, not general model benchmarks.

## Supabase

Supabase provides:

- PostgreSQL
- pgvector
- document chunk and embedding storage
- vector similarity search
- n8n chat memory

The `documents` table uses a 768-dimensional vector column matching `nomic-embed-text`.

Supabase is the **cloud component** of the current architecture. AI inference remains local.

## Networking

```text
macOS
│
├── Ollama :11434
│
└── Colima
     │
     └── Docker
          │
          └── n8n :5678
```

Ollama is exposed to n8n through:

```text
http://host.docker.internal:11434
```

n8n is available locally at:

```text
http://localhost:5678
```

Colima uses the gRPC port forwarder:

```bash
colima start --port-forwarder=grpc
```

n8n connects to Supabase over the network for vector retrieval and chat memory.

## Python

Python is used for local Ollama testing and experimentation.

The Python Ollama client has been tested successfully against the local Ollama server.

Python is not currently part of the main n8n RAG execution path.
