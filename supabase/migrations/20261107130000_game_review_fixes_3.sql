-- P4d: the last review. Waiting rewards can't crowd out ones that can be paid,
-- a voucher edit changes only what it's asked to, and a player marked absent
-- keeps no scan.

do $$
declare
  d text := pg_get_functiondef('private.organizer_sweep()'::regprocedure);
  fixed text;
begin
  fixed := replace(d, $old$      where g.status = 'pending' and not private.is_suspended(g.user_id)$old$,
    $new$      where g.status = 'pending' and not private.is_suspended(g.user_id)
        and exists (select 1 from public.voucher_types t
          where t.kind = g.kind and t.organizer_default and t.active)$new$);
  if fixed = d then raise exception 'organizer_sweep did not change'; end if;
  execute fixed;

  d := pg_get_functiondef('public.save_attendance(uuid, jsonb)'::regprocedure);
  fixed := replace(d, $old$then case when ap.check_in_method in ('qr', 'parent') then ap.check_in_method else 'host' end
        else ap.check_in_method end$old$,
    $new$then case when ap.check_in_method in ('qr', 'parent') then ap.check_in_method else 'host' end
        end$new$);
  if fixed = d then raise exception 'save_attendance did not change'; end if;
  execute fixed;
end;
$$;

create or replace function public.staff_voucher_type_save(p jsonb, p_reason text) returns uuid
language plpgsql security definer set search_path = '' as $$
-- Definer: voucher types have no client write path.
declare
  v_id uuid := nullif(p ->> 'id', '')::uuid;
  v_default boolean := (p ->> 'organizer_default')::boolean;
  v_kind text := p ->> 'kind';
  v_mall uuid := nullif(p ->> 'mall_id', '')::uuid;
  v_product uuid := nullif(p ->> 'product_id', '')::uuid;
  v_active boolean := (p ->> 'active')::boolean;
  was public.voucher_types;
begin
  perform private.staff_require('payments');
  if coalesce(trim(p_reason), '') = '' then raise exception 'Give a reason.'; end if;
  if v_id is not null then
    select * into was from public.voucher_types where id = v_id for update;
    if was.id is null then raise exception 'Not found.' using errcode = 'P0001'; end if;
    v_kind := was.kind;
    if v_default and not coalesce(v_active, was.active) then
      raise exception 'Switch this voucher on first.';
    end if;
  elsif v_product is not null and not exists (select 1 from public.products x
      where x.id = v_product and x.mall_id = v_mall) then
    raise exception 'That product isn''t from this shop.';
  end if;
  -- One default of each kind at a time.
  if v_default then
    update public.voucher_types set organizer_default = false
    where kind = v_kind and organizer_default and id is distinct from v_id;
  end if;
  if v_id is null then
    insert into public.voucher_types (name, kind, mall_id, venue_id, amount_minor, product_id, expiry_days, organizer_default)
    values (trim(p ->> 'name'), v_kind, v_mall, nullif(p ->> 'venue_id', '')::uuid,
      (p ->> 'amount_minor')::bigint, v_product, nullif(p ->> 'expiry_days', '')::int, coalesce(v_default, false))
    returning id into v_id;
  else
    -- What's already issued keeps the terms it was issued on: only new ones
    -- change. Anything the edit leaves out stays as it is.
    update public.voucher_types set name = coalesce(nullif(trim(p ->> 'name'), ''), name),
      organizer_default = coalesce(v_default, organizer_default), active = coalesce(v_active, active)
    where id = v_id;
  end if;
  perform private.staff_audit('voucher_type_saved', 'voucher_type', v_id::text, p_reason, p);
  return v_id;
end;
$$;
