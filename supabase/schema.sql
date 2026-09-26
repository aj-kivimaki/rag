-- Supabase schema for the RAG workflows.
-- Run once in the Supabase SQL Editor.
--
-- The n8n Supabase Vector Store node inserts into `documents`
-- and retrieves through the `match_documents` function.
-- The embedding dimension (768) matches `nomic-embed-text`.
--
-- The chat memory table (`n8n_chat_histories`) is created
-- automatically by the n8n Postgres Chat Memory node.

create extension if not exists vector;

create table documents (
  id bigserial primary key,
  content text,
  metadata jsonb,
  embedding vector(768)
);

create function match_documents (
  query_embedding vector(768),
  match_count int default null,
  filter jsonb default '{}'
) returns table (
  id bigint,
  content text,
  metadata jsonb,
  similarity float
)
language plpgsql
as $$
#variable_conflict use_column
begin
  return query
  select
    id,
    content,
    metadata,
    1 - (documents.embedding <=> query_embedding) as similarity
  from documents
  where metadata @> filter
  order by documents.embedding <=> query_embedding
  limit match_count;
end;
$$;
