-- 05: claims — claim requests with reporter approval.
-- Approving a claim flips the item to status='claimed' and rejects sibling
-- pending claims, all in one trigger.

create table public.claims (
  id           uuid primary key default gen_random_uuid(),
  item_id      uuid not null references public.items(id) on delete cascade,
  claimer_id   uuid not null references public.profiles(id) on delete cascade,
  message      text,
  state        claim_state not null default 'pending',
  decided_at   timestamptz,
  decided_by   uuid references public.profiles(id),
  created_at   timestamptz not null default now(),
  unique (item_id, claimer_id)
);

comment on table public.claims is 'Claim requests on items. One per (item, claimer).';

create index claims_item_idx     on public.claims (item_id);
create index claims_claimer_idx  on public.claims (claimer_id);
create index claims_state_idx    on public.claims (state);

-- Side-effects when a claim transitions to 'approved':
--   * item.status becomes 'claimed'
--   * item.claimed_by / claimed_at are set
--   * any other pending claims on the same item flip to 'rejected'
create or replace function public.handle_claim_approval()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.state = 'approved' and (old.state is distinct from 'approved') then
    update public.items
       set status     = 'claimed',
           claimed_by = new.claimer_id,
           claimed_at = now()
     where id = new.item_id;

    update public.claims
       set state       = 'rejected',
           decided_at  = now(),
           decided_by  = new.decided_by
     where item_id = new.item_id
       and id <> new.id
       and state = 'pending';
  end if;
  return new;
end;
$$;

create trigger claims_on_approve
  after update of state on public.claims
  for each row execute function public.handle_claim_approval();

-- Block claims by the reporter on their own item.
create or replace function public.reject_self_claim()
returns trigger
language plpgsql
as $$
declare
  v_reporter uuid;
begin
  select reporter_id into v_reporter from public.items where id = new.item_id;
  if v_reporter = new.claimer_id then
    raise exception 'cannot claim your own item';
  end if;
  return new;
end;
$$;

create trigger claims_no_self
  before insert on public.claims
  for each row execute function public.reject_self_claim();
