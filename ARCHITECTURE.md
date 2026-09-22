# Architecture

This document describes the technical architecture of the current local
RAG system. The README contains the project overview, status, stack, and
setup instructions; implementation details belong here.

## System Architecture

```text
                         macOS
                           │
             ┌─────────────┴─────────────┐
             │                           │
          Ollama                      Colima
             │                           │
             │                      Docker / n8n
             │                           │
             │                 ┌─────────┴─────────┐
             │                 │                   │
             │             RAG - Chat       RAG - Ingest
             │                 │                   │
             └──────────────► AI Agent             │
                               │                   │
                    ┌──────────┼──────────┐        │
                    │          │          │        │
                 Ollama     Postgres   Supabase    │
                  Chat       Chat       Vector     │
                  Model     Memory       Store     │
                                         │         │
                                 Ollama Embeddings │
```

n8n runs inside Docker/Colima.

Ollama runs directly on macOS.

## RAG Chat Workflow

```text
When chat message received
            │
            ▼
         AI Agent
        /    │     \
       ▼     ▼      ▼
   Ollama  Postgres  Supabase
    Chat     Chat     Vector
   Model    Memory     Store
                       │
                       ▼
                Ollama Embeddings
```

The AI Agent uses:

- `qwen3:1.7b` for local generation
- PostgreSQL-backed chat memory
- Supabase Vector Store as the retrieval tool

For document-related questions, the agent is instructed to retrieve
relevant context before answering.

The current Vector Store retrieval limit is **2 chunks**.

## Document Ingestion

```text
Manual Trigger
      ↓
Read File(s) from Disk
      ├──────────────→ Merge
      ↓
Postgres
      └──────────────→ Merge
                         ↓
                  Wait for both
                         ↓
              Supabase Vector Store
                    ↑           ↑
                    │           │
              Data Loader   Ollama Embeddings
```

The ingestion workflow:

1.  Reads a PDF from the local `documents` directory.
2.  Uses the filename as `source` metadata.
3.  Deletes existing chunks for that source.
4.  Loads and splits the document.
5.  Generates embeddings with `nomic-embed-text`.
6.  Stores the chunks and embeddings in Supabase pgvector.

Example metadata:

```json
{
  "source": "document.pdf"
}
```

This makes re-ingestion idempotent: re-ingesting the same document
replaces its existing chunks rather than creating duplicates.

Multiple documents can coexist in the same vector store. Ingesting one
document does not delete another document's chunks.

## Retrieval Flow

```text
User question
      ↓
   AI Agent
      ↓
Query embedding
      ↓
Supabase Vector Store
      ↓
Relevant chunks
      ↓
   AI Agent
      ↓
Qwen3 1.7B
      ↓
   Answer
```

The Supabase Vector Store uses Ollama embeddings for the query and
performs vector similarity search against the `documents` table.

The current database contains document chunks with:

- text content
- JSON metadata
- 768-dimensional embeddings

The `match_documents` function provides the vector similarity search
used by the Supabase Vector Store.

## Chat Memory

PostgreSQL-backed n8n Chat Memory stores conversational history.

```text
Chat Trigger
      ↓
   AI Agent
      │
      ▼
Postgres Chat Memory
      │
      ▼
Supabase PostgreSQL
```

Memory was tested independently and together with RAG. The agent can use
previous conversation context while retrieving information from the
vector store.

## Models

### Chat model

```text
qwen3:1.7b
```

Current settings:

- thinking disabled
- concise 3--5 bullet responses

### Embedding model

```text
nomic-embed-text
```

Embedding dimension:

```text
768
```

Other models tested during development:

Model Size Approx. RAG time Result

---

Llama 3.1 8B \~5 min 5 sec Correct retrieval and summarization
Llama 3.2 3B \~2 min 26 sec Correct retrieval and summarization
Qwen3 1.7B \~2 min Usable retrieval and answer

After disabling thinking and reducing retrieval from 4 chunks to 2,
tested Qwen3 RAG executions were approximately **34--40 seconds**, with
roughly **1,100--1,300 tokens**.

## Supabase

Supabase provides:

- PostgreSQL
- pgvector
- document storage for chunks and embeddings
- vector similarity search
- PostgreSQL storage for n8n chat memory

The `documents` table uses a 768-dimensional vector column to match
`nomic-embed-text`.

## Local Networking

```text
Mac
│
├── Ollama :11434
│      ▲
│      │ host.docker.internal
│      │
└── Colima
       │
       └── Docker
              │
              └── n8n :5678
```

Ollama on macOS:

```text
http://localhost:11434
```

Ollama from inside n8n:

```text
http://host.docker.internal:11434
```

n8n:

```text
http://localhost:5678
```

Colima uses the gRPC port forwarder so published Docker ports are
reachable from macOS:

```bash
colima start --port-forwarder=grpc
```

## Python

Python is currently used for local Ollama testing and experimentation.

The Python Ollama client has been tested successfully against the local
Ollama server.

Python is not currently part of the main n8n RAG execution path.
