# Local RAG

A local Retrieval-Augmented Generation (RAG) project built with **n8n,
Ollama, Supabase/pgvector, and Python**.

The project focuses on building a practical RAG pipeline with local AI
models, document ingestion, vector retrieval, and conversational memory.

## Stack

-   **n8n** --- workflow orchestration and AI Agent
-   **Ollama** --- local LLM inference and embeddings
-   **Supabase / PostgreSQL / pgvector** --- vector storage, similarity
    search, and chat memory
-   **Python** --- local Ollama experimentation
-   **Docker / Colima** --- local n8n environment on macOS

## Current Status

The core local RAG workflow is working end-to-end.

-   [x] Local n8n in Docker/Colima
-   [x] Local Ollama inference and embeddings
-   [x] Supabase PostgreSQL + pgvector
-   [x] PDF ingestion and text splitting
-   [x] Vector retrieval through Supabase
-   [x] AI Agent retrieval tool
-   [x] PostgreSQL chat memory
-   [x] Multiple-document knowledge base
-   [x] Safe re-ingestion without duplicate vectors
-   [x] End-to-end RAG question answering

The current setup has been tested with multiple documents, re-ingestion,
vector retrieval, and conversational memory.

## Local AI

The current chat model is `qwen3:1.7b`. Embeddings use
`nomic-embed-text`.

The embedding model produces 768-dimensional vectors.

Other local models were tested during development to compare
performance. Detailed configuration and measurements are documented in
[ARCHITECTURE.md](ARCHITECTURE.md).

## Project Structure

``` text
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

The `documents/` directory contains local knowledge-base files and is
excluded from Git.

## Running Locally

Start Colima with the required gRPC port forwarder:

``` bash
colima start --port-forwarder=grpc
```

Start n8n:

``` bash
docker compose up -d
```

Start Ollama:

``` bash
ollama serve
```

Open n8n:

``` text
http://localhost:5678
```

Check Ollama:

``` bash
ollama list
ollama ps
```

## Documentation

-   [ARCHITECTURE.md](ARCHITECTURE.md) --- system architecture,
    workflows, data flow, networking, and implementation details
