# Architecture

This document describes the architecture of the RAG system. The [README](README.md) covers the project overview, features, and setup.

The workflow definitions are in [`workflows/`](workflows/) and the database schema is in [`supabase/schema.sql`](supabase/schema.sql).

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
          ┌──────┴──────┐              ┌──────-┴─────┐
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

**Local:** Ollama, n8n, Docker/Colima, and source documents.

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

The retrieval limit is **2 chunks** (top-k = 2).

Execution details of a chat run: the agent calls the chat model, uses the vector store tool (query embedding + similarity search), then calls the chat model again to write the answer. Chat memory is read and written in Supabase.

![RAG Chat execution](pics/RAG-chat.png)

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

The ingestion workflow is run manually and processes **one PDF per run**:

1. Reads the PDF whose path is set in the **Read/Write Files from Disk** node. The local `documents/` directory is mounted read-only into n8n at `/home/node/.n8n-files`.
2. Deletes existing chunks for that file (`DELETE FROM documents WHERE metadata->>'source' = $1`, parameterized with the filename).
3. Waits for the delete to finish (Merge node) before inserting.
4. Loads and splits the document with the Default Data Loader.
5. Generates embeddings locally with `nomic-embed-text`.
6. Stores chunks, embeddings, and the filename as `source` metadata in Supabase.

Re-ingesting a document replaces its existing chunks, preventing duplicate vectors. To add more documents, change the file path and run the workflow again; multiple documents coexist in the same vector store.

![RAG Ingest Documents execution](pics/RAG-ingest-documents.png)

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

Configuration:

- thinking disabled
- concise 3–5 bullet responses (set in the AI Agent system prompt)

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

After disabling thinking and reducing retrieval from 4 to 2 chunks, Qwen3 chat executions took roughly **35 seconds to 1.5 minutes**, using about **1,100–1,300 tokens**. The chat execution shown in the [RAG Chat Workflow](#rag-chat-workflow) section took 1 min 24 s (~1,228 tokens).

All timings were measured on the development machine, an older Intel Mac. They are development measurements, not general model benchmarks.

## Supabase

Supabase provides:

- PostgreSQL
- pgvector
- document chunk and embedding storage
- vector similarity search
- n8n chat memory

The `documents` table uses a 768-dimensional vector column matching `nomic-embed-text`.

Supabase is the **cloud component** of the architecture. AI inference remains local.

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
