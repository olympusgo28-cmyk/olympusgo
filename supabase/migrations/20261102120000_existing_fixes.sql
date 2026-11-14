-- Problems found in existing code while planning Phase 2.

-- ─── Blocked players could keep sending in an existing conversation ────────

create function private.conversation_blocked(p_conversation uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: reads the other member, whose row the caller may not see.
  select exists (select 1 from public.conversation_members m
    where m.conversation_id = p_conversation and m.user_id <> auth.uid()
      and public.is_blocked_between(auth.uid(), m.user_id));
$$;
revoke execute on function private.conversation_blocked(uuid) from public;
grant execute on function private.conversation_blocked(uuid) to authenticated;

create policy "Blocked players cannot send" on public.messages
  as restrictive for insert to authenticated
  with check (not private.conversation_blocked(conversation_id));

-- ─── A parent approves each group a child joins (P2-03, P2-05) ─────────────

create table public.guardian_group_approvals (
  child_id uuid not null references auth.users (id) on delete cascade,
  club_id uuid not null references public.clubs (id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'approved', 'denied')),
  decided_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  decided_at timestamptz,
  primary key (child_id, club_id)
);
alter table public.guardian_group_approvals enable row level security;
revoke all on public.guardian_group_approvals from anon, authenticated;

create function private.group_allowed(p_user uuid, p_club uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: called from policies for any caller.
  select not private.is_minor(p_user)
    or exists (select 1 from public.guardian_group_approvals a
      where a.child_id = p_user and a.club_id = p_club and a.status = 'approved')
    or exists (select 1 from public.clubs c where c.id = p_club and c.owner_id = p_user);
$$;
revoke execute on function private.group_allowed(uuid, uuid) from public;
grant execute on function private.group_allowed(uuid, uuid) to authenticated, service_role;

-- Every way into a club passes through this table, so this is the one check.
create function private.club_member_guard() returns trigger
language plpgsql set search_path = '' as $$
begin
  if not private.group_allowed(new.user_id, new.club_id) then
    raise exception 'A parent needs to approve this group first.' using errcode = 'P0001';
  end if;
  return new;
end;
$$;
create trigger club_members_guard before insert on public.club_members
  for each row execute function private.club_member_guard();

create policy "Children chat only in approved groups" on public.group_messages
  as restrictive for all to authenticated
  using (club_id is null or private.group_allowed((select auth.uid()), club_id))
  with check (club_id is null or private.group_allowed((select auth.uid()), club_id));

-- A child cannot see a group until a parent has approved it, so they ask from
-- an invite link rather than by browsing.
do $$
declare
  d text := pg_get_functiondef('public.club_join(uuid, text)'::regprocedure);
  fixed text;
begin
  fixed := replace(d, $old$  if not found or not public.club_visible(p_club) then
    raise exception 'This club no longer exists.';
  end if;$old$, $new$  if not found or (not public.club_visible(p_club) and not private.is_minor(v_me)) then
    raise exception 'This club no longer exists.';
  end if;
  if not private.group_allowed(v_me, p_club) then
    insert into public.guardian_group_approvals (child_id, club_id) values (v_me, p_club)
    on conflict (child_id, club_id) do update set status = 'pending'
      where public.guardian_group_approvals.status = 'denied';
    perform public.notify(l.parent_id, 'A group is waiting for you',
      'Your child asked to join a group.', '!', '/parent-link/children/' || v_me)
    from public.guardian_links l where l.child_id = v_me and l.status = 'approved';
    return 'requested';
  end if;$new$);
  if fixed = d then raise exception 'club_join did not change'; end if;
  execute fixed;

  d := pg_get_functiondef('public.club_list(text)'::regprocedure);
  fixed := replace(d, $old$c.visibility = 'public' and c.hidden_at is null$old$,
    $new$c.visibility = 'public' and c.hidden_at is null and private.group_allowed(auth.uid(), c.id)$new$);
  if fixed = d then raise exception 'club_list did not change'; end if;
  execute fixed;
end;
$$;

create or replace function public.club_visible(p_club uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: clubs has no client policies.
  select exists (
    select 1 from public.clubs c
    where c.id = p_club
      and private.group_allowed(auth.uid(), c.id)
      and (c.hidden_at is null or public.club_is_member(c.id))
      and (
      c.visibility <> 'hidden'
      or public.club_is_member(c.id)
      or exists (
        select 1 from public.club_invites i
        where i.club_id = c.id and i.user_id = (select auth.uid())
      )
    )
  );
$$;

create function public.guardian_group_requests(p_child uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: reads a child's requests and the club's name for their parent.
begin
  if not private.is_guardian_of(auth.uid(), p_child) then
    raise exception 'Only a linked parent can see this.';
  end if;
  return (select coalesce(jsonb_agg(jsonb_build_object('club_id', c.id, 'name', c.name, 'area', c.area)
      order by a.created_at), '[]'::jsonb)
    from public.guardian_group_approvals a join public.clubs c on c.id = a.club_id
    where a.child_id = p_child and a.status = 'pending');
end;
$$;

create function public.guardian_group_decide(p_child uuid, p_club uuid, p_approve boolean) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes the approval and tells the child.
begin
  if not private.is_guardian_of(auth.uid(), p_child) then
    raise exception 'Only a linked parent can do this.';
  end if;
  update public.guardian_group_approvals
  set status = case when p_approve then 'approved' else 'denied' end,
      decided_by = auth.uid(), decided_at = now()
  where child_id = p_child and club_id = p_club and status = 'pending';
  if not found then raise exception 'This request is no longer waiting for you.'; end if;
  perform public.notify(p_child,
    case when p_approve then 'Your parent approved a group' else 'Your parent said no to a group' end,
    case when p_approve then 'Open the group to join it.' else 'Ask them if you have questions.' end,
    '!', case when p_approve then '/clubs/' || p_club end);
end;
$$;

revoke execute on function public.guardian_group_requests(uuid) from public, anon;
revoke execute on function public.guardian_group_decide(uuid, uuid, boolean) from public, anon;
grant execute on function public.guardian_group_requests(uuid) to authenticated;
grant execute on function public.guardian_group_decide(uuid, uuid, boolean) to authenticated;

-- ─── Meets stay inside their club unless made public (R-MET-2) ─────────────

create function private.on_activity(p_activity uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: called from a policy on activities, for the caller's own row.
  select exists (select 1 from public.activity_participants ap
    where ap.activity_id = p_activity and ap.user_id = auth.uid());
$$;
revoke execute on function private.on_activity(uuid) from public;
grant execute on function private.on_activity(uuid) to authenticated;

create policy "Club Meets stay with the club unless public" on public.activities
  as restrictive for select to authenticated
  using (kind <> 'meet' or club_id is null or public_listing
    or host_id = (select auth.uid())
    or public.club_is_member(club_id)
    or private.on_activity(id));

-- ─── Every remaining function that returned a person's name ────────────────

do $$
declare
  r record;
  d text;
  fixed text;
begin
  for r in
    select p.oid::regprocedure as sig from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname in ('academy_user_name', 'club_announcement_list',
      'club_audit_list', 'club_ban_list', 'event_scan', 'team_fixture_get', 'shop_order_json',
      'tournament_partner_answer', 'tournament_register', 'tournament_withdraw',
      'club_decide_request', 'club_invite')
  loop
    d := pg_get_functiondef(r.sig);
    fixed := replace(replace(d,
      'coalesce(p.full_name, p.username', 'coalesce(private.public_name(p.id), p.username'),
      'coalesce(full_name, username::text', 'coalesce(private.public_name(id), username::text');
    if fixed = d then raise exception '% did not change', r.sig; end if;
    execute fixed;
  end loop;
end;
$$;
