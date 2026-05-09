-- 09: Row-Level Security — all policies in one file for review.

alter table public.profiles      enable row level security;
alter table public.items         enable row level security;
alter table public.item_photos   enable row level security;
alter table public.claims        enable row level security;
alter table public.sightings     enable row level security;
alter table public.notifications enable row level security;

-- ─────────────────────────────────────────────────────────────
-- profiles
-- ─────────────────────────────────────────────────────────────
create policy "profiles: read all (authenticated)"
  on public.profiles for select
  to authenticated
  using (true);

create policy "profiles: insert self"
  on public.profiles for insert
  to authenticated
  with check (id = auth.uid());

create policy "profiles: update self"
  on public.profiles for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- ─────────────────────────────────────────────────────────────
-- items
-- ─────────────────────────────────────────────────────────────
create policy "items: read all (authenticated)"
  on public.items for select
  to authenticated
  using (true);

create policy "items: insert by reporter"
  on public.items for insert
  to authenticated
  with check (reporter_id = auth.uid());

create policy "items: update by reporter"
  on public.items for update
  to authenticated
  using (reporter_id = auth.uid())
  with check (reporter_id = auth.uid());

create policy "items: delete by reporter"
  on public.items for delete
  to authenticated
  using (reporter_id = auth.uid());

-- ─────────────────────────────────────────────────────────────
-- item_photos — only the item's reporter can mutate
-- ─────────────────────────────────────────────────────────────
create policy "item_photos: read all (authenticated)"
  on public.item_photos for select
  to authenticated
  using (true);

create policy "item_photos: insert by item reporter"
  on public.item_photos for insert
  to authenticated
  with check (
    exists (
      select 1 from public.items i
      where i.id = item_id and i.reporter_id = auth.uid()
    )
  );

create policy "item_photos: delete by item reporter"
  on public.item_photos for delete
  to authenticated
  using (
    exists (
      select 1 from public.items i
      where i.id = item_id and i.reporter_id = auth.uid()
    )
  );

-- ─────────────────────────────────────────────────────────────
-- claims — visible to claimer and item reporter only
-- ─────────────────────────────────────────────────────────────
create policy "claims: read by participants"
  on public.claims for select
  to authenticated
  using (
    claimer_id = auth.uid()
    or exists (
      select 1 from public.items i
      where i.id = item_id and i.reporter_id = auth.uid()
    )
  );

create policy "claims: insert by claimer"
  on public.claims for insert
  to authenticated
  with check (claimer_id = auth.uid());

-- Reporter approves / rejects.
create policy "claims: reporter decides"
  on public.claims for update
  to authenticated
  using (
    exists (
      select 1 from public.items i
      where i.id = item_id and i.reporter_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.items i
      where i.id = item_id and i.reporter_id = auth.uid()
    )
  );

-- Claimer can withdraw their own pending claim.
create policy "claims: claimer withdraws"
  on public.claims for update
  to authenticated
  using (claimer_id = auth.uid())
  with check (claimer_id = auth.uid() and state in ('pending','withdrawn'));

-- ─────────────────────────────────────────────────────────────
-- sightings
-- ─────────────────────────────────────────────────────────────
create policy "sightings: read all (authenticated)"
  on public.sightings for select
  to authenticated
  using (true);

create policy "sightings: insert by spotter"
  on public.sightings for insert
  to authenticated
  with check (spotter_id = auth.uid());

create policy "sightings: delete by spotter"
  on public.sightings for delete
  to authenticated
  using (spotter_id = auth.uid());

-- ─────────────────────────────────────────────────────────────
-- notifications — own only; trigger inserts bypass via security definer
-- ─────────────────────────────────────────────────────────────
create policy "notifications: read own"
  on public.notifications for select
  to authenticated
  using (user_id = auth.uid());

create policy "notifications: mark own read"
  on public.notifications for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "notifications: delete own"
  on public.notifications for delete
  to authenticated
  using (user_id = auth.uid());
