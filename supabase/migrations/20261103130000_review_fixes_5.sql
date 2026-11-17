-- Fixes from the final review of Phase 3.

-- A series belongs to whoever made it. Copying someone's series id onto your
-- own Meet let a series cancel reach theirs and mark their payments refunded.
-- Once scores are in, the sport and game stay, and so does the Meet.
create or replace function private.activity_lock_columns() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user = 'authenticated' then
    new.status := old.status;
    new.host_id := old.host_id;
    new.kind := old.kind;
    new.scoring_snapshot := old.scoring_snapshot;
    new.game_on_at := old.game_on_at;
    new.hidden_at := old.hidden_at;
    new.series_id := old.series_id;
    if private.is_minor(old.host_id) then
      new.public_listing := false;
    end if;
    -- A start can move later, not into the past, and not once it has passed.
    -- The end moves with it.
    if private.attendance_saved(old.id) or old.starts_at <= now() or new.starts_at < now() then
      new.starts_at := old.starts_at;
      new.ends_at := old.ends_at;
    end if;
    if private.activity_has_scores(old.id) then
      new.ranked := old.ranked;
      new.sports := old.sports;
      new.game_type := old.game_type;
    end if;
  end if;
  return new;
end;
$$;

do $$
declare
  d text := pg_get_functiondef('public.cancel_activity(uuid, boolean, text)'::regprocedure);
  fixed text;
begin
  fixed := replace(d, $old$  if a.id is null then raise exception 'Only the organizer can cancel.'; end if;$old$,
    $new$  if a.id is null then raise exception 'Only the organizer can cancel.'; end if;
  if a.starts_at <= now() and private.activity_has_scores(a.id) then
    raise exception 'This has scores, so it can''t be cancelled. Ask the OlympusGO team.';
  end if;$new$);
  fixed := replace(fixed, $old$or (series and a.series_id is not null and series_id = a.series_id
           and starts_at >= a.starts_at and status = 'published')$old$,
    $new$or (series and a.series_id is not null and series_id = a.series_id and host_id = a.host_id
           and starts_at >= a.starts_at and status = 'published')$new$);
  if position('host_id = a.host_id' in fixed) = 0 or position('has scores' in fixed) = 0 then
    raise exception 'cancel_activity did not change';
  end if;
  execute fixed;
end;
$$;

-- A masked player gets a stand-in id here too, as on rosters.
create or replace function public.player_json(p_user uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: called from functions that show players the caller may not read.
  select case
    when private.is_minor(p.id) and p.id <> auth.uid()
      and not private.is_guardian_of(auth.uid(), p.id)
    then jsonb_build_object('id', md5('player' || p.id::text)::uuid, 'username', null,
      'full_name', private.masked_name(p.full_name), 'avatar_url', null)
    else jsonb_build_object('id', p.id, 'username', p.username,
      'full_name', p.full_name, 'avatar_url', p.avatar_url)
  end
  from public.profiles p where p.id = p_user;
$$;
