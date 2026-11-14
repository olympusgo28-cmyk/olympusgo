-- P4c-02: custom templates, coach assessments and improvement over time.
-- Readable by the player, a minor's parent and the assigning coach, and writable
-- only by that coach. An academy level never touches a rating (R-RAT-6).

create table public.assessment_templates (
  id uuid primary key default gen_random_uuid(),
  academy_id uuid not null references public.academies (id) on delete cascade,
  name text not null check (char_length(trim(name)) between 2 and 60),
  scale_max int not null default 5 check (scale_max between 2 and 10),
  created_by uuid references auth.users (id) on delete set null,
  archived_at timestamptz,
  created_at timestamptz not null default now()
);
create index assessment_templates_academy_idx on public.assessment_templates (academy_id);

create table public.assessment_criteria (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null references public.assessment_templates (id) on delete cascade,
  position int not null,
  label text not null check (char_length(trim(label)) between 2 and 60),
  unique (template_id, position)
);

-- A child's record, so it holds its own names and outlives the academy.
create table public.assessments (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references auth.users (id) on delete cascade,
  student_id uuid,
  academy_id uuid not null,
  academy_name text not null,
  template_id uuid not null,
  template_name text not null,
  coach_id uuid references auth.users (id) on delete set null,
  coach_name text not null,
  assessed_on date not null,
  level int check (level between 1 and 9),
  note text not null default '' check (char_length(note) <= 1000),
  edited_at timestamptz,
  created_at timestamptz not null default now(),
  unique (player_id, template_id, assessed_on)
);
create index assessments_player_idx on public.assessments (player_id, assessed_on);
create index assessments_coach_idx on public.assessments (coach_id);

create table public.assessment_scores (
  assessment_id uuid not null references public.assessments (id) on delete cascade,
  criterion_id uuid not null,
  label text not null,
  position int not null,
  score int not null check (score >= 0),
  max_score int not null,
  primary key (assessment_id, criterion_id),
  check (score <= max_score)
);

alter table public.assessment_templates enable row level security;
alter table public.assessment_criteria enable row level security;
alter table public.assessments enable row level security;
alter table public.assessment_scores enable row level security;
revoke insert, update, delete, truncate on public.assessment_templates, public.assessment_criteria,
  public.assessments, public.assessment_scores from anon, authenticated;
revoke all on public.assessment_templates, public.assessment_criteria,
  public.assessments, public.assessment_scores from anon;

create function private.assessment_can_read(p_player uuid, p_coach uuid, p_academy uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: called from RLS on rows the caller may not read. The head coach
  -- isn't on this list unless they assigned it.
  select p_player = auth.uid() or private.is_guardian_of(auth.uid(), p_player)
    or (p_coach = auth.uid() and public.academy_is_coach(p_academy) and private.licence_ok(auth.uid()));
$$;

create policy "Player, parent and assigning coach read assessments" on public.assessments
  for select to authenticated using (private.assessment_can_read(player_id, coach_id, academy_id));
create policy "Player, parent and assigning coach read scores" on public.assessment_scores
  for select to authenticated using (exists (select 1 from public.assessments a where a.id = assessment_id));

-- ─── Templates ─────────────────────────────────────────────────────────────

create function public.assessment_template_list(p_academy uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: templates have no client access.
begin
  perform public.academy_require_coach(p_academy);
  return (select coalesce(jsonb_agg(jsonb_build_object('id', t.id, 'name', t.name, 'scale_max', t.scale_max,
      'used', exists (select 1 from public.assessments a where a.template_id = t.id),
      'criteria', (select coalesce(jsonb_agg(jsonb_build_object('id', c.id, 'label', c.label) order by c.position), '[]')
        from public.assessment_criteria c where c.template_id = t.id)) order by t.created_at), '[]')
    from public.assessment_templates t where t.academy_id = p_academy and t.archived_at is null);
end;
$$;

-- Criteria freeze once a template has been used, so a chart compares like with like.
create function public.assessment_template_save(p_academy uuid, p jsonb) returns uuid
language plpgsql security definer set search_path = '' as $$
-- Definer: templates have no client write path.
declare
  v_id uuid := nullif(p ->> 'id', '')::uuid;
  v_labels text[] := (select array_agg(trim(x)) from jsonb_array_elements_text(coalesce(p -> 'criteria', '[]')) x);
  v_scale int := coalesce((p ->> 'scale_max')::int, 5);
  v_used boolean;
begin
  perform public.academy_require_head(p_academy);
  if char_length(trim(coalesce(p ->> 'name', ''))) < 2 then raise exception 'Give the template a name.'; end if;
  if coalesce(cardinality(v_labels), 0) not between 1 and 20 then raise exception 'Add 1 to 20 things to assess.'; end if;
  if exists (select 1 from unnest(v_labels) x where char_length(x) < 2) then
    raise exception 'Name each thing you assess.';
  end if;
  if cardinality(v_labels) <> (select count(distinct lower(x)) from unnest(v_labels) x) then
    raise exception 'Each thing you assess needs its own name.';
  end if;
  if v_scale not between 2 and 10 then raise exception 'Score out of 2 to 10.'; end if;
  if private.text_problem(concat_ws(' ', p ->> 'name', array_to_string(v_labels, ' '))) is not null then
    raise exception 'Please change the wording.';
  end if;
  if v_id is null then
    insert into public.assessment_templates (academy_id, name, scale_max, created_by)
    values (p_academy, trim(p ->> 'name'), v_scale, auth.uid()) returning id into v_id;
  else
    perform 1 from public.assessment_templates where id = v_id and academy_id = p_academy for update;
    if not found then raise exception 'This template isn''t in your academy.'; end if;
    v_used := exists (select 1 from public.assessments a where a.template_id = v_id);
    if v_used and (v_scale <> (select scale_max from public.assessment_templates where id = v_id)
        or v_labels is distinct from (select array_agg(c.label order by c.position)
          from public.assessment_criteria c where c.template_id = v_id)) then
      raise exception 'This template has been used. Make a new one to change what it scores.';
    end if;
    update public.assessment_templates set name = trim(p ->> 'name'), scale_max = v_scale where id = v_id;
    if v_used then return v_id; end if;
    delete from public.assessment_criteria where template_id = v_id;
  end if;
  insert into public.assessment_criteria (template_id, position, label)
  select v_id, o::int, x from unnest(v_labels) with ordinality t(x, o);
  return v_id;
end;
$$;

create function public.assessment_template_archive(p_template uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: templates have no client write path.
declare
  v_academy uuid;
begin
  select academy_id into v_academy from public.assessment_templates where id = p_template;
  if v_academy is null then raise exception 'This template isn''t in your academy.'; end if;
  perform public.academy_require_head(v_academy);
  update public.assessment_templates set archived_at = now() where id = p_template;
end;
$$;

-- ─── Assessing ─────────────────────────────────────────────────────────────

-- Writes a new assessment, or corrects the coach's own.
create function public.assessment_save(p jsonb) returns uuid
language plpgsql security definer set search_path = '' as $$
-- Definer: assessments have no client write path.
declare
  me uuid := auth.uid();
  v_id uuid := nullif(p ->> 'id', '')::uuid;
  a public.assessments;
  s public.academy_students;
  t public.assessment_templates;
  v_scores jsonb := coalesce(p -> 'scores', '{}');
  v_on date := coalesce(nullif(p ->> 'assessed_on', '')::date, (now() at time zone 'Asia/Singapore')::date);
  v_note text := left(coalesce(trim(p ->> 'note'), ''), 1000);
  v_level int := nullif(p ->> 'level', '')::int;
  v_template uuid;
  v uuid;
begin
  if v_id is not null then
    select * into a from public.assessments where id = v_id for update;
    if a.id is null or a.coach_id is distinct from me then
      raise exception 'Only the coach who wrote this can change it.';
    end if;
    perform public.academy_require_coach(a.academy_id);
    v_template := a.template_id;
  else
    select * into s from public.academy_students where id = nullif(p ->> 'student_id', '')::uuid;
    if s.id is null then raise exception 'This student has left.'; end if;
    perform public.academy_require_coach(s.academy_id);
    if s.player_id is null then raise exception 'Ask them to enrol from their own account first.'; end if;
    if s.player_id = me then raise exception 'You can''t assess yourself.'; end if;
    if public.is_blocked_between(me, s.player_id) then raise exception 'This student has left.'; end if;
    v_template := nullif(p ->> 'template_id', '')::uuid;
  end if;
  select * into t from public.assessment_templates where id = v_template;
  if t.id is null or (v_id is null and (t.academy_id <> s.academy_id or t.archived_at is not null)) then
    raise exception 'Pick one of your academy''s templates.';
  end if;
  if v_on > (now() at time zone 'Asia/Singapore')::date then raise exception 'Pick today or an earlier day.'; end if;
  if v_level is not null and v_level not between 1 and 9 then raise exception 'Levels run from 1 to 9.'; end if;
  if private.text_problem(v_note) is not null then raise exception 'Please change the wording.'; end if;
  -- Every line is scored, and nothing else is.
  if exists (select 1 from public.assessment_criteria c where c.template_id = t.id
      and not (v_scores ? c.id::text))
     or exists (select 1 from jsonb_object_keys(v_scores) k where not exists (
       select 1 from public.assessment_criteria c where c.template_id = t.id and c.id::text = k)) then
    raise exception 'Score every line.';
  end if;
  if exists (select 1 from jsonb_each_text(v_scores) x
      where x.value !~ '^[0-9]{1,2}$' or x.value::int > t.scale_max) then
    raise exception 'Scores run from 0 to %.', t.scale_max;
  end if;

  if v_id is null then
    begin
      insert into public.assessments (player_id, student_id, academy_id, academy_name, template_id, template_name,
        coach_id, coach_name, assessed_on, level, note)
      values (s.player_id, s.id, s.academy_id, (select name from public.academies where id = s.academy_id),
        t.id, t.name, me, coalesce(public.academy_user_name(me), 'Coach'), v_on, v_level, v_note)
      returning * into a;
    exception when unique_violation then
      raise exception 'This student already has that assessment for this day.';
    end;
  else
    if exists (select 1 from public.assessments x where x.player_id = a.player_id
        and x.template_id = a.template_id and x.assessed_on = v_on and x.id <> a.id) then
      raise exception 'This student already has that assessment for this day.';
    end if;
    update public.assessments set assessed_on = v_on, level = v_level, note = v_note, edited_at = now()
    where id = v_id returning * into a;
    delete from public.assessment_scores where assessment_id = v_id;
  end if;
  insert into public.assessment_scores (assessment_id, criterion_id, label, position, score, max_score)
  select a.id, c.id, c.label, c.position, (v_scores ->> c.id::text)::int, t.scale_max
  from public.assessment_criteria c where c.template_id = t.id;

  if p ->> 'id' is null or p ->> 'id' = '' then
    if private.is_minor(a.player_id) then
      for v in select l.parent_id from public.guardian_links l
        where l.child_id = a.player_id and l.status = 'approved' loop
        perform public.notify(v, 'New assessment', a.academy_name, '✎', '/assessments/' || a.player_id, '#E3F7C8', '#2E5A00');
      end loop;
    end if;
    perform public.notify(a.player_id, 'New assessment', a.academy_name, '✎', '/assessments/' || a.player_id, '#E3F7C8', '#2E5A00');
  end if;
  return a.id;
end;
$$;

-- Oldest first, the way a chart reads. Only what the caller may read comes back.
create function public.assessment_list(p_player uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: joins scores under the same check as the policies.
  select coalesce(jsonb_agg(jsonb_build_object('id', a.id, 'academy', a.academy_name,
      'template_id', a.template_id, 'template', a.template_name, 'coach', a.coach_name,
      'assessed_on', a.assessed_on, 'level', a.level, 'note', a.note, 'edited', a.edited_at is not null,
      'mine', a.coach_id = auth.uid(),
      'scores', (select coalesce(jsonb_agg(jsonb_build_object('criterion_id', x.criterion_id, 'label', x.label,
          'score', x.score, 'max', x.max_score) order by x.position), '[]')
        from public.assessment_scores x where x.assessment_id = a.id))
      order by a.assessed_on, a.created_at), '[]')
  from public.assessments a
  where a.player_id = p_player and private.assessment_can_read(a.player_id, a.coach_id, a.academy_id);
$$;

do $$
declare
  f text;
begin
  foreach f in array array[
    'assessment_template_list(uuid)', 'assessment_template_save(uuid, jsonb)',
    'assessment_template_archive(uuid)', 'assessment_save(jsonb)', 'assessment_list(uuid)']
  loop
    execute format('revoke execute on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end;
$$;
