-- 02: profiles — extends auth.users with KU-specific fields.
-- A profile row is created automatically on signup via trigger.

create table public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  full_name   text not null,
  avatar_url  text,
  faculty     text,
  year        smallint check (year between 1 and 8),
  created_at  timestamptz not null default now()
);

comment on table public.profiles is 'KU Lost & Found user profile, 1:1 with auth.users.';

-- Auto-create a profile when a new auth user signs up.
-- Pulls full_name from raw_user_meta_data (set by client at signup) or falls
-- back to the email local-part so the row never violates not-null.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, avatar_url)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      nullif(new.raw_user_meta_data ->> 'name', ''),
      split_part(new.email, '@', 1)
    ),
    new.raw_user_meta_data ->> 'avatar_url'
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
