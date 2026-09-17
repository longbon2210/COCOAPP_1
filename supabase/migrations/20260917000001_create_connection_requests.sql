-- CocoApp Phase 4A: connection requests
-- Purpose values are stable internal identifiers:
-- study_group = Học nhóm, team_project = Team Project, roommates = Ghép trọ.

create table if not exists public.connection_requests (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles(id) on delete cascade,
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  purpose text not null check (purpose in ('study_group', 'team_project', 'roommates')),
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  responded_at timestamptz,
  constraint connection_requests_not_self check (requester_id <> recipient_id)
);

create unique index if not exists connection_requests_active_pair_idx
  on public.connection_requests (
    least(requester_id, recipient_id),
    greatest(requester_id, recipient_id)
  )
  where status in ('pending', 'accepted');

create index if not exists connection_requests_recipient_status_idx
  on public.connection_requests (recipient_id, status, created_at desc);

create index if not exists connection_requests_requester_status_idx
  on public.connection_requests (requester_id, status, created_at desc);

create or replace function public.connection_requests_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists connection_requests_set_updated_at
  on public.connection_requests;
create trigger connection_requests_set_updated_at
before update on public.connection_requests
for each row execute function public.connection_requests_set_updated_at();

create or replace function public.validate_connection_request()
returns trigger
language plpgsql
as $$
declare
  requester_gender text;
  recipient_gender text;
begin
  if tg_op = 'INSERT' then
    if new.status <> 'pending' then
      raise exception 'New connection requests must be pending';
    end if;

    if new.requester_id <> (select auth.uid()) then
      raise exception 'Only the requester can create a connection request';
    end if;

    if new.purpose = 'roommates' then
      select gender into requester_gender
      from public.profiles
      where id = new.requester_id;

      select gender into recipient_gender
      from public.profiles
      where id = new.recipient_id;

      if nullif(btrim(requester_gender), '') is null
        or nullif(btrim(recipient_gender), '') is null
        or requester_gender <> recipient_gender then
        raise exception 'Roommate requests require matching genders';
      end if;
    end if;

    new.responded_at = null;
    return new;
  end if;

  if new.requester_id is distinct from old.requester_id
    or new.recipient_id is distinct from old.recipient_id
    or new.purpose is distinct from old.purpose then
    raise exception 'Requester, recipient, and purpose cannot be changed';
  end if;

  if new.status is distinct from old.status then
    if old.status <> 'pending' then
      raise exception 'Only pending requests can change status';
    end if;

    if new.status in ('accepted', 'declined')
      and (select auth.uid()) <> old.recipient_id then
      raise exception 'Only the recipient can accept or decline a request';
    end if;

    if new.status = 'cancelled'
      and (select auth.uid()) <> old.requester_id then
      raise exception 'Only the requester can cancel a request';
    end if;

    if new.status not in ('accepted', 'declined', 'cancelled') then
      raise exception 'Invalid connection request transition';
    end if;

    new.responded_at = now();
  else
    new.responded_at = old.responded_at;
  end if;

  return new;
end;
$$;

drop trigger if exists connection_requests_validate
  on public.connection_requests;
create trigger connection_requests_validate
before insert or update on public.connection_requests
for each row execute function public.validate_connection_request();

alter table public.connection_requests enable row level security;

grant select, insert, update on public.connection_requests to authenticated;

drop policy if exists "Participants can view connection requests"
  on public.connection_requests;
create policy "Participants can view connection requests"
  on public.connection_requests
  for select
  to authenticated
  using ((select auth.uid()) in (requester_id, recipient_id));

drop policy if exists "Requesters can create pending requests"
  on public.connection_requests;
create policy "Requesters can create pending requests"
  on public.connection_requests
  for insert
  to authenticated
  with check (
    requester_id = (select auth.uid())
    and status = 'pending'
  );

drop policy if exists "Recipients can accept or decline requests"
  on public.connection_requests;
create policy "Recipients can accept or decline requests"
  on public.connection_requests
  for update
  to authenticated
  using (
    recipient_id = (select auth.uid())
    and status = 'pending'
  )
  with check (
    recipient_id = (select auth.uid())
    and status in ('accepted', 'declined')
  );

drop policy if exists "Requesters can cancel pending requests"
  on public.connection_requests;
create policy "Requesters can cancel pending requests"
  on public.connection_requests
  for update
  to authenticated
  using (
    requester_id = (select auth.uid())
    and status = 'pending'
  )
  with check (
    requester_id = (select auth.uid())
    and status = 'cancelled'
  );
