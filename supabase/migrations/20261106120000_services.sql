-- P4c-03: partner physios and a referral to their own booking page. We keep
-- that a referral was made and the partner's reference code, and nothing about
-- why. The partner gets no user identity from us.

create table public.service_partners (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(trim(name)) between 2 and 80),
  kind text not null default 'physio' check (kind in ('physio')),
  area text not null default '' check (char_length(area) <= 80),
  blurb text not null default '' check (char_length(blurb) <= 300),
  booking_url text not null check (booking_url ~ '^https://[^\s#]+$' and char_length(booking_url) <= 500),
  ref_code text not null check (ref_code ~ '^[A-Za-z0-9_-]{3,32}$'),
  active boolean not null default false,
  created_at timestamptz not null default now()
);

-- These four columns are the whole record. There is nowhere to put a condition.
create table public.service_referrals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  partner_id uuid not null references public.service_partners (id),
  ref_code text not null,
  created_at timestamptz not null default now()
);
create index service_referrals_partner_idx on public.service_referrals (partner_id);
create index service_referrals_user_idx on public.service_referrals (user_id);

alter table public.service_partners enable row level security;
alter table public.service_referrals enable row level security;
revoke all on public.service_partners, public.service_referrals from anon;
revoke insert, update, delete, truncate on public.service_partners, public.service_referrals from authenticated;

create function public.service_partner_list() returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: only live partners, without their reference code.
  select coalesce(jsonb_agg(jsonb_build_object('id', p.id, 'name', p.name, 'kind', p.kind,
      'area', p.area, 'blurb', p.blurb) order by p.name), '[]')
  from public.service_partners p where p.active;
$$;

create function public.service_referral_make(p_partner uuid) returns text
language plpgsql security definer set search_path = '' as $$
-- Definer: referrals have no client write path.
declare
  me uuid := auth.uid();
  p public.service_partners;
begin
  if private.is_minor(me) then raise exception 'Ask a parent to book this for you.'; end if;
  select * into p from public.service_partners where id = p_partner and active;
  if p.id is null then raise exception 'This partner is no longer listed.'; end if;
  insert into public.service_referrals (user_id, partner_id, ref_code) values (me, p.id, p.ref_code);
  return p.booking_url || case when position('?' in p.booking_url) > 0 then '&' else '?' end || 'ref=' || p.ref_code;
end;
$$;

create function public.staff_service_list() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: staff see counts per partner, never who.
begin
  perform private.staff_require('content');
  return (select coalesce(jsonb_agg(jsonb_build_object('id', p.id, 'name', p.name, 'kind', p.kind, 'area', p.area,
      'blurb', p.blurb, 'booking_url', p.booking_url, 'ref_code', p.ref_code, 'active', p.active,
      'referrals', (select count(*) from public.service_referrals r where r.partner_id = p.id))
      order by p.active desc, p.name), '[]')
    from public.service_partners p);
end;
$$;

create function public.staff_service_save(p jsonb, p_reason text) returns uuid
language plpgsql security definer set search_path = '' as $$
-- Definer: partners have no client write path.
declare
  v_id uuid := nullif(p ->> 'id', '')::uuid;
begin
  perform private.staff_require('content');
  if coalesce(trim(p_reason), '') = '' then raise exception 'Give a reason.'; end if;
  if coalesce(p ->> 'booking_url', '') !~ '^https://[^\s#]+$' then
    raise exception 'The booking link must start with https://';
  end if;
  if coalesce(p ->> 'ref_code', '') !~ '^[A-Za-z0-9_-]{3,32}$' then
    raise exception 'The reference code is 3 to 32 letters, numbers, - or _.';
  end if;
  if v_id is null then
    insert into public.service_partners (name, area, blurb, booking_url, ref_code, active)
    values (trim(p ->> 'name'), coalesce(p ->> 'area', ''), coalesce(p ->> 'blurb', ''), p ->> 'booking_url',
      p ->> 'ref_code', coalesce((p ->> 'active')::boolean, false))
    returning id into v_id;
  else
    update public.service_partners set name = trim(p ->> 'name'), area = coalesce(p ->> 'area', area),
      blurb = coalesce(p ->> 'blurb', blurb), booking_url = p ->> 'booking_url', ref_code = p ->> 'ref_code',
      active = coalesce((p ->> 'active')::boolean, active)
    where id = v_id;
    if not found then raise exception 'Not found.' using errcode = 'P0001'; end if;
  end if;
  perform private.staff_audit('service_partner_saved', 'service_partner', v_id::text, p_reason, p);
  return v_id;
end;
$$;

do $$
declare
  f text;
begin
  foreach f in array array['service_partner_list()', 'service_referral_make(uuid)',
    'staff_service_list()', 'staff_service_save(jsonb, text)']
  loop
    execute format('revoke execute on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end;
$$;
