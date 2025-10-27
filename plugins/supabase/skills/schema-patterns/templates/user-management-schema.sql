-- User Management Schema
-- Extended user profiles, preferences, and metadata
-- Complements auth.users table

-- User profiles (extends auth.users)
create table if not exists public.user_profiles (
    user_id uuid primary key references auth.users(id) on delete cascade,
    bio text,
    avatar_url text,
    banner_url text,
    location text,
    website text,
    timezone text default 'UTC',
    language text default 'en',
    theme text default 'system' check (theme in ('light', 'dark', 'system')),
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

-- User preferences (settings, notifications, privacy)
create table if not exists public.user_preferences (
    user_id uuid primary key references auth.users(id) on delete cascade,
    preferences jsonb default '{}'::jsonb,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

-- User metadata (extensible key-value store)
create table if not exists public.user_metadata (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid not null references auth.users(id) on delete cascade,
    key text not null,
    value jsonb not null,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now(),
    unique(user_id, key)
);

-- User sessions (track login history and active sessions)
create table if not exists public.user_sessions (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid not null references auth.users(id) on delete cascade,
    session_token text unique not null,
    ip_address inet,
    user_agent text,
    device_type text check (device_type in ('desktop', 'mobile', 'tablet', 'other')),
    location_country text,
    location_city text,
    last_activity_at timestamp with time zone default now(),
    expires_at timestamp with time zone,
    created_at timestamp with time zone default now()
);

-- User connections (social links, integrations)
create table if not exists public.user_connections (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid not null references auth.users(id) on delete cascade,
    provider text not null check (provider in ('github', 'google', 'twitter', 'linkedin', 'discord', 'slack')),
    provider_user_id text not null,
    provider_username text,
    provider_email text,
    access_token_encrypted text, -- Store encrypted
    refresh_token_encrypted text, -- Store encrypted
    expires_at timestamp with time zone,
    scopes text[],
    metadata jsonb default '{}'::jsonb,
    connected_at timestamp with time zone default now(),
    last_synced_at timestamp with time zone,
    unique(user_id, provider)
);

-- User achievements/badges
create table if not exists public.user_achievements (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid not null references auth.users(id) on delete cascade,
    achievement_type text not null,
    achievement_name text not null,
    description text,
    icon_url text,
    metadata jsonb default '{}'::jsonb,
    earned_at timestamp with time zone default now(),
    unique(user_id, achievement_type, achievement_name)
);

-- User activity log
create table if not exists public.user_activity_log (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid not null references auth.users(id) on delete cascade,
    activity_type text not null,
    activity_data jsonb default '{}'::jsonb,
    ip_address inet,
    user_agent text,
    created_at timestamp with time zone default now()
);

-- User notifications
create table if not exists public.user_notifications (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid not null references auth.users(id) on delete cascade,
    type text not null check (type in ('info', 'success', 'warning', 'error')),
    title text not null,
    message text not null,
    action_url text,
    metadata jsonb default '{}'::jsonb,
    read_at timestamp with time zone,
    created_at timestamp with time zone default now()
);

-- User follows (for social features)
create table if not exists public.user_follows (
    id uuid primary key default uuid_generate_v4(),
    follower_id uuid not null references auth.users(id) on delete cascade,
    following_id uuid not null references auth.users(id) on delete cascade,
    created_at timestamp with time zone default now(),
    unique(follower_id, following_id),
    check (follower_id != following_id)
);

-- Indexes for performance
create index if not exists idx_profiles_user on public.user_profiles(user_id);

create index if not exists idx_preferences_user on public.user_preferences(user_id);

create index if not exists idx_metadata_user on public.user_metadata(user_id);
create index if not exists idx_metadata_key on public.user_metadata(key);
create index if not exists idx_metadata_user_key on public.user_metadata(user_id, key);

create index if not exists idx_sessions_user on public.user_sessions(user_id);
create index if not exists idx_sessions_token on public.user_sessions(session_token);
create index if not exists idx_sessions_expires on public.user_sessions(expires_at) where expires_at > now();
create index if not exists idx_sessions_activity on public.user_sessions(last_activity_at desc);

create index if not exists idx_connections_user on public.user_connections(user_id);
create index if not exists idx_connections_provider on public.user_connections(provider);

create index if not exists idx_achievements_user on public.user_achievements(user_id);
create index if not exists idx_achievements_earned on public.user_achievements(earned_at desc);

create index if not exists idx_activity_user on public.user_activity_log(user_id, created_at desc);
create index if not exists idx_activity_type on public.user_activity_log(activity_type);

create index if not exists idx_notifications_user on public.user_notifications(user_id, created_at desc);
create index if not exists idx_notifications_unread on public.user_notifications(user_id) where read_at is null;

create index if not exists idx_follows_follower on public.user_follows(follower_id);
create index if not exists idx_follows_following on public.user_follows(following_id);

-- Helper functions

-- Get user's full profile
create or replace function public.get_user_profile(p_user_id uuid)
returns jsonb as $$
declare
    result jsonb;
begin
    select jsonb_build_object(
        'id', u.id,
        'email', u.email,
        'profile', row_to_json(p.*),
        'preferences', pr.preferences,
        'follower_count', (select count(*) from public.user_follows where following_id = p_user_id),
        'following_count', (select count(*) from public.user_follows where follower_id = p_user_id),
        'achievement_count', (select count(*) from public.user_achievements where user_id = p_user_id)
    ) into result
    from auth.users u
    left join public.user_profiles p on p.user_id = u.id
    left join public.user_preferences pr on pr.user_id = u.id
    where u.id = p_user_id;

    return result;
end;
$$ language plpgsql stable security definer;

-- Mark notifications as read
create or replace function public.mark_notifications_read(p_user_id uuid, p_notification_ids uuid[])
returns void as $$
begin
    update public.user_notifications
    set read_at = now()
    where user_id = p_user_id
      and id = any(p_notification_ids)
      and read_at is null;
end;
$$ language plpgsql security definer;

-- Get unread notification count
create or replace function public.get_unread_notification_count(p_user_id uuid)
returns bigint as $$
    select count(*)
    from public.user_notifications
    where user_id = p_user_id
      and read_at is null;
$$ language sql stable;

-- Cleanup expired sessions
create or replace function public.cleanup_expired_sessions()
returns void as $$
begin
    delete from public.user_sessions
    where expires_at < now();
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

create trigger set_profiles_updated_at
    before update on public.user_profiles
    for each row
    execute function public.handle_updated_at();

create trigger set_preferences_updated_at
    before update on public.user_preferences
    for each row
    execute function public.handle_updated_at();

create trigger set_metadata_updated_at
    before update on public.user_metadata
    for each row
    execute function public.handle_updated_at();

-- Auto-create profile on user signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
    insert into public.user_profiles (user_id)
    values (new.id);

    insert into public.user_preferences (user_id, preferences)
    values (new.id, '{
        "notifications": {
            "email": true,
            "push": true,
            "in_app": true
        },
        "privacy": {
            "profile_visible": true,
            "show_activity": true
        }
    }'::jsonb);

    return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
    after insert on auth.users
    for each row
    execute function public.handle_new_user();

-- Row Level Security (RLS)
alter table public.user_profiles enable row level security;
alter table public.user_preferences enable row level security;
alter table public.user_metadata enable row level security;
alter table public.user_sessions enable row level security;
alter table public.user_connections enable row level security;
alter table public.user_achievements enable row level security;
alter table public.user_activity_log enable row level security;
alter table public.user_notifications enable row level security;
alter table public.user_follows enable row level security;

-- User profiles policies
create policy "Profiles are viewable by everyone"
    on public.user_profiles for select
    using (true);

create policy "Users can update own profile"
    on public.user_profiles for update
    using (user_id = auth.uid());

-- User preferences policies (private)
create policy "Users can view own preferences"
    on public.user_preferences for select
    using (user_id = auth.uid());

create policy "Users can update own preferences"
    on public.user_preferences for update
    using (user_id = auth.uid());

-- User metadata policies
create policy "Users can view own metadata"
    on public.user_metadata for select
    using (user_id = auth.uid());

create policy "Users can insert own metadata"
    on public.user_metadata for insert
    with check (user_id = auth.uid());

create policy "Users can update own metadata"
    on public.user_metadata for update
    using (user_id = auth.uid());

create policy "Users can delete own metadata"
    on public.user_metadata for delete
    using (user_id = auth.uid());

-- Sessions policies
create policy "Users can view own sessions"
    on public.user_sessions for select
    using (user_id = auth.uid());

create policy "Users can delete own sessions"
    on public.user_sessions for delete
    using (user_id = auth.uid());

-- Connections policies
create policy "Users can view own connections"
    on public.user_connections for select
    using (user_id = auth.uid());

create policy "Users can manage own connections"
    on public.user_connections for all
    using (user_id = auth.uid());

-- Achievements policies
create policy "Achievements are viewable by everyone"
    on public.user_achievements for select
    using (true);

-- Activity log policies
create policy "Users can view own activity"
    on public.user_activity_log for select
    using (user_id = auth.uid());

-- Notifications policies
create policy "Users can view own notifications"
    on public.user_notifications for select
    using (user_id = auth.uid());

create policy "Users can update own notifications"
    on public.user_notifications for update
    using (user_id = auth.uid());

-- Follows policies
create policy "Follows are viewable by everyone"
    on public.user_follows for select
    using (true);

create policy "Users can follow others"
    on public.user_follows for insert
    with check (follower_id = auth.uid());

create policy "Users can unfollow"
    on public.user_follows for delete
    using (follower_id = auth.uid());
