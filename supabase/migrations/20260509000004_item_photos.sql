-- 04: item_photos — multiple Storage-backed photos per item.

create table public.item_photos (
  id             uuid primary key default gen_random_uuid(),
  item_id        uuid not null references public.items(id) on delete cascade,
  storage_path   text not null,
  display_order  smallint not null default 0 check (display_order >= 0 and display_order < 5),
  created_at     timestamptz not null default now(),
  unique (item_id, display_order)
);

comment on table public.item_photos is 'Up to 5 photos per item, ordered by display_order.';

create index item_photos_item_idx on public.item_photos (item_id);

-- Hard cap of 5 photos per item, enforced server-side.
create or replace function public.enforce_item_photos_limit()
returns trigger
language plpgsql
as $$
begin
  if (select count(*) from public.item_photos where item_id = new.item_id) >= 5 then
    raise exception 'item % already has 5 photos (max)', new.item_id;
  end if;
  return new;
end;
$$;

create trigger item_photos_limit
  before insert on public.item_photos
  for each row execute function public.enforce_item_photos_limit();
