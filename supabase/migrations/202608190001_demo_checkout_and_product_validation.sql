-- Keep the existing constraints and add the stricter catalogue rule used by the admin form.
alter table public.products
  add constraint products_price_must_be_positive check (price > 0) not valid;
alter table public.products validate constraint products_price_must_be_positive;

-- Demo checkout intentionally accepts a guest. It creates or updates the customer
-- record inside the transaction, while product, stock, and price checks remain server-side.
create or replace function public.create_order(
  p_shipping jsonb,
  p_items jsonb,
  p_discount numeric default 0,
  p_shipping_fee numeric default 0
) returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  v_customer public.customers;
  v_order public.orders;
  v_item jsonb;
  v_product public.products;
  v_subtotal numeric := 0;
  v_total numeric;
  v_quantity integer;
  v_price numeric;
  v_user_id uuid := auth.uid();
  v_email text;
begin
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'A demo order needs at least one item';
  end if;
  if coalesce(p_discount, 0) <> 0 or coalesce(p_shipping_fee, 0) <> 0 then
    raise exception 'Discounts and shipping must be calculated server-side';
  end if;
  if coalesce(trim(p_shipping->>'name'), '') = ''
    or coalesce(trim(p_shipping->>'phone'), '') = ''
    or coalesce(trim(p_shipping->>'address'), '') = ''
    or coalesce(trim(p_shipping->>'city'), '') = ''
    or coalesce(trim(p_shipping->>'state'), '') = ''
    or coalesce(trim(p_shipping->>'postal_code'), '') !~ '^[0-9]{6}$' then
    raise exception 'Complete delivery details are required';
  end if;

  if v_user_id is not null then
    select * into v_customer from public.customers where user_id = v_user_id for update;
    if found then
      update public.customers
      set name = trim(p_shipping->>'name'), phone = trim(p_shipping->>'phone')
      where id = v_customer.id
      returning * into v_customer;
    else
      select coalesce(email, 'demo-' || v_user_id::text || '@memory-kraft.invalid')
      into v_email from auth.users where id = v_user_id;
      insert into public.customers(user_id, name, email, phone)
      values (v_user_id, trim(p_shipping->>'name'), v_email, trim(p_shipping->>'phone'))
      returning * into v_customer;
    end if;
  else
    insert into public.customers(name, email, phone)
    values (trim(p_shipping->>'name'), 'demo-' || gen_random_uuid()::text || '@memory-kraft.invalid', trim(p_shipping->>'phone'))
    returning * into v_customer;
  end if;

  for v_item in select * from jsonb_array_elements(p_items) loop
    v_quantity := nullif(v_item->>'quantity', '')::integer;
    if v_quantity is null or v_quantity < 1 then raise exception 'Invalid quantity'; end if;
    select * into v_product from public.products
    where id = (v_item->>'product_id')::uuid and status = 'active' for update;
    if not found then raise exception 'Product unavailable'; end if;
    if v_product.stock_quantity < v_quantity then raise exception 'Insufficient stock'; end if;
    v_price := coalesce(v_product.sale_price, v_product.price);
    v_subtotal := v_subtotal + (v_price * v_quantity);
  end loop;

  v_total := v_subtotal;
  insert into public.orders(order_number, customer_id, subtotal, discount, shipping_fee, total, shipping_name, shipping_phone, shipping_address, shipping_city, shipping_state, shipping_postal_code, shipping_country)
  values ('MK-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10)), v_customer.id, v_subtotal, 0, 0, v_total, trim(p_shipping->>'name'), trim(p_shipping->>'phone'), trim(p_shipping->>'address'), trim(p_shipping->>'city'), trim(p_shipping->>'state'), trim(p_shipping->>'postal_code'), coalesce(nullif(trim(p_shipping->>'country'), ''), 'India'))
  returning * into v_order;

  for v_item in select * from jsonb_array_elements(p_items) loop
    v_quantity := (v_item->>'quantity')::integer;
    select * into v_product from public.products where id = (v_item->>'product_id')::uuid for update;
    v_price := coalesce(v_product.sale_price, v_product.price);
    insert into public.order_items(order_id, product_id, product_name_snapshot, price_snapshot, quantity, customization_text)
    values (v_order.id, v_product.id, v_product.name, v_price, v_quantity, nullif(v_item->>'customization_text', ''));
    update public.products
    set stock_quantity = stock_quantity - v_quantity,
        status = case when stock_quantity - v_quantity = 0 then 'out_of_stock' else status end
    where id = v_product.id;
    insert into public.inventory_movements(product_id, previous_quantity, change_quantity, new_quantity, reason)
    values (v_product.id, v_product.stock_quantity, -v_quantity, v_product.stock_quantity - v_quantity, 'order');
  end loop;
  return v_order;
end;
$$;

revoke all on function public.create_order(jsonb, jsonb, numeric, numeric) from public;
grant execute on function public.create_order(jsonb, jsonb, numeric, numeric) to anon, authenticated;
