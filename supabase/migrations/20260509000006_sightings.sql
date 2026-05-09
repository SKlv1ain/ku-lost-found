-- 06: sightings — "I saw this" tips on lost items.

create table public.sightings (
  id          uuid primary key default gen_random_uuid(),
  item_id     uuid not null references public.items(id) on delete cascade,
  spotter_id  uuid not null references public.profiles(id) on delete cascade,
  note        text,
  lat         double precision,
  lng         double precision,
  created_at  timestamptz not null default now(),
  constraint sightings_coords_pair check (
    (lat is null and lng is null) or (lat is not null and lng is not null)
  )
);

comment on table public.sightings is 'Helpful "I saw this" reports on lost items.';

create index sightings_item_idx    on public.sightings (item_id);
create index sightings_spotter_idx on public.sightings (spotter_id);
