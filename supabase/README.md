# Supabase — KU Lost & Found

Postgres schema, RLS policies, and Storage setup for the SwiftUI app.

## Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli) (`brew install supabase/tap/supabase`)
- Docker Desktop (the CLI uses it to boot a local Postgres + Studio)

## Local development

From the repo root:

```bash
supabase start          # boots Postgres + Studio + Auth + Storage on :54321/54322/54323
supabase db reset       # runs migrations/*.sql in order, then seed.sql
```

Studio: <http://127.0.0.1:54323>
Postgres: `postgresql://postgres:postgres@127.0.0.1:54322/postgres`

To re-apply just the latest migration without wiping data:

```bash
supabase migration up
```

## Schema overview

| Table | Purpose |
|---|---|
| `profiles` | 1:1 with `auth.users`; full_name, faculty, year, avatar |
| `items` | Lost / found reports (status, category, lat/lng, reporter) |
| `item_photos` | ≤5 Storage-backed photos per item |
| `claims` | Claim requests; reporter approves → item flips to `claimed` |
| `sightings` | "I saw this" tips on lost items |
| `notifications` | Bell-icon feed; populated by triggers only |
| `profile_stats` (view) | Per-user counts shown on Profile |

Enums: `item_status`, `item_category`, `claim_state`, `notification_kind`.

Storage bucket: `item-photos` — public read, authenticated write into `{user_id}/{item_id}/…`.

## RLS at a glance

- **Read** — `items`, `item_photos`, `sightings`, `profiles` are readable by any authenticated user. `claims` only by participants. `notifications` only by their owner.
- **Write** — users can mutate only their own rows; reporter exclusively decides on claims.
- **Server-only** — `notifications` rows are inserted by `security definer` triggers; clients can only mark them read/delete.

See `migrations/20260509000009_rls_policies.sql` for the canonical policy list.

## Production

1. `supabase link --project-ref <your-ref>`
2. `supabase db push` to apply migrations.
3. In the dashboard:
   - Auth → Providers → Google: paste `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET`.
   - Storage → confirm `item-photos` bucket exists and is public.
4. Set the iOS app's `SUPABASE_URL` and `SUPABASE_ANON_KEY` (Info.plist or xcconfig).

## Env vars (local Google OAuth, optional)

```
GOOGLE_CLIENT_ID=xxxxx.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=xxxxx
```

Place these in `.env` next to `config.toml` or export them in your shell before `supabase start`.

## Verification checklist

After `supabase db reset`:

- [ ] `select count(*) from public.items;` returns `7`
- [ ] `select * from public.profile_stats;` returns the demo user row
- [ ] Studio → Authentication shows `demo@ku.test`
- [ ] Studio → Storage shows the `item-photos` bucket
- [ ] Try inserting a claim from another auth user — RLS should permit it; the demo user (reporter) should see it via the read policy
