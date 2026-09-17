-- CocoApp Phase 4B: connection notifications.
-- Only future connection request events create notifications; this migration does not backfill.

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  actor_id uuid not null references public.profiles(id) on delete cascade,
  connection_request_id uuid not null
    references public.connection_requests(id) on delete cascade,
  type text not null check (
    type in (
      'request_received',
      'request_accepted',
      'request_declined',
      'request_cancelled',
      'connection_disconnected'
    )
  ),
  read_at timestamptz,
  created_at timestamptz not null default now(),
  constraint notifications_not_self check (recipient_id <> actor_id)
);

create unique index if not exists notifications_connection_event_idx
  on public.notifications (connection_request_id, recipient_id, type);

create index if not exists notifications_recipient_created_idx
  on public.notifications (recipient_id, created_at desc);

create index if not exists notifications_recipient_unread_idx
  on public.notifications (recipient_id, created_at desc)
  where read_at is null;

create or replace function public.create_connection_notification()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  notification_recipient_id uuid;
  notification_actor_id uuid;
  notification_type text;
begin
  if tg_op = 'INSERT' then
    notification_recipient_id := new.recipient_id;
    notification_actor_id := new.requester_id;
    notification_type := 'request_received';
  elsif new.status is not distinct from old.status then
    return new;
  elsif new.status = 'accepted' and old.status = 'pending' then
    notification_recipient_id := old.requester_id;
    notification_actor_id := old.recipient_id;
    notification_type := 'request_accepted';
  elsif new.status = 'declined' and old.status = 'pending' then
    notification_recipient_id := old.requester_id;
    notification_actor_id := old.recipient_id;
    notification_type := 'request_declined';
  elsif new.status = 'cancelled' and old.status = 'pending' then
    notification_recipient_id := old.recipient_id;
    notification_actor_id := old.requester_id;
    notification_type := 'request_cancelled';
  elsif new.status = 'cancelled' and old.status = 'accepted' then
    notification_actor_id := auth.uid();

    if notification_actor_id = old.requester_id then
      notification_recipient_id := old.recipient_id;
    elsif notification_actor_id = old.recipient_id then
      notification_recipient_id := old.requester_id;
    else
      return new;
    end if;

    notification_type := 'connection_disconnected';
  else
    return new;
  end if;

  if notification_actor_id is null
    or notification_recipient_id is null
    or notification_actor_id = notification_recipient_id then
    return new;
  end if;

  insert into public.notifications (
    recipient_id,
    actor_id,
    connection_request_id,
    type
  )
  values (
    notification_recipient_id,
    notification_actor_id,
    new.id,
    notification_type
  )
  on conflict (connection_request_id, recipient_id, type) do nothing;

  return new;
end;
$$;

drop trigger if exists connection_requests_create_notification
  on public.connection_requests;
create trigger connection_requests_create_notification
after insert or update of status on public.connection_requests
for each row execute function public.create_connection_notification();

create or replace function public.protect_notification_update()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.recipient_id is distinct from old.recipient_id
    or new.actor_id is distinct from old.actor_id
    or new.connection_request_id is distinct from old.connection_request_id
    or new.type is distinct from old.type
    or new.created_at is distinct from old.created_at then
    raise exception 'Notification event fields cannot be changed';
  end if;

  if old.read_at is not null then
    new.read_at := old.read_at;
  else
    new.read_at := now();
  end if;

  return new;
end;
$$;

drop trigger if exists notifications_protect_update on public.notifications;
create trigger notifications_protect_update
before update on public.notifications
for each row execute function public.protect_notification_update();

alter table public.notifications enable row level security;

revoke all on table public.notifications from anon, authenticated;
grant select on table public.notifications to authenticated;
grant update (read_at) on table public.notifications to authenticated;

drop policy if exists "Users can view their notifications"
  on public.notifications;
create policy "Users can view their notifications"
  on public.notifications
  for select
  to authenticated
  using ((select auth.uid()) = recipient_id);

drop policy if exists "Users can mark their notifications as read"
  on public.notifications;
create policy "Users can mark their notifications as read"
  on public.notifications
  for update
  to authenticated
  using ((select auth.uid()) = recipient_id)
  with check ((select auth.uid()) = recipient_id);

revoke all on function public.create_connection_notification() from public;
revoke all on function public.protect_notification_update() from public;

do $$
begin
  if exists (
    select 1
    from pg_publication
    where pubname = 'supabase_realtime'
  ) and not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end;
$$;
