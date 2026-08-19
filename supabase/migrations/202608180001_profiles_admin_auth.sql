-- Repair migration for projects where the Auth user exists before the ecommerce schema.
-- This is deliberately limited to the profile/role foundation used by AdminApp.

do $$
begin
  create type public.profile_role as enum ('customer', 'admin');
exception
  when duplicate_object then null;
end $$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role public.profile_role not null default 'customer',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.set_profile_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at
before update on public.profiles
for each row execute function public.set_profile_updated_at();

create or replace function public.handle_new_user_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id)
  values (new.id)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_profile_created on auth.users;
create trigger on_auth_user_profile_created
after insert on auth.users
for each row execute function public.handle_new_user_profile();

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

alter table public.profiles enable row level security;

drop policy if exists "profiles own or admin" on public.profiles;
create policy "profiles own or admin"
on public.profiles for select
using (id = auth.uid() or public.is_admin());

-- No client-side update policy is granted: users cannot promote themselves.

insert into public.profiles (id, role)
select id, 'admin'::public.profile_role
from auth.users
where email = 'memory@kraft.in'
on conflict (id) do update
set role = excluded.role;

do $$
begin
  if not exists (select 1 from auth.users where email = 'memory@kraft.in') then
    raise exception 'Existing Auth user memory@kraft.in was not found';
  end if;
end $$;
