-- Chạy 1 lần trong Supabase: Dashboard -> SQL Editor -> New query -> Run
-- Thêm tọa độ + bán kính cho nhắc nhở theo vị trí (GPS)
alter table public.tasks
  add column if not exists "locationLat" double precision,
  add column if not exists "locationLng" double precision,
  add column if not exists "locationRadius" integer default 300;
