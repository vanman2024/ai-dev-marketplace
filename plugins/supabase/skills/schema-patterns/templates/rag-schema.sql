-- RAG (Retrieval-Augmented Generation) Schema
-- Optimized for document storage, chunking, and vector similarity search
-- Requires: pgvector extension
-- Includes: documents, document_chunks, embeddings, collections

-- Document collections for organization
create table if not exists public.document_collections (
    id uuid primary key default uuid_generate_v4(),
    name text not null,
    description text,
    metadata jsonb default '{}'::jsonb,
    created_by uuid references auth.users(id) on delete set null,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

-- Documents table
create table if not exists public.documents (
    id uuid primary key default uuid_generate_v4(),
    collection_id uuid references public.document_collections(id) on delete cascade,
    title text not null,
    content text not null,
    source_type text check (source_type in ('file', 'url', 'api', 'manual')),
    source_url text,
    file_type text,
    file_size bigint,
    metadata jsonb default '{}'::jsonb,
    created_by uuid references auth.users(id) on delete set null,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now(),
    deleted_at timestamp with time zone
);

-- Document chunks (split for embedding)
create table if not exists public.document_chunks (
    id uuid primary key default uuid_generate_v4(),
    document_id uuid not null references public.documents(id) on delete cascade,
    content text not null,
    chunk_index integer not null,

    -- Vector embedding column (384 dimensions for all-MiniLM-L6-v2)
    -- Change dimension based on your embedding model:
    -- - 384: all-MiniLM-L6-v2 (sentence-transformers)
    -- - 768: BERT-base models
    -- - 1536: OpenAI text-embedding-ada-002
    -- - 3072: OpenAI text-embedding-3-large
    embedding vector(384),

    -- Token count for the chunk
    token_count integer,

    -- Metadata about the chunk
    metadata jsonb default '{}'::jsonb,

    created_at timestamp with time zone default now(),

    constraint unique_document_chunk unique(document_id, chunk_index)
);

-- Alternative: Using halfvec for storage efficiency (16-bit instead of 32-bit)
-- Uncomment if you want to use halfvec to save ~50% storage
-- create table if not exists public.document_chunks_halfvec (
--     id uuid primary key default uuid_generate_v4(),
--     document_id uuid not null references public.documents(id) on delete cascade,
--     content text not null,
--     chunk_index integer not null,
--     embedding halfvec(1536), -- halfvec for OpenAI embeddings
--     token_count integer,
--     metadata jsonb default '{}'::jsonb,
--     created_at timestamp with time zone default now(),
--     constraint unique_document_chunk_halfvec unique(document_id, chunk_index)
-- );

-- Document processing status
create table if not exists public.document_processing_status (
    id uuid primary key default uuid_generate_v4(),
    document_id uuid not null references public.documents(id) on delete cascade,
    status text not null check (status in ('pending', 'processing', 'completed', 'failed')),
    progress_percent integer default 0 check (progress_percent >= 0 and progress_percent <= 100),
    chunks_created integer default 0,
    error_message text,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

-- Query logs for analytics
create table if not exists public.rag_query_logs (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id) on delete set null,
    query_text text not null,
    query_embedding vector(384),
    results_count integer,
    search_type text check (search_type in ('semantic', 'keyword', 'hybrid')),
    filters jsonb default '{}'::jsonb,
    response_time_ms integer,
    created_at timestamp with time zone default now()
);

-- Indexes for performance
create index if not exists idx_collections_created_by on public.document_collections(created_by);

create index if not exists idx_documents_collection on public.documents(collection_id);
create index if not exists idx_documents_created_by on public.documents(created_by);
create index if not exists idx_documents_deleted on public.documents(deleted_at) where deleted_at is null;
create index if not exists idx_documents_source_type on public.documents(source_type);

create index if not exists idx_chunks_document on public.document_chunks(document_id);
create index if not exists idx_chunks_chunk_index on public.document_chunks(document_id, chunk_index);

-- HNSW index for vector similarity search (cosine distance)
-- This is the most important index for RAG performance
create index if not exists idx_chunks_embedding_hnsw
    on public.document_chunks
    using hnsw (embedding vector_cosine_ops)
    with (m = 16, ef_construction = 64);

-- Alternative: IVFFlat index (faster build, slower query)
-- Uncomment if you prefer IVFFlat over HNSW
-- create index if not exists idx_chunks_embedding_ivfflat
--     on public.document_chunks
--     using ivfflat (embedding vector_cosine_ops)
--     with (lists = 100);

create index if not exists idx_processing_document on public.document_processing_status(document_id);
create index if not exists idx_processing_status on public.document_processing_status(status);

create index if not exists idx_query_logs_user on public.rag_query_logs(user_id);
create index if not exists idx_query_logs_created on public.rag_query_logs(created_at desc);

-- Full-text search indexes
create index if not exists idx_documents_content_search
    on public.documents
    using gin(to_tsvector('english', title || ' ' || content));

create index if not exists idx_chunks_content_search
    on public.document_chunks
    using gin(to_tsvector('english', content));

-- Functions for RAG operations

-- Semantic search function using cosine similarity
create or replace function public.search_documents(
    query_embedding vector(384),
    match_threshold float default 0.7,
    match_count int default 10,
    filter_collection_id uuid default null
)
returns table (
    chunk_id uuid,
    document_id uuid,
    document_title text,
    chunk_content text,
    chunk_index integer,
    similarity float
) as $$
begin
    return query
    select
        dc.id as chunk_id,
        d.id as document_id,
        d.title as document_title,
        dc.content as chunk_content,
        dc.chunk_index,
        1 - (dc.embedding <=> query_embedding) as similarity
    from public.document_chunks dc
    join public.documents d on d.id = dc.document_id
    where
        1 - (dc.embedding <=> query_embedding) > match_threshold
        and d.deleted_at is null
        and (filter_collection_id is null or d.collection_id = filter_collection_id)
    order by dc.embedding <=> query_embedding
    limit match_count;
end;
$$ language plpgsql stable;

-- Hybrid search (semantic + keyword)
create or replace function public.hybrid_search_documents(
    query_text text,
    query_embedding vector(384),
    semantic_weight float default 0.7,
    keyword_weight float default 0.3,
    match_count int default 10
)
returns table (
    chunk_id uuid,
    document_id uuid,
    document_title text,
    chunk_content text,
    combined_score float
) as $$
begin
    return query
    with semantic_search as (
        select
            dc.id,
            dc.document_id,
            d.title,
            dc.content,
            1 - (dc.embedding <=> query_embedding) as semantic_score
        from public.document_chunks dc
        join public.documents d on d.id = dc.document_id
        where d.deleted_at is null
    ),
    keyword_search as (
        select
            dc.id,
            ts_rank_cd(to_tsvector('english', dc.content), plainto_tsquery('english', query_text)) as keyword_score
        from public.document_chunks dc
        join public.documents d on d.id = dc.document_id
        where
            to_tsvector('english', dc.content) @@ plainto_tsquery('english', query_text)
            and d.deleted_at is null
    )
    select
        ss.id as chunk_id,
        ss.document_id,
        ss.title as document_title,
        ss.content as chunk_content,
        (coalesce(ss.semantic_score, 0) * semantic_weight +
         coalesce(ks.keyword_score, 0) * keyword_weight) as combined_score
    from semantic_search ss
    left join keyword_search ks on ks.id = ss.id
    where
        ss.semantic_score > 0.5 or ks.keyword_score > 0
    order by combined_score desc
    limit match_count;
end;
$$ language plpgsql stable;

-- Get document statistics
create or replace function public.get_document_stats(p_document_id uuid)
returns table (
    total_chunks bigint,
    total_tokens bigint,
    avg_chunk_size float,
    has_embeddings boolean
) as $$
begin
    return query
    select
        count(*)::bigint as total_chunks,
        sum(token_count)::bigint as total_tokens,
        avg(length(content))::float as avg_chunk_size,
        bool_and(embedding is not null) as has_embeddings
    from public.document_chunks
    where document_id = p_document_id;
end;
$$ language plpgsql stable;

-- Automatic timestamp update trigger
create or replace function public.handle_updated_at()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

create trigger set_collections_updated_at
    before update on public.document_collections
    for each row
    execute function public.handle_updated_at();

create trigger set_documents_updated_at
    before update on public.documents
    for each row
    execute function public.handle_updated_at();

create trigger set_processing_updated_at
    before update on public.document_processing_status
    for each row
    execute function public.handle_updated_at();

-- Row Level Security (RLS)
alter table public.document_collections enable row level security;
alter table public.documents enable row level security;
alter table public.document_chunks enable row level security;
alter table public.document_processing_status enable row level security;
alter table public.rag_query_logs enable row level security;

-- Collections policies
create policy "Users can view collections they created or public ones"
    on public.document_collections for select
    using (
        created_by = auth.uid() or
        (metadata->>'public')::boolean = true
    );

create policy "Users can create collections"
    on public.document_collections for insert
    with check (created_by = auth.uid());

create policy "Users can update their own collections"
    on public.document_collections for update
    using (created_by = auth.uid());

-- Documents policies
create policy "Users can view documents in accessible collections"
    on public.documents for select
    using (
        deleted_at is null and (
            created_by = auth.uid() or
            exists (
                select 1 from public.document_collections dc
                where dc.id = documents.collection_id
                  and (dc.created_by = auth.uid() or (dc.metadata->>'public')::boolean = true)
            )
        )
    );

create policy "Users can create documents"
    on public.documents for insert
    with check (created_by = auth.uid());

create policy "Users can update their own documents"
    on public.documents for update
    using (created_by = auth.uid());

create policy "Users can delete their own documents"
    on public.documents for delete
    using (created_by = auth.uid());

-- Document chunks inherit document permissions
create policy "Users can view chunks of accessible documents"
    on public.document_chunks for select
    using (
        exists (
            select 1 from public.documents d
            where d.id = document_chunks.document_id
              and d.deleted_at is null
              and (
                  d.created_by = auth.uid() or
                  exists (
                      select 1 from public.document_collections dc
                      where dc.id = d.collection_id
                        and (dc.created_by = auth.uid() or (dc.metadata->>'public')::boolean = true)
                  )
              )
        )
    );

-- Processing status policies
create policy "Users can view processing status of their documents"
    on public.document_processing_status for select
    using (
        exists (
            select 1 from public.documents d
            where d.id = document_processing_status.document_id
              and d.created_by = auth.uid()
        )
    );

-- Query logs policies
create policy "Users can view their own query logs"
    on public.rag_query_logs for select
    using (user_id = auth.uid());

create policy "Users can create query logs"
    on public.rag_query_logs for insert
    with check (user_id = auth.uid());
