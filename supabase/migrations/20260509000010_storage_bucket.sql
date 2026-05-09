-- 10: Storage bucket and policies for item photos.
-- Public read, authenticated write into a per-user prefix.
-- Path convention: {user_id}/{item_id}/{uuid}.jpg

insert into storage.buckets (id, name, public)
values ('item-photos', 'item-photos', true)
on conflict (id) do nothing;

-- Anyone can read (bucket is public, but be explicit for RLS path).
create policy "item-photos: public read"
  on storage.objects for select
  to public
  using (bucket_id = 'item-photos');

-- Authenticated users can upload only under their own user_id prefix.
create policy "item-photos: insert under own folder"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'item-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "item-photos: update own"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'item-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "item-photos: delete own"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'item-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );
