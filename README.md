# Local RAG

A local Retrieval-Augmented Generation (RAG) project built with **n8n, Ollama, Supabase/pgvector, and Python**.

The project focuses on understanding and building a practical RAG pipeline with local AI models, document ingestion, vector retrieval, and conversational memory.

## Stack

- **n8n** — workflow orchestration, document ingestion, AI Agent, retrieval, and memory
- **Ollama** — local LLM inference and embeddings
- **Supabase / PostgreSQL / pgvector** — vector storage, similarity search, and chat memory
- **Python** — local Ollama experimentation
- **Docker / Colima** — local n8n environment on macOS

## Current Status

The core local RAG workflow is working end-to-end.

- [x] n8n running locally in Docker/Colima
- [x] Ollama running locally
- [x] n8n → Ollama connection
- [x] n8n Chat Trigger
- [x] n8n AI Agent
- [x] Local chat model with Ollama
- [x] Local embedding model with Ollama
- [x] Supabase PostgreSQL + pgvector
- [x] PDF document ingestion
- [x] Document loading and text splitting
- [x] Vector embeddings
- [x] Supabase Vector Store retrieval
- [x] AI Agent retrieval tool
- [x] Postgres Chat Memory
- [x] Multi-document knowledge base
- [x] Safe document re-ingestion without duplicate vectors
- [x] End-to-end RAG question answering

## Workflows

### RAG - Chat

```text
When chat message received
          ↓
       AI Agent
      ↙    ↓     ↘
 Chat Model  Memory  Vector Store
    ↓          ↓          ↓
 Ollama    Supabase    pgvector
                       + Ollama embeddings
          ↓
       Answer
```

The AI Agent uses the Supabase Vector Store as a tool. For document-related questions, the agent is instructed to retrieve relevant context before answering. The chat model is a local Ollama model, and Postgres Chat Memory keeps conversational context between messages.

### RAG - Ingest Documents

```text
Manual Trigger
      ↓
Read/Write Files from Disk
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
                 ↑              ↑
          Data Loader       Embeddings
```

The ingestion workflow adds a `source` metadata field to each document chunk. Before inserting new vectors, the Postgres node deletes existing chunks belonging to the same source. This makes re-ingestion idempotent: updating or re-running a document does not create duplicate vectors.

Multiple documents can coexist in the same knowledge base. The current test knowledge base contains two PDFs with separate source metadata.

## Local AI

Ollama runs directly on the Intel Mac and is accessed by the n8n container through:

```text
http://host.docker.internal:11434
```

Current models used in the project:

```text
qwen3:1.7b         → current local chat model
llama3.2:3b        → model comparison
nomic-embed-text   → embeddings
```

The embedding model produces **768-dimensional vectors**.

### Model Comparison

The same RAG question was tested with three local Ollama models using the same document and n8n workflow:

| Model | Size | Approx. time | Result |
|---|---:|---:|---|
| Llama 3.1 | 8B | ~5 min 5 sec | Correctly retrieved and summarized the document |
| Llama 3.2 | 3B | ~2 min 26 sec | Correctly retrieved and summarized the document |
| Qwen3 | 1.7B | ~2 min 0 sec | Retrieved the document and produced a usable answer |

Further testing with `qwen3:1.7b` showed that performance could be improved by:

- disabling model thinking
- reducing Vector Store retrieval from 4 chunks to 2
- keeping responses concise at 3–5 bullet points

In tested RAG queries, this reduced execution time to roughly **34–40 seconds** and reduced token usage to roughly **1,100–1,300 tokens**. Exact performance depends on the query and whether the agent decides retrieval is necessary.

## Supabase

The project uses PostgreSQL with the `pgvector` extension.

The `documents` table stores:

- document chunk content
- JSON metadata
- 768-dimensional embeddings

Each ingested chunk receives a `source` metadata field, which is used to identify and replace existing vectors during re-ingestion.

Vector similarity search is exposed through the Supabase `match_documents` function and the n8n Supabase Vector Store node.

Supabase PostgreSQL is also used by the n8n Postgres Chat Memory node.

## Project Structure

```text
rag/
├── app/
│   └── main.py
├── documents/
├── n8n/
│   └── data/
├── .venv/
├── docker-compose.yml
├── requirements.txt
├── .gitignore
├── README.md
└── ARCHITECTURE.md
```

The `documents/` directory contains local knowledge-base files and is excluded from Git. Test documents are referred to generically in the project documentation rather than committed to the repository.

## Running Locally

Start Colima with the required gRPC port forwarder:

```bash
colima start --port-forwarder=grpc
```

Start n8n:

```bash
docker compose up -d
```

Start Ollama:

```bash
ollama serve
```

Open n8n:

```text
http://localhost:5678
```

Check Ollama:

```bash
ollama list
ollama ps
```

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for the current system architecture and local networking setup.
