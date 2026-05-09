-- 07: notifications — populated only by triggers, never written directly.

create table public.notifications (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  kind        notification_kind not null,
  item_id     uuid references public.items(id) on delete cascade,
  actor_id    uuid references public.profiles(id) on delete set null,
  read_at     timestamptz,
  created_at  timestamptz not null default now()
);

comment on table public.notifications is 'Bell-icon feed; rows authored by triggers only.';

create index notifications_user_unread_idx
  on public.notifications (user_id, created_at desc)
  where read_at is null;

-- Trigger: claim inserted → notify item reporter.
create or replace function public.notify_on_claim_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_reporter uuid;
begin
  select reporter_id into v_reporter from public.items where id = new.item_id;
  insert into public.notifications (user_id, kind, item_id, actor_id)
  values (v_reporter, 'claim_submitted', new.item_id, new.claimer_id);
  return new;
end;
$$;

create trigger claims_notify_insert
  after insert on public.claims
  for each row execute function public.notify_on_claim_insert();

-- Trigger: claim state change → notify claimer of the decision.
create or replace function public.notify_on_claim_decision()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.state = 'approved' and old.state is distinct from 'approved' then
    insert into public.notifications (user_id, kind, item_id, actor_id)
    values (new.claimer_id, 'claim_approved', new.item_id, new.decided_by);
  elsif new.state = 'rejected' and old.state is distinct from 'rejected' then
    insert into public.notifications (user_id, kind, item_id, actor_id)
    values (new.claimer_id, 'claim_rejected', new.item_id, new.decided_by);
  end if;
  return new;
end;
$$;

create trigger claims_notify_decision
  after update of state on public.claims
  for each row execute function public.notify_on_claim_decision();

-- Trigger: sighting inserted → notify item reporter.
create or replace function public.notify_on_sighting()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_reporter uuid;
begin
  select reporter_id into v_reporter from public.items where id = new.item_id;
  insert into public.notifications (user_id, kind, item_id, actor_id)
  values (v_reporter, 'sighting_added', new.item_id, new.spotter_id);
  return new;
end;
$$;

create trigger sightings_notify
  after insert on public.sightings
  for each row execute function public.notify_on_sighting();
