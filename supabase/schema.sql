-- Backend upgrade scaffold; local demo does not connect to this schema.
create extension if not exists pgcrypto;
create table public.profiles (id uuid primary key references auth.users(id), display_name text not null);
create table public.restaurants (id uuid primary key default gen_random_uuid(), name text not null, pickup_location text not null);
create table public.menu_categories (id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id), name text not null);
create table public.menu_items (id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id), category_id uuid references public.menu_categories(id), name text not null, price_cents integer not null check(price_cents>=0), calories integer, protein_g numeric, carbs_g numeric, fat_g numeric, nutrition_source text not null default 'estimate', available boolean not null default true);
create table public.item_customizations (id uuid primary key default gen_random_uuid(), menu_item_id uuid not null references public.menu_items(id), name text not null, price_cents integer not null check(price_cents>=0), available boolean not null default true);
create table public.wallets (user_id uuid primary key references public.profiles(id), balance_cents integer not null default 15000 check(balance_cents>=0));
create table public.orders (id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id), restaurant_id uuid not null references public.restaurants(id), status text not null default 'Order placed' check(status in ('Order placed','Preparing','Ready for pickup','Completed')), total_cents integer not null check(total_cents>0), pickup_location text not null, pickup_code text not null, created_at timestamptz not null default now());
create table public.order_items (id uuid primary key default gen_random_uuid(), order_id uuid not null references public.orders(id), menu_item_id uuid not null references public.menu_items(id), quantity integer not null check(quantity between 1 and 20), unit_price_cents integer not null, snapshot jsonb not null, instructions text);
create table public.wallet_transactions (id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id), order_id uuid unique references public.orders(id), amount_cents integer not null, created_at timestamptz not null default now());
create table public.favorites (user_id uuid references public.profiles(id), menu_item_id uuid references public.menu_items(id), primary key(user_id,menu_item_id));
do $$ declare t text; begin foreach t in array array['profiles','restaurants','menu_categories','menu_items','item_customizations','wallets','orders','order_items','wallet_transactions','favorites'] loop execute format('alter table public.%I enable row level security',t); end loop; end $$;
create policy catalog_read on public.restaurants for select to authenticated using(true);
create policy categories_read on public.menu_categories for select to authenticated using(true);
create policy menu_read on public.menu_items for select to authenticated using(true);
create policy options_read on public.item_customizations for select to authenticated using(true);
create policy profile_read on public.profiles for select to authenticated using(id=auth.uid());
create policy wallet_read on public.wallets for select to authenticated using(user_id=auth.uid());
create policy orders_read on public.orders for select to authenticated using(user_id=auth.uid());
create policy lines_read on public.order_items for select to authenticated using(exists(select 1 from public.orders o where o.id=order_id and o.user_id=auth.uid()));
create policy transactions_read on public.wallet_transactions for select to authenticated using(user_id=auth.uid());
create policy favorites_own on public.favorites for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
-- No client-side direct order or wallet writes. Staff policies must be implemented separately.
-- input: [{"menu_item_id":"uuid", "quantity":1, "option_ids":["uuid"], "instructions":"..."}]
create or replace function public.place_order(p_restaurant uuid,p_items jsonb) returns uuid
language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); balance integer; amount integer:=0; line jsonb; item public.menu_items%rowtype; opt_total integer; opt_count integer; qty integer; oid uuid:=gen_random_uuid(); location text;
begin
 if uid is null then raise exception 'Authentication required'; end if;
 if jsonb_typeof(p_items)<>'array' or jsonb_array_length(p_items) not between 1 and 50 then raise exception 'Invalid cart'; end if;
 select balance_cents into balance from public.wallets where user_id=uid for update;
 if not found then raise exception 'Wallet missing'; end if;
 select pickup_location into location from public.restaurants where id=p_restaurant;
 if not found then raise exception 'Restaurant missing'; end if;
 -- Compute and validate all prices on the server; never trust client totals.
 for line in select * from jsonb_array_elements(p_items) loop
  select * into item from public.menu_items where id=(line->>'menu_item_id')::uuid and restaurant_id=p_restaurant and available for share;
  if not found then raise exception 'Unavailable item'; end if;
  qty:=(line->>'quantity')::integer;
  if qty is null or qty not between 1 and 20 then raise exception 'Invalid quantity'; end if;
  select coalesce(sum(price_cents),0),count(*) into opt_total,opt_count from public.item_customizations where menu_item_id=item.id and available and id in (select value::uuid from jsonb_array_elements_text(coalesce(line->'option_ids','[]'::jsonb)));
  if opt_count<>jsonb_array_length(coalesce(line->'option_ids','[]'::jsonb)) then raise exception 'Invalid or duplicate option'; end if;
  amount:=amount+(item.price_cents+opt_total)*qty;
 end loop;
 if amount<=0 or balance<amount then raise exception 'Insufficient funds or invalid amount'; end if;
 insert into public.orders(id,user_id,restaurant_id,total_cents,pickup_location,pickup_code) values(oid,uid,p_restaurant,amount,location,lpad(floor(random()*10000)::text,4,'0'));
 for line in select * from jsonb_array_elements(p_items) loop
  select * into item from public.menu_items where id=(line->>'menu_item_id')::uuid;
  select coalesce(sum(price_cents),0) into opt_total from public.item_customizations where menu_item_id=item.id and id in(select value::uuid from jsonb_array_elements_text(coalesce(line->'option_ids','[]'::jsonb)));
  insert into public.order_items(order_id,menu_item_id,quantity,unit_price_cents,snapshot,instructions) values(oid,item.id,(line->>'quantity')::integer,item.price_cents+opt_total,jsonb_build_object('item',to_jsonb(item),'options',(select coalesce(jsonb_agg(to_jsonb(c)),'[]'::jsonb) from public.item_customizations c where c.id in(select value::uuid from jsonb_array_elements_text(coalesce(line->'option_ids','[]'::jsonb))))),left(line->>'instructions',250));
 end loop;
 update public.wallets set balance_cents=balance_cents-amount where user_id=uid;
 insert into public.wallet_transactions(user_id,order_id,amount_cents) values(uid,oid,-amount);
 return oid;
end $$;
revoke all on function public.place_order(uuid,jsonb) from public;
grant execute on function public.place_order(uuid,jsonb) to authenticated;
