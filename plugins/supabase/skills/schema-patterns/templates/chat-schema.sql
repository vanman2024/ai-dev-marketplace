-- Chat/Conversation Schema
-- Optimized for real-time messaging applications
-- Includes: users, conversations, messages, participants, typing indicators

-- Users table (extends auth.users)
create table if not exists public.users (
    id uuid primary key references auth.users(id) on delete cascade,
    email text unique not null,
    username text unique not null,
    full_name text,
    avatar_url text,
    status text default 'offline' check (status in ('online', 'offline', 'away', 'busy')),
    last_seen_at timestamp with time zone default now(),
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

-- Conversations table
create table if not exists public.conversations (
    id uuid primary key default uuid_generate_v4(),
    title text,
    type text default 'direct' check (type in ('direct', 'group', 'channel')),
    metadata jsonb default '{}'::jsonb,
    created_by uuid references public.users(id) on delete set null,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

-- Conversation participants
create table if not exists public.conversation_participants (
    id uuid primary key default uuid_generate_v4(),
    conversation_id uuid not null references public.conversations(id) on delete cascade,
    user_id uuid not null references public.users(id) on delete cascade,
    role text default 'member' check (role in ('owner', 'admin', 'member')),
    last_read_at timestamp with time zone,
    joined_at timestamp with time zone default now(),
    muted boolean default false,
    unique(conversation_id, user_id)
);

-- Messages table
create table if not exists public.messages (
    id uuid primary key default uuid_generate_v4(),
    conversation_id uuid not null references public.conversations(id) on delete cascade,
    user_id uuid not null references public.users(id) on delete cascade,
    content text not null,
    message_type text default 'text' check (message_type in ('text', 'image', 'file', 'system')),
    metadata jsonb default '{}'::jsonb,
    parent_message_id uuid references public.messages(id) on delete set null,
    edited_at timestamp with time zone,
    deleted_at timestamp with time zone,
    created_at timestamp with time zone default now()
);

-- Message reactions
create table if not exists public.message_reactions (
    id uuid primary key default uuid_generate_v4(),
    message_id uuid not null references public.messages(id) on delete cascade,
    user_id uuid not null references public.users(id) on delete cascade,
    emoji text not null,
    created_at timestamp with time zone default now(),
    unique(message_id, user_id, emoji)
);

-- Typing indicators (ephemeral data, cleared periodically)
create table if not exists public.typing_indicators (
    conversation_id uuid not null references public.conversations(id) on delete cascade,
    user_id uuid not null references public.users(id) on delete cascade,
    expires_at timestamp with time zone default (now() + interval '5 seconds'),
    primary key (conversation_id, user_id)
);

-- Indexes for performance
create index if not exists idx_users_username on public.users(username);
create index if not exists idx_users_status on public.users(status) where status = 'online';

create index if not exists idx_conversations_created_by on public.conversations(created_by);
create index if not exists idx_conversations_updated_at on public.conversations(updated_at desc);

create index if not exists idx_participants_conversation on public.conversation_participants(conversation_id);
create index if not exists idx_participants_user on public.conversation_participants(user_id);
create index if not exists idx_participants_last_read on public.conversation_participants(last_read_at);

create index if not exists idx_messages_conversation on public.messages(conversation_id, created_at desc);
create index if not exists idx_messages_user on public.messages(user_id);
create index if not exists idx_messages_parent on public.messages(parent_message_id) where parent_message_id is not null;
create index if not exists idx_messages_deleted on public.messages(deleted_at) where deleted_at is null;

create index if not exists idx_reactions_message on public.message_reactions(message_id);

create index if not exists idx_typing_expires on public.typing_indicators(expires_at);

-- Full-text search on messages
create index if not exists idx_messages_content_search on public.messages using gin(to_tsvector('english', content));

-- Functions for automatic timestamp updates
create or replace function public.handle_updated_at()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

-- Triggers for updated_at
create trigger set_users_updated_at
    before update on public.users
    for each row
    execute function public.handle_updated_at();

create trigger set_conversations_updated_at
    before update on public.conversations
    for each row
    execute function public.handle_updated_at();

-- Function to cleanup old typing indicators
create or replace function public.cleanup_typing_indicators()
returns void as $$
begin
    delete from public.typing_indicators
    where expires_at < now();
end;
$$ language plpgsql;

-- Function to get unread message count
create or replace function public.get_unread_count(p_conversation_id uuid, p_user_id uuid)
returns bigint as $$
    select count(*)
    from public.messages m
    where m.conversation_id = p_conversation_id
      and m.created_at > coalesce(
          (select last_read_at
           from public.conversation_participants
           where conversation_id = p_conversation_id
             and user_id = p_user_id),
          '1970-01-01'::timestamp
      )
      and m.user_id != p_user_id
      and m.deleted_at is null;
$$ language sql stable;

-- Row Level Security (RLS) policies
alter table public.users enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_participants enable row level security;
alter table public.messages enable row level security;
alter table public.message_reactions enable row level security;
alter table public.typing_indicators enable row level security;

-- Users can read their own profile and other users' public data
create policy "Users can view all profiles"
    on public.users for select
    using (true);

create policy "Users can update own profile"
    on public.users for update
    using (auth.uid() = id);

-- Conversations: users can only see conversations they're part of
create policy "Users can view their conversations"
    on public.conversations for select
    using (
        exists (
            select 1 from public.conversation_participants
            where conversation_id = conversations.id
              and user_id = auth.uid()
        )
    );

create policy "Users can create conversations"
    on public.conversations for insert
    with check (auth.uid() = created_by);

create policy "Conversation owners/admins can update"
    on public.conversations for update
    using (
        exists (
            select 1 from public.conversation_participants
            where conversation_id = conversations.id
              and user_id = auth.uid()
              and role in ('owner', 'admin')
        )
    );

-- Participants: users can view participants in their conversations
create policy "Users can view conversation participants"
    on public.conversation_participants for select
    using (
        exists (
            select 1 from public.conversation_participants cp
            where cp.conversation_id = conversation_participants.conversation_id
              and cp.user_id = auth.uid()
        )
    );

create policy "Users can join conversations"
    on public.conversation_participants for insert
    with check (user_id = auth.uid());

create policy "Users can update their participation"
    on public.conversation_participants for update
    using (user_id = auth.uid());

-- Messages: users can view messages in their conversations
create policy "Users can view messages in their conversations"
    on public.messages for select
    using (
        exists (
            select 1 from public.conversation_participants
            where conversation_id = messages.conversation_id
              and user_id = auth.uid()
        )
    );

create policy "Users can send messages to their conversations"
    on public.messages for insert
    with check (
        user_id = auth.uid() and
        exists (
            select 1 from public.conversation_participants
            where conversation_id = messages.conversation_id
              and user_id = auth.uid()
        )
    );

create policy "Users can update their own messages"
    on public.messages for update
    using (user_id = auth.uid());

create policy "Users can delete their own messages"
    on public.messages for delete
    using (user_id = auth.uid());

-- Message reactions
create policy "Users can view reactions"
    on public.message_reactions for select
    using (
        exists (
            select 1 from public.messages m
            join public.conversation_participants cp on cp.conversation_id = m.conversation_id
            where m.id = message_reactions.message_id
              and cp.user_id = auth.uid()
        )
    );

create policy "Users can add reactions"
    on public.message_reactions for insert
    with check (user_id = auth.uid());

create policy "Users can remove their reactions"
    on public.message_reactions for delete
    using (user_id = auth.uid());

-- Typing indicators
create policy "Users can view typing indicators"
    on public.typing_indicators for select
    using (
        exists (
            select 1 from public.conversation_participants
            where conversation_id = typing_indicators.conversation_id
              and user_id = auth.uid()
        )
    );

create policy "Users can set their typing status"
    on public.typing_indicators for insert
    with check (user_id = auth.uid());

create policy "Users can update their typing status"
    on public.typing_indicators for update
    using (user_id = auth.uid());

create policy "Users can remove their typing status"
    on public.typing_indicators for delete
    using (user_id = auth.uid());
