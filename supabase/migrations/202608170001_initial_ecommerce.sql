create extension if not exists pgcrypto;

do $$ begin create type public.product_status as enum ('active', 'draft', 'out_of_stock', 'archived'); exception when duplicate_object then null; end $$;
-- public.profile_role is established by 202608180001_profiles_admin_auth.sql.
do $$ begin create type public.payment_status as enum ('pending', 'paid', 'failed', 'refunded'); exception when duplicate_object then null; end $$;
do $$ begin create type public.order_status as enum ('pending', 'confirmed', 'preparing', 'ready', 'shipped', 'delivered', 'cancelled', 'refunded'); exception when duplicate_object then null; end $$;
do $$ begin create type public.inventory_reason as enum ('restock', 'order', 'return', 'damaged', 'manual_adjustment'); exception when duplicate_object then null; end $$;
do $$ begin create type public.review_status as enum ('pending', 'approved', 'rejected'); exception when duplicate_object then null; end $$;
do $$ begin create type public.discount_type as enum ('percentage', 'fixed'); exception when duplicate_object then null; end $$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role public.profile_role not null default 'customer',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(), name text not null, slug text not null unique,
  description text, image text, status boolean not null default true, created_at timestamptz not null default now()
);
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(), name text not null, slug text not null unique,
  description text, short_description text, price numeric(12,2) not null check (price >= 0),
  sale_price numeric(12,2) check (sale_price is null or (sale_price >= 0 and sale_price <= price)),
  sku text unique, stock_quantity integer not null default 0 check (stock_quantity >= 0),
  low_stock_threshold integer not null default 0 check (low_stock_threshold >= 0), main_image text,
  status public.product_status not null default 'draft', personalizable boolean not null default false,
  photo_upload_required boolean not null default false, max_photos integer not null default 0 check (max_photos >= 0),
  custom_text_allowed boolean not null default false, max_text_length integer not null default 0 check (max_text_length >= 0),
  customization_instructions text, dimensions text, materials text, delivery_information text, care_instructions text,
  seo_title text, seo_description text, seo_image text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.product_categories (product_id uuid not null references public.products(id) on delete cascade, category_id uuid not null references public.categories(id) on delete cascade, primary key (product_id, category_id));
create table if not exists public.product_images (id uuid primary key default gen_random_uuid(), product_id uuid not null references public.products(id) on delete cascade, storage_path text not null, public_url text, alt_text text, position integer not null default 0, created_at timestamptz not null default now(), unique(product_id, position));
create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(), user_id uuid unique references auth.users(id) on delete set null,
  name text, email text not null, phone text, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(email)
);
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(), order_number text not null unique, customer_id uuid references public.customers(id) on delete set null,
  subtotal numeric(12,2) not null default 0, discount numeric(12,2) not null default 0, shipping_fee numeric(12,2) not null default 0, total numeric(12,2) not null default 0,
  payment_status public.payment_status not null default 'pending', order_status public.order_status not null default 'pending',
  shipping_name text not null, shipping_phone text, shipping_address text not null, shipping_city text, shipping_state text, shipping_postal_code text, shipping_country text not null default 'India',
  tracking_number text, tracking_url text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(), order_id uuid not null references public.orders(id) on delete cascade, product_id uuid references public.products(id) on delete set null,
  product_name_snapshot text not null, price_snapshot numeric(12,2) not null, quantity integer not null check(quantity > 0), customization_text text, created_at timestamptz not null default now()
);
create table if not exists public.personalization_assets (
  id uuid primary key default gen_random_uuid(), order_id uuid not null references public.orders(id) on delete cascade, order_item_id uuid not null references public.order_items(id) on delete cascade,
  storage_path text not null, public_url text, original_filename text not null, created_at timestamptz not null default now()
);
create table if not exists public.order_notes (id uuid primary key default gen_random_uuid(), order_id uuid not null references public.orders(id) on delete cascade, admin_user_id uuid not null references auth.users(id), note text not null, created_at timestamptz not null default now());
create table if not exists public.inventory_movements (id uuid primary key default gen_random_uuid(), product_id uuid not null references public.products(id), previous_quantity integer not null, change_quantity integer not null, new_quantity integer not null check(new_quantity >= 0), reason public.inventory_reason not null, admin_user_id uuid references auth.users(id), created_at timestamptz not null default now());
create table if not exists public.coupons (id uuid primary key default gen_random_uuid(), code text not null unique, discount_type public.discount_type not null, discount_value numeric(12,2) not null check(discount_value >= 0), minimum_order numeric(12,2), maximum_discount numeric(12,2), usage_limit integer, per_customer_limit integer, starts_at timestamptz, expires_at timestamptz, status boolean not null default true, created_at timestamptz not null default now());
create table if not exists public.reviews (id uuid primary key default gen_random_uuid(), product_id uuid not null references public.products(id) on delete cascade, customer_id uuid references public.customers(id) on delete set null, order_id uuid references public.orders(id) on delete set null, rating integer not null check(rating between 1 and 5), review text, status public.review_status not null default 'pending', created_at timestamptz not null default now());

create index if not exists products_status_idx on public.products(status); create index if not exists orders_customer_idx on public.orders(customer_id); create index if not exists order_items_order_idx on public.order_items(order_id); create index if not exists personalization_assets_order_idx on public.personalization_assets(order_id);

create or replace function public.set_updated_at() returns trigger language plpgsql as $$ begin new.updated_at = now(); return new; end; $$;
do $$ begin if not exists (select 1 from pg_trigger where tgname = 'profiles_updated_at' and tgrelid = 'public.profiles'::regclass) then create trigger profiles_updated_at before update on public.profiles for each row execute function public.set_updated_at(); end if; end $$;
do $$ begin if not exists (select 1 from pg_trigger where tgname = 'products_updated_at' and tgrelid = 'public.products'::regclass) then create trigger products_updated_at before update on public.products for each row execute function public.set_updated_at(); end if; end $$;
do $$ begin if not exists (select 1 from pg_trigger where tgname = 'customers_updated_at' and tgrelid = 'public.customers'::regclass) then create trigger customers_updated_at before update on public.customers for each row execute function public.set_updated_at(); end if; end $$;
do $$ begin if not exists (select 1 from pg_trigger where tgname = 'orders_updated_at' and tgrelid = 'public.orders'::regclass) then create trigger orders_updated_at before update on public.orders for each row execute function public.set_updated_at(); end if; end $$;
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path = public as $$ begin insert into public.profiles(id) values(new.id) on conflict do nothing; insert into public.customers(user_id, name, email) values (new.id, nullif(trim(coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name', '')), ''), new.email) on conflict (user_id) do update set email = excluded.email; return new; end; $$;
do $$ begin if not exists (select 1 from pg_trigger where tgname = 'on_auth_user_created' and tgrelid = 'auth.users'::regclass) then create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user(); end if; end $$;
create or replace function public.is_admin() returns boolean language sql stable security definer set search_path = public as $$ select exists(select 1 from public.profiles where id = auth.uid() and role = 'admin'); $$;
create or replace function public.current_user_role() returns public.profile_role language sql stable security definer set search_path = public as $$ select role from public.profiles where id = auth.uid(); $$;

alter table public.profiles enable row level security; alter table public.categories enable row level security; alter table public.products enable row level security; alter table public.product_categories enable row level security; alter table public.product_images enable row level security; alter table public.customers enable row level security; alter table public.orders enable row level security; alter table public.order_items enable row level security; alter table public.personalization_assets enable row level security; alter table public.order_notes enable row level security; alter table public.inventory_movements enable row level security; alter table public.coupons enable row level security; alter table public.reviews enable row level security;

do $$ begin if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'profiles' and policyname = 'profiles own or admin') then create policy "profiles own or admin" on public.profiles for select using (id = auth.uid() or public.is_admin()); end if; end $$; do $$ begin if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'profiles' and policyname = 'profiles own update') then create policy "profiles own update" on public.profiles for update using (id = auth.uid()) with check (id = auth.uid() and role = public.current_user_role()); end if; end $$;
create policy "categories public active" on public.categories for select using (status or public.is_admin()); create policy "categories admin write" on public.categories for all using (public.is_admin()) with check (public.is_admin());
create policy "products public active" on public.products for select using (status = 'active' or public.is_admin()); create policy "products admin write" on public.products for all using (public.is_admin()) with check (public.is_admin());
create policy "product categories readable" on public.product_categories for select using (public.is_admin() or exists(select 1 from public.products p where p.id = product_id and p.status = 'active')); create policy "product categories admin write" on public.product_categories for all using (public.is_admin()) with check (public.is_admin());
create policy "product images readable" on public.product_images for select using (public.is_admin() or exists(select 1 from public.products p where p.id = product_id and p.status = 'active')); create policy "product images admin write" on public.product_images for all using (public.is_admin()) with check (public.is_admin());
create policy "customers own or admin" on public.customers for select using (user_id = auth.uid() or public.is_admin()); create policy "customers own insert" on public.customers for insert with check(user_id = auth.uid()); create policy "customers own update" on public.customers for update using(user_id = auth.uid() or public.is_admin()) with check(user_id = auth.uid() or public.is_admin());
create policy "orders own or admin" on public.orders for select using (public.is_admin() or customer_id in(select id from public.customers where user_id = auth.uid())); create policy "orders admin update" on public.orders for update using(public.is_admin()) with check(public.is_admin()); create policy "items own or admin" on public.order_items for select using (public.is_admin() or order_id in(select id from public.orders where customer_id in(select id from public.customers where user_id = auth.uid()))); create policy "assets own or admin" on public.personalization_assets for select using (public.is_admin() or order_id in(select id from public.orders where customer_id in(select id from public.customers where user_id = auth.uid()))); create policy "assets customer attach own order" on public.personalization_assets for insert with check (exists(select 1 from public.orders o join public.order_items oi on oi.order_id = o.id where o.id = personalization_assets.order_id and oi.id = personalization_assets.order_item_id and o.customer_id in(select id from public.customers where user_id = auth.uid())) and (storage.foldername(storage_path))[1] = auth.uid()::text); create policy "assets admin write" on public.personalization_assets for all using(public.is_admin()) with check(public.is_admin()); create policy "notes admin" on public.order_notes for all using(public.is_admin()) with check(public.is_admin()); create policy "inventory admin" on public.inventory_movements for all using(public.is_admin()) with check(public.is_admin());
create policy "coupons active readable" on public.coupons for select using(status or public.is_admin()); create policy "coupons admin write" on public.coupons for all using(public.is_admin()) with check(public.is_admin()); create policy "reviews readable" on public.reviews for select using(status = 'approved' or public.is_admin() or customer_id in(select id from public.customers where user_id = auth.uid())); create policy "reviews customer insert" on public.reviews for insert with check(customer_id in(select id from public.customers where user_id = auth.uid())); create policy "reviews admin write" on public.reviews for update using(public.is_admin()) with check(public.is_admin());

insert into storage.buckets(id, name, public) values ('product-images', 'product-images', true), ('customer-personalization', 'customer-personalization', false) on conflict(id) do nothing;
create policy "product images public read" on storage.objects for select using(bucket_id = 'product-images'); create policy "product images admin write" on storage.objects for all using(bucket_id = 'product-images' and public.is_admin()) with check(bucket_id = 'product-images' and public.is_admin());
create policy "personalization owner read" on storage.objects for select using(bucket_id = 'customer-personalization' and (public.is_admin() or (storage.foldername(name))[1] = auth.uid()::text)); create policy "personalization owner upload" on storage.objects for insert with check(bucket_id = 'customer-personalization' and (storage.foldername(name))[1] = auth.uid()::text); create policy "personalization owner delete" on storage.objects for delete using(bucket_id = 'customer-personalization' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()));

create or replace function public.create_order(p_shipping jsonb, p_items jsonb, p_discount numeric default 0, p_shipping_fee numeric default 0) returns public.orders language plpgsql security definer set search_path = public as $$
declare v_customer public.customers; v_order public.orders; v_item jsonb; v_product public.products; v_subtotal numeric := 0; v_total numeric; v_quantity int; v_price numeric; begin
  if auth.uid() is null then raise exception 'Authentication required'; end if; if coalesce(p_discount, 0) <> 0 or coalesce(p_shipping_fee, 0) <> 0 then raise exception 'Discounts and shipping must be calculated server-side'; end if;
  select * into v_customer from public.customers where user_id = auth.uid(); if not found then raise exception 'Customer profile required'; end if;
  for v_item in select * from jsonb_array_elements(p_items) loop
    v_quantity := (v_item->>'quantity')::int; if v_quantity is null or v_quantity < 1 then raise exception 'Invalid quantity'; end if;
    select * into v_product from public.products where id = (v_item->>'product_id')::uuid and status = 'active' for update; if not found then raise exception 'Product unavailable'; end if;
    if v_product.stock_quantity < v_quantity then raise exception 'Insufficient stock for %', v_product.name; end if;
    v_price := coalesce(v_product.sale_price, v_product.price); v_subtotal := v_subtotal + (v_price * v_quantity);
  end loop;
  v_total := greatest(v_subtotal - coalesce(p_discount,0),0) + coalesce(p_shipping_fee,0);
  insert into public.orders(order_number, customer_id, subtotal, discount, shipping_fee, total, shipping_name, shipping_phone, shipping_address, shipping_city, shipping_state, shipping_postal_code, shipping_country)
  values ('MK-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,10)), v_customer.id, v_subtotal, coalesce(p_discount,0), coalesce(p_shipping_fee,0), v_total, p_shipping->>'name', p_shipping->>'phone', p_shipping->>'address', p_shipping->>'city', p_shipping->>'state', p_shipping->>'postal_code', coalesce(p_shipping->>'country','India')) returning * into v_order;
  for v_item in select * from jsonb_array_elements(p_items) loop
    v_quantity := (v_item->>'quantity')::int; select * into v_product from public.products where id = (v_item->>'product_id')::uuid for update; v_price := coalesce(v_product.sale_price, v_product.price);
    insert into public.order_items(order_id, product_id, product_name_snapshot, price_snapshot, quantity, customization_text) values(v_order.id, v_product.id, v_product.name, v_price, v_quantity, nullif(v_item->>'customization_text',''));
    update public.products set stock_quantity = stock_quantity - v_quantity, status = case when stock_quantity - v_quantity = 0 then 'out_of_stock' else status end where id = v_product.id;
    insert into public.inventory_movements(product_id, previous_quantity, change_quantity, new_quantity, reason) values(v_product.id, v_product.stock_quantity, -v_quantity, v_product.stock_quantity - v_quantity, 'order');
  end loop; return v_order; end; $$;
revoke all on function public.create_order(jsonb,jsonb,numeric,numeric) from public; grant execute on function public.create_order(jsonb,jsonb,numeric,numeric) to authenticated;
