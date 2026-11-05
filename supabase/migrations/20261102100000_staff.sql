-- A-01: staff accounts for the admin app. Every staff check needs a session
-- that passed MFA, so a staff account without it gets no data. Roles are
-- enforced here, not in the admin screens.

create table public.staff (
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null check (role in ('super', 'moderator', 'content', 'payments')),
  active boolean not null default true,
  added_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  primary key (user_id, role)
);

-- Every staff action, for good, with a reason.
create table public.admin_audit (
  id bigint generated always as identity primary key,
  actor uuid not null,
  action text not null,
  target_kind text not null,
  target_id text not null,
  reason text not null check (char_length(trim(reason)) >= 3),
  detail jsonb not null default '{}'::jsonb,
  at timestamptz not null default now()
);
create index admin_audit_target_idx on public.admin_audit (target_kind, target_id);

create trigger admin_audit_append_only before update or delete on public.admin_audit
  for each row execute function private.forbid_change();
create trigger admin_audit_no_truncate before truncate on public.admin_audit
  for each statement execute function private.forbid_change();

alter table public.staff enable row level security;
alter table public.admin_audit enable row level security;
revoke all on public.staff from anon, authenticated;
revoke all on public.admin_audit from anon, authenticated;
-- No policies: staff read through the functions below.

create function private.has_mfa() returns boolean
language sql stable set search_path = '' as $$
  select coalesce(auth.jwt() ->> 'aal', '') = 'aal2';
$$;

-- With no role: any staff member. A super passes every role check.
create function private.is_staff(p_role text default null) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: public.staff has no client access.
  select private.has_mfa() and exists (
    select 1 from public.staff s
    where s.user_id = auth.uid() and s.active
      and (p_role is null or s.role = p_role or s.role = 'super'));
$$;

create function private.staff_require(p_role text default null) returns void
language plpgsql stable set search_path = '' as $$
begin
  if not private.is_staff(p_role) then
    raise exception 'Not found.' using errcode = 'P0001';
  end if;
end;
$$;

create function private.staff_audit(
  p_action text, p_kind text, p_id text, p_reason text, p_detail jsonb default '{}'::jsonb
) returns void
language sql security definer set search_path = '' as $$
  -- Definer: admin_audit has no client access.
  insert into public.admin_audit (actor, action, target_kind, target_id, reason, detail)
  values (auth.uid(), p_action, p_kind, p_id, p_reason, p_detail);
$$;

revoke execute on function private.has_mfa() from public;
revoke execute on function private.is_staff(text) from public;
revoke execute on function private.staff_require(text) from public;
revoke execute on function private.staff_audit(text, text, text, text, jsonb) from public;
grant execute on function private.has_mfa() to anon, authenticated, service_role;
grant execute on function private.is_staff(text) to anon, authenticated, service_role;
grant execute on function private.staff_require(text) to authenticated, service_role;
grant execute on function private.staff_audit(text, text, text, text, jsonb) to authenticated, service_role;

-- What the admin app needs before MFA, so it can send staff to set it up.
create function public.staff_whoami() returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: public.staff has no client access. Only ever the caller's rows.
  select jsonb_build_object(
    'roles', coalesce(jsonb_agg(s.role), '[]'::jsonb),
    'mfa', private.has_mfa())
  from public.staff s where s.user_id = auth.uid() and s.active;
$$;
revoke execute on function public.staff_whoami() from public, anon;
grant execute on function public.staff_whoami() to authenticated;

insert into private.restricted_allow (path) values ('/rpc/staff_whoami');

create function public.staff_audit_list(p_limit int default 100) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: admin_audit has no client access. Super only.
begin
  perform private.staff_require('super');
  return (select coalesce(jsonb_agg(to_jsonb(a) order by a.at desc), '[]'::jsonb)
    from (select * from public.admin_audit order by at desc limit least(p_limit, 500)) a);
end;
$$;
revoke execute on function public.staff_audit_list(int) from public, anon;
grant execute on function public.staff_audit_list(int) to authenticated;

-- Staff have no birthday, so they count as restricted. With MFA they pass.
create or replace function private.gate_request() returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: runs as whichever role is calling and reads private tables.
declare
  v_path text := current_setting('request.path', true);
  v_method text := current_setting('request.method', true);
  v_user uuid := auth.uid();
  v_rule private.rate_rules;
begin
  -- Not an API call, for example a direct database session.
  if v_path is null or v_path = '' then
    return;
  end if;

  if v_user is not null and private.is_restricted(v_user)
    and not private.is_staff()
    and not exists (select 1 from private.restricted_allow a where a.path = v_path) then
    raise exception 'Ask a parent to link your account first.' using errcode = 'P0001';
  end if;

  if v_method = 'POST' then
    select * into v_rule from private.rate_rules r where r.path = v_path;
    if v_rule.path is not null and not private.rate_hit(
        v_path, coalesce(v_user::text, private.request_ip()),
        v_rule.max_hits, v_rule.window_seconds) then
      raise exception 'Too many tries. Wait a while, then try again.' using errcode = 'P0001';
    end if;
  end if;
end;
$$;
