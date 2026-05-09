-- 08: profile_stats — derived counts shown on Profile screen.
-- Kept as a view (no denormalisation) so counts can never drift.

create or replace view public.profile_stats as
select
  p.id,
  (select count(*)::int from public.items     i where i.reporter_id = p.id)                                        as reported_count,
  (select count(*)::int from public.items     i where i.reporter_id = p.id and i.status = 'claimed')               as returned_count,
  (
    (select count(*)::int from public.claims    c where c.claimer_id = p.id and c.state = 'approved')
    + (select count(*)::int from public.sightings s where s.spotter_id = p.id)
  ) as helped_count
from public.profiles p;

comment on view public.profile_stats is
  'Per-user counts: items reported, items returned, items helped (approved claims + sightings).';
