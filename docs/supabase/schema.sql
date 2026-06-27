-- ROLA Supabase schema (Milestone 7)
-- Run in the Supabase SQL editor after creating a project.

-- Profiles table (extends auth.users)
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  onboarding_complete boolean default false,
  created_at timestamptz default now()
);

-- Style profiles (derived traits only — no raw messages)
create table if not exists public.style_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  scope text not null check (scope in ('global', 'contact')),
  contact_hash text,
  traits jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  unique (user_id, scope, contact_hash)
);

-- Feedback events (learning signals)
create table if not exists public.feedback_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  suggestion_id uuid not null,
  contact_hash text not null,
  original_text text not null,
  final_text text not null,
  action text not null check (action in ('approved', 'edited', 'dismissed')),
  created_at timestamptz not null default now()
);

-- Row Level Security
alter table public.profiles enable row level security;
alter table public.style_profiles enable row level security;
alter table public.feedback_events enable row level security;

create policy "Users manage own profile"
  on public.profiles for all
  using (auth.uid() = id)
  with check (auth.uid() = id);

create policy "Users manage own style profiles"
  on public.style_profiles for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users manage own feedback"
  on public.feedback_events for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, new.email);
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
