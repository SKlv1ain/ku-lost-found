-- 01: Domain enums shared across tables.
-- Names mirror Swift enums in Models/Item.swift so the iOS layer can
-- encode/decode raw values directly.

create type item_status as enum (
  'lost',
  'found',
  'claimed',
  'expired'
);

create type item_category as enum (
  'electronics',
  'clothing',
  'id_card',
  'keys',
  'bag',
  'books',
  'other'
);

create type claim_state as enum (
  'pending',
  'approved',
  'rejected',
  'withdrawn'
);

create type notification_kind as enum (
  'claim_submitted',
  'claim_approved',
  'claim_rejected',
  'sighting_added'
);
