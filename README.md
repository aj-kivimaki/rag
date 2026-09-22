# RAG

A Retrieval-Augmented Generation project built with **n8n, Ollama, Supabase, and Python**.

The goal is to build and understand a complete RAG workflow using local AI models where practical.

## Stack

- **n8n** — workflow orchestration and AI Agent
- **Ollama** — local LLMs and embeddings
- **Supabase / pgvector** — vector storage and retrieval
- **Python** — application layer and experimentation
- **Docker / Colima** — local n8n environment

## Current Status

- [x] Local n8n running in Docker
- [x] Ollama running locally
- [x] Ollama accessible from n8n
- [x] n8n Chat Trigger
- [x] n8n AI Agent
- [x] Ollama Chat Model connected
- [x] `llama3:1:8b` and `llama3.2:3b` installed
- [x] `nomic-embed-text` installed
- [x] Supabase / pgvector
- [x] Document ingestion
- [x] Vector embeddings
- [x] Vector retrieval
- [x] AI Agent retrieval tool
- [ ] Chat memory
- [x] Complete end-to-end RAG workflow

## Current Workflows

### RAG - Chat

```text
Chat Trigger
     ↓
  AI Agent
     ↓
Supabase Vector Store
     ↓
Relevant document chunks
     ↓
Ollama Chat Model
     ↓
    Answer
```

The AI Agent uses the Supabase Vector Store as a tool for retrieving relevant information from the knowledge base.

### RAG - Ingest Documents

```text
Manual Trigger
     ↓
Edit Fields
     ↓
Default Data Loader
     ↓
Text splitting
     ↓
Ollama Embeddings
     ↓
Supabase / pgvector
```

The ingestion workflow currently uses the `documents` table in Supabase and `nomic-embed-text` for 768-dimensional embeddings.

## Local AI

Ollama runs directly on the Mac.

Current models:

```text
llama3.1:8b       → LLM
llama3.2:3b       → LLM
nomic-embed-text  → embeddings
```

## Supabase

The project uses PostgreSQL with the `pgvector` extension.

The `documents` table stores:

- document content
- metadata
- 768-dimensional embeddings

Vector similarity search is used to retrieve relevant document chunks for the AI Agent.

## Project Structure

```text
rag/
├── app/
├── n8n/
│   └── data/
├── .venv/
├── docker-compose.yml
├── requirements.txt
├── .gitignore
├── README.md
└── ARCHITECTURE.md
```

## Running

Start Colima if needed:

```bash
colima start --port-forwarder=grpc
```

Start n8n:

```bash
docker compose up -d
```

Open:

```text
http://localhost:5678
```

Start Ollama:

```bash
ollama serve
```

Check installed models:

```bash
ollama list
ollama ps
```

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for the current and planned architecture.
