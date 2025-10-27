-- Multi-Tenant Schema
-- Organization-based multi-tenancy with teams and role-based access
-- Includes: organizations, teams, members, roles, invitations

-- Organizations table
create table if not exists public.organizations (
    id uuid primary key default uuid_generate_v4(),
    name text not null,
    slug text unique not null,
    description text,
    avatar_url text,
    website text,
    plan_type text default 'free' check (plan_type in ('free', 'pro', 'enterprise')),
    settings jsonb default '{}'::jsonb,
    metadata jsonb default '{}'::jsonb,
    created_by uuid references auth.users(id) on delete set null,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now(),
    deleted_at timestamp with time zone
);

-- Teams within organizations
create table if not exists public.teams (
    id uuid primary key default uuid_generate_v4(),
    organization_id uuid not null references public.organizations(id) on delete cascade,
    name text not null,
    description text,
    settings jsonb default '{}'::jsonb,
    created_by uuid references auth.users(id) on delete set null,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now(),
    deleted_at timestamp with time zone,
    unique(organization_id, name)
);

-- Organization members
create table if not exists public.organization_members (
    id uuid primary key default uuid_generate_v4(),
    organization_id uuid not null references public.organizations(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    role text not null check (role in ('owner', 'admin', 'member', 'viewer')),
    permissions jsonb default '[]'::jsonb,
    joined_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now(),
    unique(organization_id, user_id)
);

-- Team members
create table if not exists public.team_members (
    id uuid primary key default uuid_generate_v4(),
    team_id uuid not null references public.teams(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    role text not null check (role in ('lead', 'member')),
    joined_at timestamp with time zone default now(),
    unique(team_id, user_id)
);

-- Invitations
create table if not exists public.organization_invitations (
    id uuid primary key default uuid_generate_v4(),
    organization_id uuid not null references public.organizations(id) on delete cascade,
    email text not null,
    role text not null check (role in ('admin', 'member', 'viewer')),
    invited_by uuid not null references auth.users(id) on delete cascade,
    accepted_at timestamp with time zone,
    expires_at timestamp with time zone default (now() + interval '7 days'),
    created_at timestamp with time zone default now(),
    unique(organization_id, email)
);

-- Organization API keys (for programmatic access)
create table if not exists public.organization_api_keys (
    id uuid primary key default uuid_generate_v4(),
    organization_id uuid not null references public.organizations(id) on delete cascade,
    name text not null,
    key_hash text not null unique,
    key_prefix text not null, -- First 8 chars for display (e.g., "sk_live_")
    scopes text[] default array[]::text[],
    last_used_at timestamp with time zone,
    expires_at timestamp with time zone,
    created_by uuid not null references auth.users(id) on delete cascade,
    created_at timestamp with time zone default now(),
    revoked_at timestamp with time zone
);

-- Audit log for organization actions
create table if not exists public.organization_audit_log (
    id uuid primary key default uuid_generate_v4(),
    organization_id uuid not null references public.organizations(id) on delete cascade,
    user_id uuid references auth.users(id) on delete set null,
    action text not null,
    resource_type text,
    resource_id uuid,
    metadata jsonb default '{}'::jsonb,
    ip_address inet,
    user_agent text,
    created_at timestamp with time zone default now()
);

-- Indexes for performance
create index if not exists idx_orgs_slug on public.organizations(slug);
create index if not exists idx_orgs_created_by on public.organizations(created_by);
create index if not exists idx_orgs_deleted on public.organizations(deleted_at) where deleted_at is null;
create index if not exists idx_orgs_plan_type on public.organizations(plan_type);

create index if not exists idx_teams_org on public.teams(organization_id);
create index if not exists idx_teams_deleted on public.teams(deleted_at) where deleted_at is null;

create index if not exists idx_org_members_org on public.organization_members(organization_id);
create index if not exists idx_org_members_user on public.organization_members(user_id);
create index if not exists idx_org_members_role on public.organization_members(role);

create index if not exists idx_team_members_team on public.team_members(team_id);
create index if not exists idx_team_members_user on public.team_members(user_id);

create index if not exists idx_invitations_org on public.organization_invitations(organization_id);
create index if not exists idx_invitations_email on public.organization_invitations(email);
create index if not exists idx_invitations_expires on public.organization_invitations(expires_at) where accepted_at is null;

create index if not exists idx_api_keys_org on public.organization_api_keys(organization_id);
create index if not exists idx_api_keys_hash on public.organization_api_keys(key_hash);
create index if not exists idx_api_keys_revoked on public.organization_api_keys(revoked_at) where revoked_at is null;

create index if not exists idx_audit_log_org on public.organization_audit_log(organization_id, created_at desc);
create index if not exists idx_audit_log_user on public.organization_audit_log(user_id);
create index if not exists idx_audit_log_resource on public.organization_audit_log(resource_type, resource_id);

-- Helper functions

-- Check if user has specific role in organization
create or replace function public.user_has_org_role(
    p_user_id uuid,
    p_organization_id uuid,
    p_required_role text
)
returns boolean as $$
declare
    user_role text;
    role_hierarchy int;
    required_hierarchy int;
begin
    -- Get user's role
    select role into user_role
    from public.organization_members
    where organization_id = p_organization_id
      and user_id = p_user_id;

    if user_role is null then
        return false;
    end if;

    -- Role hierarchy: owner > admin > member > viewer
    role_hierarchy := case user_role
        when 'owner' then 4
        when 'admin' then 3
        when 'member' then 2
        when 'viewer' then 1
        else 0
    end;

    required_hierarchy := case p_required_role
        when 'owner' then 4
        when 'admin' then 3
        when 'member' then 2
        when 'viewer' then 1
        else 0
    end;

    return role_hierarchy >= required_hierarchy;
end;
$$ language plpgsql stable security definer;

-- Get user's organizations
create or replace function public.get_user_organizations(p_user_id uuid)
returns table (
    organization_id uuid,
    organization_name text,
    organization_slug text,
    user_role text,
    joined_at timestamp with time zone
) as $$
begin
    return query
    select
        o.id,
        o.name,
        o.slug,
        om.role,
        om.joined_at
    from public.organizations o
    join public.organization_members om on om.organization_id = o.id
    where om.user_id = p_user_id
      and o.deleted_at is null
    order by om.joined_at desc;
end;
$$ language plpgsql stable security definer;

-- Get user's teams within an organization
create or replace function public.get_user_teams(
    p_user_id uuid,
    p_organization_id uuid
)
returns table (
    team_id uuid,
    team_name text,
    team_role text
) as $$
begin
    return query
    select
        t.id,
        t.name,
        tm.role
    from public.teams t
    join public.team_members tm on tm.team_id = t.id
    where tm.user_id = p_user_id
      and t.organization_id = p_organization_id
      and t.deleted_at is null
    order by t.name;
end;
$$ language plpgsql stable security definer;

-- Automatic timestamp updates
create or replace function public.handle_updated_at()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

create trigger set_orgs_updated_at
    before update on public.organizations
    for each row
    execute function public.handle_updated_at();

create trigger set_teams_updated_at
    before update on public.teams
    for each row
    execute function public.handle_updated_at();

create trigger set_org_members_updated_at
    before update on public.organization_members
    for each row
    execute function public.handle_updated_at();

-- Audit logging trigger
create or replace function public.log_organization_action()
returns trigger as $$
begin
    insert into public.organization_audit_log (
        organization_id,
        user_id,
        action,
        resource_type,
        resource_id,
        metadata
    ) values (
        coalesce(new.organization_id, old.organization_id),
        auth.uid(),
        case
            when TG_OP = 'INSERT' then 'create'
            when TG_OP = 'UPDATE' then 'update'
            when TG_OP = 'DELETE' then 'delete'
        end,
        TG_TABLE_NAME,
        coalesce(new.id, old.id),
        jsonb_build_object(
            'operation', TG_OP,
            'table', TG_TABLE_NAME
        )
    );
    return coalesce(new, old);
end;
$$ language plpgsql security definer;

-- Apply audit logging to key tables
create trigger audit_organizations
    after insert or update or delete on public.organizations
    for each row
    execute function public.log_organization_action();

create trigger audit_teams
    after insert or update or delete on public.teams
    for each row
    execute function public.log_organization_action();

create trigger audit_org_members
    after insert or update or delete on public.organization_members
    for each row
    execute function public.log_organization_action();

-- Row Level Security (RLS)
alter table public.organizations enable row level security;
alter table public.teams enable row level security;
alter table public.organization_members enable row level security;
alter table public.team_members enable row level security;
alter table public.organization_invitations enable row level security;
alter table public.organization_api_keys enable row level security;
alter table public.organization_audit_log enable row level security;

-- Organizations policies
create policy "Users can view organizations they belong to"
    on public.organizations for select
    using (
        deleted_at is null and
        exists (
            select 1 from public.organization_members
            where organization_id = organizations.id
              and user_id = auth.uid()
        )
    );

create policy "Users can create organizations"
    on public.organizations for insert
    with check (created_by = auth.uid());

create policy "Owners and admins can update organizations"
    on public.organizations for update
    using (
        public.user_has_org_role(auth.uid(), id, 'admin')
    );

create policy "Only owners can delete organizations"
    on public.organizations for delete
    using (
        public.user_has_org_role(auth.uid(), id, 'owner')
    );

-- Teams policies
create policy "Users can view teams in their organizations"
    on public.teams for select
    using (
        deleted_at is null and
        exists (
            select 1 from public.organization_members
            where organization_id = teams.organization_id
              and user_id = auth.uid()
        )
    );

create policy "Admins can create teams"
    on public.teams for insert
    with check (
        public.user_has_org_role(auth.uid(), organization_id, 'admin')
    );

create policy "Admins can update teams"
    on public.teams for update
    using (
        public.user_has_org_role(auth.uid(), organization_id, 'admin')
    );

-- Organization members policies
create policy "Users can view members in their organizations"
    on public.organization_members for select
    using (
        exists (
            select 1 from public.organization_members om
            where om.organization_id = organization_members.organization_id
              and om.user_id = auth.uid()
        )
    );

create policy "Admins can add members"
    on public.organization_members for insert
    with check (
        public.user_has_org_role(auth.uid(), organization_id, 'admin')
    );

create policy "Admins can update members"
    on public.organization_members for update
    using (
        public.user_has_org_role(auth.uid(), organization_id, 'admin')
    );

create policy "Admins can remove members"
    on public.organization_members for delete
    using (
        public.user_has_org_role(auth.uid(), organization_id, 'admin')
    );

-- Team members policies
create policy "Users can view team members in their teams"
    on public.team_members for select
    using (
        exists (
            select 1 from public.teams t
            join public.organization_members om on om.organization_id = t.organization_id
            where t.id = team_members.team_id
              and om.user_id = auth.uid()
        )
    );

create policy "Team leads and org admins can manage team members"
    on public.team_members for all
    using (
        exists (
            select 1 from public.teams t
            where t.id = team_members.team_id
              and (
                  public.user_has_org_role(auth.uid(), t.organization_id, 'admin')
                  or exists (
                      select 1 from public.team_members tm
                      where tm.team_id = t.id
                        and tm.user_id = auth.uid()
                        and tm.role = 'lead'
                  )
              )
        )
    );

-- Invitations policies
create policy "Members can view invitations in their organizations"
    on public.organization_invitations for select
    using (
        exists (
            select 1 from public.organization_members
            where organization_id = organization_invitations.organization_id
              and user_id = auth.uid()
        )
    );

create policy "Admins can send invitations"
    on public.organization_invitations for insert
    with check (
        public.user_has_org_role(auth.uid(), organization_id, 'admin')
    );

-- API keys policies
create policy "Members can view API keys in their organizations"
    on public.organization_api_keys for select
    using (
        revoked_at is null and
        exists (
            select 1 from public.organization_members
            where organization_id = organization_api_keys.organization_id
              and user_id = auth.uid()
        )
    );

create policy "Admins can manage API keys"
    on public.organization_api_keys for all
    using (
        public.user_has_org_role(auth.uid(), organization_id, 'admin')
    );

-- Audit log policies
create policy "Members can view audit logs in their organizations"
    on public.organization_audit_log for select
    using (
        exists (
            select 1 from public.organization_members
            where organization_id = organization_audit_log.organization_id
              and user_id = auth.uid()
              and role in ('owner', 'admin')
        )
    );
