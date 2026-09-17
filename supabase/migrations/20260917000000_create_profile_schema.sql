-- CocoApp Phase 2A: profile schema

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  university text not null default '',
  major text not null default '',
  study_year text not null default '',
  gender text not null default '',
  purpose text not null default '',
  bio text not null default '' check (char_length(bio) <= 180),
  city text not null default '',
  area text not null default '',
  public_location text not null default '',
  max_distance_km integer not null default 3 check (max_distance_km in (1, 3, 5, 10)),
  verification_status text not null default 'unverified'
    check (verification_status in ('unverified', 'pending', 'verified')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.profile_private (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  phone text,
  exact_address text,
  hide_phone boolean not null default true,
  hide_exact_address boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists profile_private_set_updated_at on public.profile_private;
create trigger profile_private_set_updated_at
before update on public.profile_private
for each row execute function public.set_updated_at();

create or replace function public.create_profile_for_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'fullName', ''))
  on conflict (id) do nothing;

  insert into public.profile_private (profile_id)
  values (new.id)
  on conflict (profile_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.create_profile_for_user();

insert into public.profiles (id, full_name)
select
  users.id,
  coalesce(
    nullif(btrim(users.raw_user_meta_data ->> 'fullName'), ''),
    nullif(btrim(users.raw_user_meta_data ->> 'full_name'), ''),
    nullif(split_part(users.email, '@', 1), ''),
    ''
  )
from auth.users as users
on conflict (id) do nothing;

create or replace function public.prevent_profile_verification_change()
returns trigger
language plpgsql
as $$
begin
  if (
      (tg_op = 'INSERT' and new.verification_status <> 'unverified')
      or (tg_op = 'UPDATE' and new.verification_status is distinct from old.verification_status)
    )
    and current_user not in ('postgres', 'service_role', 'supabase_admin') then
    raise exception 'verification_status is managed by the platform';
  end if;

  return new;
end;
$$;

drop trigger if exists profiles_prevent_verification_change on public.profiles;
create trigger profiles_prevent_verification_change
before insert or update on public.profiles
for each row execute function public.prevent_profile_verification_change();

alter table public.profiles enable row level security;
alter table public.profile_private enable row level security;

drop policy if exists "Authenticated users can view public profiles"
  on public.profiles;
create policy "Authenticated users can view public profiles"
  on public.profiles
  for select
  to authenticated
  using (true);

drop policy if exists "Users can create their own profile" on public.profiles;
create policy "Users can create their own profile"
  on public.profiles
  for insert
  to authenticated
  with check ((select auth.uid()) = id);

drop policy if exists "Users can update their own profile" on public.profiles;
create policy "Users can update their own profile"
  on public.profiles
  for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

drop policy if exists "Users can view their private profile" on public.profile_private;
create policy "Users can view their private profile"
  on public.profile_private
  for select
  to authenticated
  using ((select auth.uid()) = profile_id);

drop policy if exists "Users can create their private profile"
  on public.profile_private;
create policy "Users can create their private profile"
  on public.profile_private
  for insert
  to authenticated
  with check ((select auth.uid()) = profile_id);

drop policy if exists "Users can update their private profile"
  on public.profile_private;
create policy "Users can update their private profile"
  on public.profile_private
  for update
  to authenticated
  using ((select auth.uid()) = profile_id)
  with check ((select auth.uid()) = profile_id);