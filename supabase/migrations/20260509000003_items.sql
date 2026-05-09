-- 03: items — the core lost/found report.

create table public.items (
  id             uuid primary key default gen_random_uuid(),
  reporter_id    uuid not null references public.profiles(id) on delete cascade,
  title          text not null check (length(title) between 1 and 120),
  description    text,
  status         item_status not null,
  category       item_category not null,
  emoji          text,
  location_name  text not null,
  lat            double precision,
  lng            double precision,
  occurred_at    timestamptz not null,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  claimed_by     uuid references public.profiles(id) on delete set null,
  claimed_at     timestamptz,

  -- claimed_by is only meaningful when status = 'claimed'
  constraint items_claim_consistency check (
    (status = 'claimed' and claimed_by is not null and claimed_at is not null)
    or (status <> 'claimed' and claimed_by is null and claimed_at is null)
  ),
  -- lat/lng must come as a pair (or both null)
  constraint items_coords_pair check (
    (lat is null and lng is null) or (lat is not null and lng is not null)
  )
);

comment on table public.items is 'Lost / found item reports. One row per report.';

create index items_status_idx       on public.items (status);
create index items_category_idx     on public.items (category);
create index items_reporter_idx     on public.items (reporter_id);
create index items_created_at_idx   on public.items (created_at desc);
create index items_coords_idx       on public.items (lat, lng) where lat is not null;

-- Maintain updated_at on every row update.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger items_set_updated_at
  before update on public.items
  for each row execute function public.set_updated_at();
