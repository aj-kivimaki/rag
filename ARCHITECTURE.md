# Architecture

## Current Setup

```text
                    macOS
                      │
          ┌───────────┴───────────┐
          │                       │
       Ollama                  Colima
          │                       │
          │                 Docker / n8n
          │                       │
          │                ┌──────┴──────┐
          │                │             │
          │          Chat Trigger    AI Agent
          │                              │
          └─────────────────────── Ollama Chat Model
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

The connection has been tested successfully from inside the n8n container.

## Current n8n Workflow

```text
When chat message received
          ↓
       AI Agent
          ↓
   Ollama Chat Model
          ↓
       Ollama
          ↓
    Local LLM
```

## Planned RAG Workflow

### Ingestion

```text
Documents
    ↓
n8n
    ↓
Load / split documents
    ↓
Ollama Embeddings
    ↓
Supabase / pgvector
```

### Retrieval

```text
User question
      ↓
   AI Agent
      ↓
Supabase Vector Store
      ↓
Relevant chunks
      ↓
   AI Agent
      ↓
Ollama Chat Model
      ↓
    Answer
```

## Planned Components

### Ollama

Local AI inference.

```text
llama3.1:8b
    → generation

nomic-embed-text
    → embeddings
```

### n8n

Responsible for:

- workflow orchestration
- AI Agent
- document ingestion
- retrieval
- model connections
- memory

### Supabase

Planned database layer:

- PostgreSQL
- pgvector
- document chunks
- embeddings
- vector similarity search
- chat memory

### Python

Python is currently used for testing and experimentation with Ollama.

It is not part of the n8n workflow yet.

## Local Networking

```text
Mac
└── Ollama :11434
       ▲
       │ host.docker.internal
       │
Docker / Colima
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
