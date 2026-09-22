# Architecture

## Current Setup

```text
                         macOS

              ┌────────────┴────────────┐
              │                         │
           Ollama                    Colima
              │                         │
              │                    Docker / n8n
              │                         │
              │                 ┌───────┴────────┐
              │                 │                │
              │            RAG - Chat     RAG - Ingest
              │                 │                │
              └──────────────► AI Agent          │
                                │                │
                    ┌───────────┼───────────┐    │
                    │           │           │    │
               Ollama Chat   Postgres   Supabase │
                  Model       Chat       Vector  │
                             Memory       Store  │
                                                 │
                                         Ollama Embeddings
```

n8n runs inside Docker/Colima.

Ollama runs directly on macOS.

The n8n container reaches Ollama through:

```text
http://host.docker.internal:11434
```

Ollama is available locally at:

```text
http://localhost:11434
```

The connection has been tested successfully from inside the n8n
container.

n8n is available at:

```text
http://localhost:5678
```

## Current RAG Chat Workflow

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
- Supabase Vector Store for document retrieval
- `nomic-embed-text` for embeddings

For document-related questions, the AI Agent is configured to use the
Supabase Vector Store before answering.

## Current Document Ingestion Workflow

```text
Manual Trigger
      ↓
Read File(s) from Disk
      ├──────────────→ Merge (Input 1)
      ↓
Postgres
      └──────────────→ Merge (Input 2)
                         ↓
                  Choose Branch
                  Wait for both
                  Output Input 1
                         ↓
              Supabase Vector Store
                    ↑           ↑
                    │           │
          Default Data       Ollama
             Loader        Embeddings
```

The ingestion workflow:

1.  Reads a PDF from the local `documents` directory.
2.  Deletes existing chunks for that document using its `source`
    metadata.
3.  Waits for the deletion to complete.
4.  Loads and splits the document.
5.  Adds source metadata to each chunk.
6.  Generates embeddings locally with Ollama.
7.  Stores the chunks and embeddings in Supabase pgvector.

The `source` metadata is used to make re-ingestion safe:

```json
{
  "source": "document.pdf"
}
```

Re-ingesting the same document replaces its existing chunks instead of
creating duplicates.

Multiple documents can coexist in the same vector store. Ingestion of
one document does not remove chunks belonging to other documents.

## Retrieval

```text
User question
      ↓
   AI Agent
      ↓
Ollama embedding
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

The current retrieval limit is **2 chunks** per query.

This was chosen after testing because it reduced execution time and
token usage while still producing relevant answers for the tested
questions.

## Current Database Layer

Supabase provides:

- PostgreSQL
- pgvector
- document chunks
- vector embeddings
- vector similarity search
- chat memory storage

The document table uses a 768-dimensional vector because
`nomic-embed-text` produces 768-dimensional embeddings.

Current test documents have been successfully ingested as separate
sources.

## Current Models

### Ollama

Local AI inference.

```text
qwen3:1.7b
    → generation

nomic-embed-text
    → embeddings
```

`qwen3:1.7b` is currently used for the RAG chat workflow with thinking
disabled.

Other local models were tested during development to compare speed and
answer quality.

## Model Performance

The same RAG workflow was tested with different local Ollama models:

---

Model Size Approx. time Result

---

Llama 3.1 8B \~5 min 5 sec Correctly
retrieved and
summarized the
document

Llama 3.2 3B \~2 min 26 sec Correctly
retrieved and
summarized the
document

Qwen3 1.7B \~2 min Retrieved the
document and
produced a
usable answer

---

Further optimization with Qwen3 reduced tested RAG executions to
approximately **34--40 seconds** by:

- disabling thinking
- reducing retrieval from 4 chunks to 2
- keeping responses concise

## n8n

Responsible for:

- workflow orchestration
- AI Agent
- document ingestion
- document retrieval
- model connections
- chat memory
- connecting local Ollama with Supabase

## Python

Python is currently used for testing and experimentation with Ollama.

The Python client has been tested successfully against the local Ollama
server.

Python is not currently part of the main n8n RAG workflow.

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

n8n:

```text
http://localhost:5678
```

Ollama:

```text
http://localhost:11434
```

Inside the n8n container, Ollama is reached through:

```text
http://host.docker.internal:11434
```

## Project Status

The core local RAG MVP is working end-to-end:

```text
Local PDF
   ↓
n8n ingestion
   ↓
Ollama embeddings
   ↓
Supabase pgvector
   ↓
User question
   ↓
Vector retrieval
   ↓
Qwen3 1.7B
   ↓
Grounded answer
```

The system has been tested with multiple documents, document
re-ingestion, vector retrieval, and PostgreSQL chat memory.
