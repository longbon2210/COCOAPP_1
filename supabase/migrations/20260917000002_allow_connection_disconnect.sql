-- CocoApp Phase 4A follow-up: allow either participant to disconnect.
-- Existing connection request rows are retained as cancelled history.

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
    if old.status = 'pending' then
      if new.status in ('accepted', 'declined')
        and (select auth.uid()) <> old.recipient_id then
        raise exception 'Only the recipient can accept or decline a request';
      end if;

      if new.status = 'cancelled'
        and (select auth.uid()) <> old.requester_id then
        raise exception 'Only the requester can cancel a request';
      end if;
    elsif old.status = 'accepted' then
      if new.status <> 'cancelled'
        or (select auth.uid()) not in (old.requester_id, old.recipient_id) then
        raise exception 'Only a participant can disconnect an accepted request';
      end if;
    else
      raise exception 'Only pending or accepted requests can change status';
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

drop policy if exists "Participants can disconnect accepted requests"
  on public.connection_requests;
create policy "Participants can disconnect accepted requests"
  on public.connection_requests
  for update
  to authenticated
  using (
    (select auth.uid()) in (requester_id, recipient_id)
    and status = 'accepted'
  )
  with check (
    (select auth.uid()) in (requester_id, recipient_id)
    and status = 'cancelled'
  );
