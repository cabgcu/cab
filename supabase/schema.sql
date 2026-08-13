-- Cards Against Bad (Conversation) — Supabase schema
--
-- Run this once in the Supabase SQL Editor for this project:
-- https://supabase.com/dashboard/project/nmmshjdknmuzpgpquwec/sql/new
--
-- The app is a static HTML page with no server, so it only ever talks to
-- Supabase using the publishable (anon) key. This schema's Row Level
-- Security policies are what keep that safe: anyone with the anon key can
-- read/write rooms (this is a party game with no accounts or private
-- data), but nothing else in the project is exposed.

create table if not exists public.rooms (
    code text primary key,
    host_id text not null,
    status text not null default 'waiting',
    level integer not null default 1,
    is_flipped boolean not null default false,
    current_question text,
    card_key bigint,
    used_questions jsonb not null default '{"1":[],"2":[],"3":[],"4":[]}'::jsonb,
    players jsonb not null default '{}'::jsonb,
    turn_order jsonb not null default '[]'::jsonb,
    current_turn_index integer not null default 0,
    created_at timestamptz not null default now()
);

alter table public.rooms enable row level security;

drop policy if exists "Anyone can read rooms" on public.rooms;
create policy "Anyone can read rooms"
    on public.rooms for select
    using (true);

drop policy if exists "Anyone can create rooms" on public.rooms;
create policy "Anyone can create rooms"
    on public.rooms for insert
    with check (true);

drop policy if exists "Anyone can update rooms" on public.rooms;
create policy "Anyone can update rooms"
    on public.rooms for update
    using (true);

-- Needed so realtime UPDATE/DELETE events carry full row data for the
-- `code=eq.*` filter the client subscribes with.
alter table public.rooms replica identity full;

-- Enable realtime replication so clients get live postgres_changes events.
-- (Wrapped so re-running this script is safe if it's already enabled.)
do $$
begin
    if not exists (
        select 1 from pg_publication_tables
        where pubname = 'supabase_realtime'
          and schemaname = 'public'
          and tablename = 'rooms'
    ) then
        alter publication supabase_realtime add table public.rooms;
    end if;
end $$;
