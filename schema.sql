-- Broiler Farm Manager: Supabase setup
-- Run in Supabase SQL Editor before connecting the app.
create extension if not exists pgcrypto;

-- Profile IDs match Supabase Auth user IDs so RLS can isolate farm data.
create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  role text not null default 'farmer' check (role in ('farmer','supervisor','trader')),
  district text not null default '',
  state text not null default '',
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.broiler_batches (
  batch_id uuid primary key default gen_random_uuid(),
  farmer_id uuid not null references public.users(id) on delete cascade,
  breed_type text not null default 'Cobb 500',
  chicks_placed int not null check (chicks_placed > 0),
  placement_date date not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.daily_logs (
  log_id uuid primary key default gen_random_uuid(),
  batch_id uuid not null references public.broiler_batches(batch_id) on delete cascade,
  day_age int not null check (day_age >= 0),
  daily_mortality int not null default 0 check (daily_mortality >= 0),
  feed_consumed_bags numeric(5,2) not null check (feed_consumed_bags >= 0),
  avg_body_weight_grams numeric(6,2),
  water_intake_litres int,
  logged_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.mandi_rates (
  rate_id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  date date not null,
  state text not null,
  district text not null,
  broiler_rate_per_kg numeric(7,2) not null check (broiler_rate_per_kg >= 0),
  logged_at timestamptz not null default timezone('utc', now())
);


-- Explicit API grants. RLS policies below still control which rows each user can access.
grant usage on schema public to authenticated;
grant select, insert, update on table public.users to authenticated;
grant select, insert, update, delete on table public.broiler_batches to authenticated;
grant select, insert, update, delete on table public.daily_logs to authenticated;
grant select, insert, update, delete on table public.mandi_rates to authenticated;

alter table public.users enable row level security;
alter table public.broiler_batches enable row level security;
alter table public.daily_logs enable row level security;
alter table public.mandi_rates enable row level security;

drop policy if exists "users read own profile" on public.users;
create policy "users read own profile" on public.users for select to authenticated using (id = auth.uid());
drop policy if exists "users insert own profile" on public.users;
create policy "users insert own profile" on public.users for insert to authenticated with check (id = auth.uid());
drop policy if exists "users update own profile" on public.users;
create policy "users update own profile" on public.users for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "owner manages batches" on public.broiler_batches;
create policy "owner manages batches" on public.broiler_batches for all to authenticated
using (farmer_id = auth.uid()) with check (farmer_id = auth.uid());

drop policy if exists "owner manages daily logs" on public.daily_logs;
create policy "owner manages daily logs" on public.daily_logs for all to authenticated
using (exists (select 1 from public.broiler_batches b where b.batch_id = daily_logs.batch_id and b.farmer_id = auth.uid()))
with check (exists (select 1 from public.broiler_batches b where b.batch_id = daily_logs.batch_id and b.farmer_id = auth.uid()));

drop policy if exists "authenticated read mandi rates" on public.mandi_rates;
create policy "authenticated read mandi rates" on public.mandi_rates for select to authenticated using (true);
drop policy if exists "owner inserts mandi rates" on public.mandi_rates;
create policy "owner inserts mandi rates" on public.mandi_rates for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "owner updates mandi rates" on public.mandi_rates;
create policy "owner updates mandi rates" on public.mandi_rates for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "owner deletes mandi rates" on public.mandi_rates;
create policy "owner deletes mandi rates" on public.mandi_rates for delete to authenticated using (user_id = auth.uid());

-- Enable Email/Password provider in Supabase Authentication settings.
