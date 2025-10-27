-- AI Usage Tracking Schema
-- Track API calls, token usage, costs, and rate limiting
-- Optimized for analytics and billing

-- API usage records (detailed per-request tracking)
create table if not exists public.api_usage (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id) on delete set null,
    organization_id uuid, -- references public.organizations(id) if using multi-tenant schema
    endpoint text not null,
    method text check (method in ('GET', 'POST', 'PUT', 'PATCH', 'DELETE')),
    model_name text,
    provider text check (provider in ('openai', 'anthropic', 'google', 'cohere', 'custom')),

    -- Token metrics
    tokens_input integer default 0,
    tokens_output integer default 0,
    tokens_used integer generated always as (tokens_input + tokens_output) stored,

    -- Cost tracking
    cost_usd numeric(12, 6) default 0,
    cost_currency text default 'USD',

    -- Performance metrics
    response_time_ms integer,
    status_code integer,
    success boolean,

    -- Request metadata
    request_id text unique,
    session_id uuid,
    ip_address inet,
    user_agent text,
    metadata jsonb default '{}'::jsonb,

    created_at timestamp with time zone default now()
);

-- Token usage summary (aggregated by period)
create table if not exists public.token_usage_summary (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id) on delete cascade,
    organization_id uuid, -- references public.organizations(id) if using multi-tenant schema
    period_start timestamp with time zone not null,
    period_end timestamp with time zone not null,
    period_type text check (period_type in ('hour', 'day', 'week', 'month')),

    -- Aggregated metrics
    total_tokens bigint default 0,
    total_input_tokens bigint default 0,
    total_output_tokens bigint default 0,
    total_cost_usd numeric(12, 6) default 0,
    request_count integer default 0,
    success_count integer default 0,
    error_count integer default 0,

    -- Model breakdown
    model_usage jsonb default '{}'::jsonb,

    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now(),

    unique(user_id, period_start, period_type)
);

-- Usage quotas and limits
create table if not exists public.usage_quotas (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id) on delete cascade,
    organization_id uuid, -- references public.organizations(id) if using multi-tenant schema
    quota_type text not null check (quota_type in ('tokens_per_day', 'tokens_per_month', 'cost_per_month', 'requests_per_minute')),
    limit_value bigint not null,
    current_usage bigint default 0,
    reset_at timestamp with time zone,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now(),
    unique(user_id, quota_type)
);

-- Rate limiting records
create table if not exists public.rate_limits (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id) on delete cascade,
    organization_id uuid, -- references public.organizations(id) if using multi-tenant schema
    endpoint text not null,
    window_start timestamp with time zone not null,
    window_duration_seconds integer not null,
    request_count integer default 0,
    max_requests integer not null,
    blocked boolean default false,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now(),
    unique(user_id, endpoint, window_start)
);

-- Model pricing table (for cost calculation)
create table if not exists public.model_pricing (
    id uuid primary key default uuid_generate_v4(),
    provider text not null,
    model_name text not null,
    input_price_per_1k_tokens numeric(12, 6) not null,
    output_price_per_1k_tokens numeric(12, 6) not null,
    currency text default 'USD',
    effective_from timestamp with time zone default now(),
    effective_until timestamp with time zone,
    metadata jsonb default '{}'::jsonb,
    created_at timestamp with time zone default now(),
    unique(provider, model_name, effective_from)
);

-- Usage alerts (notify when approaching limits)
create table if not exists public.usage_alerts (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id) on delete cascade,
    organization_id uuid, -- references public.organizations(id) if using multi-tenant schema
    alert_type text check (alert_type in ('quota_warning', 'quota_exceeded', 'cost_threshold', 'rate_limit')),
    threshold_percent integer check (threshold_percent between 0 and 100),
    triggered_at timestamp with time zone default now(),
    resolved_at timestamp with time zone,
    notification_sent boolean default false,
    metadata jsonb default '{}'::jsonb
);

-- Cost breakdown by model/endpoint
create table if not exists public.cost_breakdown (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id) on delete set null,
    organization_id uuid,
    period_start timestamp with time zone not null,
    period_end timestamp with time zone not null,
    model_name text not null,
    endpoint text,
    total_requests integer default 0,
    total_tokens bigint default 0,
    total_cost_usd numeric(12, 6) default 0,
    created_at timestamp with time zone default now(),
    unique(user_id, period_start, model_name, endpoint)
);

-- Indexes for performance
create index if not exists idx_api_usage_user on public.api_usage(user_id, created_at desc);
create index if not exists idx_api_usage_org on public.api_usage(organization_id, created_at desc) where organization_id is not null;
create index if not exists idx_api_usage_endpoint on public.api_usage(endpoint);
create index if not exists idx_api_usage_model on public.api_usage(model_name);
create index if not exists idx_api_usage_request_id on public.api_usage(request_id);
create index if not exists idx_api_usage_created on public.api_usage(created_at desc);
create index if not exists idx_api_usage_success on public.api_usage(success);

create index if not exists idx_summary_user_period on public.token_usage_summary(user_id, period_start desc);
create index if not exists idx_summary_org_period on public.token_usage_summary(organization_id, period_start desc) where organization_id is not null;

create index if not exists idx_quotas_user on public.usage_quotas(user_id);
create index if not exists idx_quotas_reset on public.usage_quotas(reset_at) where reset_at is not null;

create index if not exists idx_rate_limits_user on public.rate_limits(user_id, window_start desc);
create index if not exists idx_rate_limits_window on public.rate_limits(window_start);

create index if not exists idx_pricing_provider_model on public.model_pricing(provider, model_name, effective_from desc);
create index if not exists idx_pricing_effective on public.model_pricing(effective_until) where effective_until is not null;

create index if not exists idx_alerts_user on public.usage_alerts(user_id, triggered_at desc);
create index if not exists idx_alerts_unresolved on public.usage_alerts(user_id) where resolved_at is null;

create index if not exists idx_cost_breakdown_user on public.cost_breakdown(user_id, period_start desc);

-- Helper functions

-- Calculate cost for API usage
create or replace function public.calculate_api_cost(
    p_provider text,
    p_model_name text,
    p_input_tokens integer,
    p_output_tokens integer,
    p_timestamp timestamp with time zone default now()
)
returns numeric(12, 6) as $$
declare
    pricing record;
    cost numeric(12, 6);
begin
    -- Get pricing for the model
    select * into pricing
    from public.model_pricing
    where provider = p_provider
      and model_name = p_model_name
      and effective_from <= p_timestamp
      and (effective_until is null or effective_until > p_timestamp)
    order by effective_from desc
    limit 1;

    if pricing is null then
        -- Return 0 if pricing not found
        return 0;
    end if;

    -- Calculate cost
    cost := (p_input_tokens::numeric / 1000 * pricing.input_price_per_1k_tokens) +
            (p_output_tokens::numeric / 1000 * pricing.output_price_per_1k_tokens);

    return round(cost, 6);
end;
$$ language plpgsql stable;

-- Check if user has exceeded quota
create or replace function public.check_usage_quota(
    p_user_id uuid,
    p_quota_type text
)
returns boolean as $$
declare
    quota record;
begin
    select * into quota
    from public.usage_quotas
    where user_id = p_user_id
      and quota_type = p_quota_type;

    if quota is null then
        return true; -- No quota defined, allow
    end if;

    -- Reset quota if needed
    if quota.reset_at is not null and quota.reset_at < now() then
        update public.usage_quotas
        set current_usage = 0,
            reset_at = case p_quota_type
                when 'tokens_per_day' then now() + interval '1 day'
                when 'tokens_per_month' then now() + interval '1 month'
                when 'cost_per_month' then now() + interval '1 month'
                when 'requests_per_minute' then now() + interval '1 minute'
            end
        where id = quota.id;
        return true;
    end if;

    return quota.current_usage < quota.limit_value;
end;
$$ language plpgsql;

-- Get usage statistics for user
create or replace function public.get_usage_stats(
    p_user_id uuid,
    p_period_days integer default 30
)
returns jsonb as $$
declare
    result jsonb;
begin
    select jsonb_build_object(
        'total_requests', count(*),
        'total_tokens', sum(tokens_used),
        'total_cost_usd', sum(cost_usd),
        'success_rate', avg(case when success then 1 else 0 end),
        'avg_response_time_ms', avg(response_time_ms),
        'by_model', (
            select jsonb_object_agg(model_name, model_stats)
            from (
                select
                    model_name,
                    jsonb_build_object(
                        'requests', count(*),
                        'tokens', sum(tokens_used),
                        'cost', sum(cost_usd)
                    ) as model_stats
                from public.api_usage
                where user_id = p_user_id
                  and created_at > now() - (p_period_days || ' days')::interval
                group by model_name
            ) model_data
        ),
        'by_endpoint', (
            select jsonb_object_agg(endpoint, endpoint_stats)
            from (
                select
                    endpoint,
                    jsonb_build_object(
                        'requests', count(*),
                        'avg_response_time', avg(response_time_ms)
                    ) as endpoint_stats
                from public.api_usage
                where user_id = p_user_id
                  and created_at > now() - (p_period_days || ' days')::interval
                group by endpoint
            ) endpoint_data
        )
    ) into result
    from public.api_usage
    where user_id = p_user_id
      and created_at > now() - (p_period_days || ' days')::interval;

    return coalesce(result, '{}'::jsonb);
end;
$$ language plpgsql stable;

-- Aggregate usage into summaries (run periodically)
create or replace function public.aggregate_usage_summary(
    p_period_type text default 'day'
)
returns void as $$
begin
    insert into public.token_usage_summary (
        user_id,
        organization_id,
        period_start,
        period_end,
        period_type,
        total_tokens,
        total_input_tokens,
        total_output_tokens,
        total_cost_usd,
        request_count,
        success_count,
        error_count,
        model_usage
    )
    select
        user_id,
        organization_id,
        date_trunc(p_period_type, created_at) as period_start,
        date_trunc(p_period_type, created_at) + ('1 ' || p_period_type)::interval as period_end,
        p_period_type,
        sum(tokens_used),
        sum(tokens_input),
        sum(tokens_output),
        sum(cost_usd),
        count(*),
        count(*) filter (where success),
        count(*) filter (where not success),
        jsonb_object_agg(model_name, count(*))
    from public.api_usage
    where created_at >= date_trunc(p_period_type, now() - ('1 ' || p_period_type)::interval)
      and created_at < date_trunc(p_period_type, now())
    group by user_id, organization_id, date_trunc(p_period_type, created_at)
    on conflict (user_id, period_start, period_type)
    do update set
        total_tokens = excluded.total_tokens,
        total_input_tokens = excluded.total_input_tokens,
        total_output_tokens = excluded.total_output_tokens,
        total_cost_usd = excluded.total_cost_usd,
        request_count = excluded.request_count,
        success_count = excluded.success_count,
        error_count = excluded.error_count,
        model_usage = excluded.model_usage,
        updated_at = now();
end;
$$ language plpgsql;

-- Automatic timestamp updates
create or replace function public.handle_updated_at()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

create trigger set_summary_updated_at
    before update on public.token_usage_summary
    for each row
    execute function public.handle_updated_at();

create trigger set_quotas_updated_at
    before update on public.usage_quotas
    for each row
    execute function public.handle_updated_at();

create trigger set_rate_limits_updated_at
    before update on public.rate_limits
    for each row
    execute function public.handle_updated_at();

-- Row Level Security (RLS)
alter table public.api_usage enable row level security;
alter table public.token_usage_summary enable row level security;
alter table public.usage_quotas enable row level security;
alter table public.rate_limits enable row level security;
alter table public.model_pricing enable row level security;
alter table public.usage_alerts enable row level security;
alter table public.cost_breakdown enable row level security;

-- API usage policies
create policy "Users can view own usage"
    on public.api_usage for select
    using (user_id = auth.uid());

create policy "Service can insert usage records"
    on public.api_usage for insert
    with check (true); -- Allow service account to insert

-- Token summary policies
create policy "Users can view own summaries"
    on public.token_usage_summary for select
    using (user_id = auth.uid());

-- Quota policies
create policy "Users can view own quotas"
    on public.usage_quotas for select
    using (user_id = auth.uid());

-- Rate limit policies
create policy "Users can view own rate limits"
    on public.rate_limits for select
    using (user_id = auth.uid());

-- Model pricing is public
create policy "Model pricing is public"
    on public.model_pricing for select
    using (true);

-- Alert policies
create policy "Users can view own alerts"
    on public.usage_alerts for select
    using (user_id = auth.uid());

-- Cost breakdown policies
create policy "Users can view own cost breakdown"
    on public.cost_breakdown for select
    using (user_id = auth.uid());
