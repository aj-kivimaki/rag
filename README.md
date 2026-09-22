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

### Completed

- [x] Local n8n running in Docker/Colima
- [x] Ollama running locally
- [x] Ollama accessible from n8n
- [x] n8n Chat Trigger
- [x] n8n AI Agent
- [x] Ollama Chat Model
- [x] `llama3.2:3b` installed
- [x] `qwen3:1.7b` installed
- [x] `nomic-embed-text` installed
- [x] Supabase / pgvector
- [x] Document ingestion from PDF
- [x] Document loading and text splitting
- [x] Vector embeddings
- [x] Vector retrieval through Supabase Vector Store
- [x] AI Agent retrieval tool
- [x] End-to-end RAG question answering

### Remaining

- [ ] Postgres Chat Memory
- [ ] Delete existing document vectors before re-ingesting updated documents
- [ ] Remove the initial test row from the `documents` table

## Workflows

### RAG - Chat

```text
When chat message received
          ↓
       AI Agent
       ↙      ↘
Ollama Chat   Supabase Vector Store
   Model              ↓
       ↘       Relevant chunks
        ↘           ↓
         ─────→ AI Agent
                    ↓
                 Answer
```

The AI Agent uses the Supabase Vector Store as a retrieval tool. Ollama provides the chat model, while `nomic-embed-text` converts the user's query into an embedding for vector search.

### RAG - Ingest Documents

```text
Manual Trigger
      ↓
Read/Write Files from Disk
      ↓
Default Data Loader
      ↓
Text splitting
      ↓
Ollama Embeddings
      ↓
Supabase Vector Store
```

Documents are loaded from the local `documents/` directory.

A test PDF (`test-document.pdf`) was successfully split into chunks and stored in the Supabase `documents` table with 768-dimensional embeddings.

## Local AI

Ollama runs directly on the Mac.

Current models:

```text
llama3.2:3b       → LLM
qwen3:1.7b        → smaller LLM for CPU testing
nomic-embed-text  → embeddings
```

The LLM can be swapped independently of the embedding model. Smaller models are being tested because LLM inference is CPU-bound on the current Intel Mac.

## Model Comparison

The same RAG question was tested with three local Ollama models using the same document and n8n workflow.

| Model     | Size |  Approx. time | Result                                              |
| --------- | ---: | ------------: | --------------------------------------------------- |
| Llama 3.1 |   8B |  ~5 min 5 sec | Correctly retrieved and summarized the document     |
| Llama 3.2 |   3B | ~2 min 26 sec | Correctly retrieved and summarized the document     |
| Qwen3     | 1.7B |  ~2 min 0 sec | Retrieved the document and produced a usable answer |

### Qwen3 performance optimization

Further testing was done with `qwen3:1.7b`:

- **Thinking disabled** — removed the `<think>` output and slightly reduced generation time.
- **Vector Store limit reduced from 4 to 2 chunks** — reduced the AI Agent execution from roughly 64 seconds to roughly 34–40 seconds in the tested RAG queries.
- Token usage dropped from roughly 2,000 tokens to roughly 1,100–1,300 tokens.
- Two retrieved chunks were sufficient for the tested questions while maintaining relevant, document-grounded answers.
- Some questions may be answered directly by the agent without calling the Vector Store, so those very fast responses are not considered valid RAG performance measurements.

Current RAG settings:

- Model: `qwen3:1.7b`
- Thinking: disabled
- Vector Store retrieval limit: 2 chunks
- Response format: 3–5 concise bullet points

These settings provide a practical balance between retrieval quality and response time on the local Intel Mac setup.

## Supabase

The `documents` table stores:

- document chunk content
- metadata
- 768-dimensional embeddings

Vector similarity search is exposed through the `match_documents` function and the n8n Supabase Vector Store node.

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

The `documents/` directory is excluded from Git because source documents are local knowledge-base data.

## Running

Start Colima with the required port forwarder:

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

## Remaining Work

The core RAG pipeline is working. The remaining pieces are mainly conversation memory and safe re-ingestion of updated documents:

1. Add **Postgres Chat Memory** to the AI Agent.
2. Add a document update/re-ingestion strategy that removes existing vectors before inserting new chunks.
3. Remove the original test row from the Supabase `documents` table.
