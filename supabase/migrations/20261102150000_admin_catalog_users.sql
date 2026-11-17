-- A-02 and A-04. Staff manage sports without a code change, and review users
-- and recovery requests.

alter table public.player_sports drop constraint player_sports_sport_check;
alter table public.player_sports add constraint player_sports_sport_fk
  foreign key (sport) references public.sports (key) on update cascade;
alter table public.teams drop constraint teams_sport_check;
alter table public.teams add constraint teams_sport_fk
  foreign key (sport) references public.sports (key) on update cascade;

create table public.game_types (
  key text primary key check (key ~ '^[a-z_]{2,30}$'),
  name text not null,
  ranked boolean not null default false,
  status text not null default 'draft' check (status in ('draft', 'live', 'maintenance')),
  updated_at timestamptz not null default now()
);

create table public.level_scales (
  band text primary key,
  name text not null,
  from_level numeric(3, 1) not null,
  updated_at timestamptz not null default now()
);

insert into public.game_types (key, name, ranked, status) values
  ('casual', 'Casual', false, 'live'),
  ('ranked', 'Ranked', true, 'live'),
  ('tournament', 'Tournament', true, 'live');

-- R-RAT-3.
insert into public.level_scales (band, name, from_level) values
  ('LB', 'Low Beginner', 1.0), ('MB', 'Mid Beginner', 2.0), ('HB', 'High Beginner', 3.0),
  ('LI', 'Low Intermediate', 4.0), ('MI', 'Mid Intermediate', 5.0), ('HI', 'High Intermediate', 6.0),
  ('AD', 'Advanced', 7.0), ('PRO', 'Professional', 8.0);

alter table public.game_types enable row level security;
alter table public.level_scales enable row level security;
create policy "Live game types are visible" on public.game_types
  for select to anon, authenticated using (status <> 'draft');
create policy "Level scales are visible" on public.level_scales
  for select to anon, authenticated using (true);
create trigger game_types_audit after insert or update or delete on public.game_types
  for each row execute function private.audit_catalog();
create trigger level_scales_audit after insert or update or delete on public.level_scales
  for each row execute function private.audit_catalog();
create trigger game_types_touch before update on public.game_types
  for each row execute function public.touch_updated_at();
create trigger level_scales_touch before update on public.level_scales
  for each row execute function public.touch_updated_at();

insert into private.restricted_allow (path) values ('/game_types'), ('/level_scales');

-- Draft rows included, for the admin app.
create function public.staff_catalog() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: drafts are hidden from clients by policy.
begin
  perform private.staff_require('content');
  return jsonb_build_object(
    'sports', (select coalesce(jsonb_agg(jsonb_build_object('key', s.key, 'name', s.name,
        'status', s.status, 'position', s.position,
        'formats', (select coalesce(jsonb_agg(to_jsonb(f) order by f.position), '[]'::jsonb)
          from public.sport_formats f where f.sport_key = s.key)) order by s.position), '[]'::jsonb)
      from public.sports s),
    'game_types', (select coalesce(jsonb_agg(to_jsonb(g) order by g.key), '[]'::jsonb) from public.game_types g),
    'level_scales', (select coalesce(jsonb_agg(to_jsonb(l) order by l.from_level), '[]'::jsonb) from public.level_scales l));
end;
$$;

create function public.staff_sport_save(p_key text, p_name text, p_status text, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: sports has no client write path.
begin
  perform private.staff_require('content');
  if p_status = 'live' and not exists (select 1 from public.sport_formats f
      where f.sport_key = p_key and f.status = 'live') then
    raise exception 'Add a live format before making this sport live.';
  end if;
  insert into public.sports as s (key, name, status, position)
  values (p_key, p_name, p_status, (select coalesce(max(position), 0) + 1 from public.sports))
  on conflict (key) do update set name = excluded.name, status = excluded.status;
  perform private.staff_audit('sport_save', 'sport', p_key, p_reason, jsonb_build_object('status', p_status));
end;
$$;

-- Changes apply to new Meets only: each Meet keeps its own copy of the rules.
create function public.staff_format_save(
  p_sport text, p_key text, p_name text, p_status text, p_min_players int, p_scoring jsonb, p_reason text
) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: sport_formats has no client write path.
begin
  perform private.staff_require('content');
  insert into public.sport_formats as f (sport_key, key, name, status, min_players, scoring)
  values (p_sport, p_key, p_name, p_status, p_min_players, coalesce(p_scoring, '{}'::jsonb))
  on conflict (sport_key, key) do update
    set name = excluded.name, status = excluded.status,
        min_players = excluded.min_players, scoring = excluded.scoring;
  perform private.staff_audit('format_save', 'format', p_sport || ':' || p_key, p_reason,
    jsonb_build_object('status', p_status));
end;
$$;

-- ─── Users (A-04) ──────────────────────────────────────────────────────────

create function public.staff_user_search(p_query text) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: searches private contact details. Moderators see no payment data.
declare
  v text := trim(coalesce(p_query, ''));
begin
  perform private.staff_require('moderator');
  if char_length(v) < 3 then raise exception 'Enter at least 3 characters.'; end if;
  return (select coalesce(jsonb_agg(jsonb_build_object('id', p.id, 'username', p.username,
      'name', p.full_name, 'audience', private.audience_of(p.id))), '[]'::jsonb)
    from (select pr.* from public.profiles pr
      join public.account_private ap on ap.id = pr.id
      where pr.username::text ilike v || '%' or pr.full_name ilike '%' || v || '%'
        or ap.mobile like '%' || v or ap.email = lower(v)
      limit 25) p);
end;
$$;

create function public.staff_user_get(p_user uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: reads across private tables for one person. The age group is
-- shown, not the birthday.
begin
  perform private.staff_require('moderator');
  return (select jsonb_build_object('id', p.id, 'username', p.username, 'name', p.full_name,
      'audience', private.audience_of(p.id), 'restricted', private.is_restricted(p.id),
      'hidden', p.hidden_at is not null,
      'moderation', (select to_jsonb(m) from public.account_moderation m where m.user_id = p.id),
      'links', (select coalesce(jsonb_agg(jsonb_build_object('status', l.status,
          'role', case when l.child_id = p.id then 'child' else 'parent' end,
          'other', (select full_name from public.profiles o
            where o.id = case when l.child_id = p.id then l.parent_id else l.child_id end))), '[]'::jsonb)
        from public.guardian_links l where p.id in (l.child_id, l.parent_id)))
    from public.profiles p where p.id = p_user);
end;
$$;

create function public.staff_recovery_list() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: account_recovery_requests has no client policies.
begin
  perform private.staff_require('moderator');
  return (select coalesce(jsonb_agg(to_jsonb(r) order by r.created_at), '[]'::jsonb)
    from public.account_recovery_requests r where r.status = 'open');
end;
$$;

create function public.staff_recovery_decide(p_id bigint, p_approve boolean, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: account_recovery_requests has no client policies.
begin
  perform private.staff_require('moderator');
  update public.account_recovery_requests
  set status = case when p_approve then 'approved' else 'refused' end,
      reviewed_by = auth.uid(), reviewed_at = now()
  where id = p_id and status = 'open';
  if not found then raise exception 'This request is closed.'; end if;
  perform private.staff_audit(case when p_approve then 'recovery_approved' else 'recovery_refused' end,
    'recovery', p_id::text, p_reason);
end;
$$;

revoke execute on function public.staff_catalog() from public, anon;
revoke execute on function public.staff_sport_save(text, text, text, text) from public, anon;
revoke execute on function public.staff_format_save(text, text, text, text, int, jsonb, text) from public, anon;
revoke execute on function public.staff_user_search(text) from public, anon;
revoke execute on function public.staff_user_get(uuid) from public, anon;
revoke execute on function public.staff_recovery_list() from public, anon;
revoke execute on function public.staff_recovery_decide(bigint, boolean, text) from public, anon;
grant execute on function public.staff_catalog() to authenticated;
grant execute on function public.staff_sport_save(text, text, text, text) to authenticated;
grant execute on function public.staff_format_save(text, text, text, text, int, jsonb, text) to authenticated;
grant execute on function public.staff_user_search(text) to authenticated;
grant execute on function public.staff_user_get(uuid) to authenticated;
grant execute on function public.staff_recovery_list() to authenticated;
grant execute on function public.staff_recovery_decide(bigint, boolean, text) to authenticated;
