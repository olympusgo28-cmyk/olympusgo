-- Academies, with payments switched off: coaches run weekly classes,
-- parents ask to enrol their children, and coaches record attendance,
-- skills and notes. Fees are paid to the academy directly for now.

create table public.academies (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name text not null check (char_length(trim(name)) between 2 and 60),
  sport text not null,
  area text not null default '' check (char_length(area) <= 80),
  blurb text not null default '' check (char_length(blurb) <= 300),
  audience text not null default '' check (char_length(audience) <= 80),
  venues text[] not null default '{}',
  billing text not null default 'month' check (billing in ('term', 'month', 'perClass')),
  makeups_per_month int not null default 2 check (makeups_per_month between 0 and 8),
  -- Documents the owner said they have; Olympus checks them.
  documents text[] not null default '{}',
  verification text not null default 'none' check (verification in ('none', 'submitted', 'verified')),
  color bigint not null default 4281285215,
  ink bigint not null default 4294967295,
  cover_color bigint not null default 4293417228,
  created_at timestamptz not null default now()
);

create table public.academy_coaches (
  academy_id uuid not null references public.academies (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null default 'Coach' check (char_length(role) <= 40),
  head boolean not null default false,
  created_at timestamptz not null default now(),
  primary key (academy_id, user_id)
);

-- Coaches invited by email before they have an account.
create table public.academy_coach_invites (
  academy_id uuid not null references public.academies (id) on delete cascade,
  email text not null check (char_length(email) <= 120),
  created_at timestamptz not null default now(),
  primary key (academy_id, email)
);

create table public.academy_classes (
  id uuid primary key default gen_random_uuid(),
  academy_id uuid not null references public.academies (id) on delete cascade,
  name text not null check (char_length(trim(name)) between 2 and 60),
  level int not null default 1 check (level between 1 and 9),
  level_name text not null default '' check (char_length(level_name) <= 40),
  weekdays int[] not null check (cardinality(weekdays) between 1 and 7),
  hour int not null check (hour between 0 and 23),
  minute int not null default 0 check (minute between 0 and 59),
  minutes int not null default 90 check (minutes between 15 and 300),
  ages text not null default '' check (char_length(ages) <= 40),
  fee_cents int not null default 0 check (fee_cents between 0 and 1000000),
  capacity int not null check (capacity between 1 and 100),
  coach_id uuid references auth.users (id) on delete set null,
  court text not null default '' check (char_length(court) <= 40),
  term_weeks int not null default 10 check (term_weeks between 1 and 52),
  created_at timestamptz not null default now()
);
create index academy_classes_academy_idx on public.academy_classes (academy_id);

create table public.academy_students (
  id uuid primary key default gen_random_uuid(),
  academy_id uuid not null references public.academies (id) on delete cascade,
  class_id uuid not null references public.academy_classes (id) on delete cascade,
  -- The parent, or the adult student themself.
  parent_id uuid not null references auth.users (id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 80),
  age int check (age between 3 and 99),
  filming_consent boolean not null default false,
  makeup_credits int not null default 0 check (makeup_credits >= 0),
  credit_use_by date,
  notice text check (char_length(notice) <= 300),
  notice_coming boolean,
  created_at timestamptz not null default now()
);
create index academy_students_class_idx on public.academy_students (class_id);
create index academy_students_parent_idx on public.academy_students (parent_id);

create table public.academy_requests (
  id uuid primary key default gen_random_uuid(),
  academy_id uuid not null references public.academies (id) on delete cascade,
  class_id uuid not null references public.academy_classes (id) on delete cascade,
  parent_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  student text not null check (char_length(trim(student)) between 1 and 80),
  age int check (age between 3 and 99),
  note text not null default '' check (char_length(note) <= 500),
  kind text not null default 'enrol' check (kind in ('enrol', 'trial')),
  trial_at timestamptz,
  state text not null default 'pending' check (state in ('pending', 'accepted', 'declined')),
  created_at timestamptz not null default now()
);
create index academy_requests_academy_idx on public.academy_requests (academy_id, state);

-- One row per student per class held: present, absent or a make-up.
create table public.academy_attendance (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.academy_students (id) on delete cascade,
  class_id uuid not null references public.academy_classes (id) on delete cascade,
  held_on date not null,
  week int not null,
  lesson text not null default '',
  state text not null check (state in ('present', 'absent', 'makeup')),
  unique (student_id, class_id, held_on)
);

create table public.academy_skills (
  student_id uuid not null references public.academy_students (id) on delete cascade,
  skill_id text not null,
  status text not null check (status in ('notYet', 'practising', 'gotIt')),
  week int,
  primary key (student_id, skill_id)
);

create table public.academy_notes (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.academy_students (id) on delete cascade,
  coach_id uuid references auth.users (id) on delete set null,
  lesson text not null default '',
  present boolean not null default true,
  body text not null check (char_length(body) between 1 and 1000),
  got text,
  practising text,
  created_at timestamptz not null default now()
);

create table public.academy_makeups (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.academy_students (id) on delete cascade,
  class_id uuid not null references public.academy_classes (id) on delete cascade,
  at timestamptz not null,
  created_at timestamptz not null default now()
);

create table public.academy_plans (
  academy_id uuid not null references public.academies (id) on delete cascade,
  level int not null,
  week int not null,
  drills jsonb not null default '[]' check (jsonb_typeof(drills) = 'array'),
  note text not null default '',
  edited_by uuid references auth.users (id) on delete set null,
  edited_at timestamptz not null default now(),
  primary key (academy_id, level, week)
);

create table public.academy_invites (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.academy_classes (id) on delete cascade,
  mobile text not null,
  created_at timestamptz not null default now()
);

alter table public.academies enable row level security;
alter table public.academy_coaches enable row level security;
alter table public.academy_coach_invites enable row level security;
alter table public.academy_classes enable row level security;
alter table public.academy_students enable row level security;
alter table public.academy_requests enable row level security;
alter table public.academy_attendance enable row level security;
alter table public.academy_skills enable row level security;
alter table public.academy_notes enable row level security;
alter table public.academy_makeups enable row level security;
alter table public.academy_plans enable row level security;
alter table public.academy_invites enable row level security;
-- Everything goes through the functions below.

-- ─── Helpers ───────────────────────────────────────────────────────────────

create function public.academy_is_coach(p_academy uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.academy_coaches
                 where academy_id = p_academy and user_id = (select auth.uid()));
$$;

create function public.academy_require_coach(p_academy uuid) returns void
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.academy_is_coach(p_academy) then
    raise exception 'Only the academy''s coaches can do this.';
  end if;
end;
$$;

create function public.academy_require_head(p_academy uuid) returns void
language plpgsql stable security definer set search_path = '' as $$
begin
  if not exists (select 1 from public.academy_coaches
                 where academy_id = p_academy and user_id = (select auth.uid()) and head) then
    raise exception 'Only the head coach can do this.';
  end if;
end;
$$;

create function public.academy_user_name(p_user uuid) returns text
language sql stable security definer set search_path = '' as $$
  select coalesce(full_name, username::text, 'Coach') from public.profiles where id = p_user;
$$;

-- The default term plan: topic and the skills it works on.
create function public.academy_default_plan(p_sport text) returns jsonb
language sql immutable set search_path = '' as $$
  select case when p_sport = 'badminton' then '[
    ["Grip, ready position and split-step", "Split-step · Low serve", "fw1"],
    ["Clears from the back", "Forehand clear · Recover to base", "st1"],
    ["Backhand clear", "Backhand clear", "st2"],
    ["Smash basics and high serve", "Smash · High serve", "st3"],
    ["Net play", "Net kill · Lunge to the net", "st4"],
    ["Net shots under pressure", "Rally of 10", "gs1"],
    ["Doubles basics", "Practice week", ""],
    ["Doubles positions", "Doubles positions", "gs2"],
    ["Scoring and calls", "Scoring and calls", "gs3"],
    ["Skills check", "Coaches confirm level-up", ""]]'::jsonb
  else '[
    ["Grip and ready position", "Ready position", "fw1"],
    ["Footwork basics", "Footwork", "fw2"],
    ["Forehand", "Forehand", "st1"],
    ["Backhand", "Backhand", "st2"],
    ["Serve", "Serve", "sv1"],
    ["Rallying", "Rally of 10", "gs1"],
    ["Practice week", "Practice week", ""],
    ["Match play", "Match play", "gs2"],
    ["Scoring and calls", "Scoring and calls", "gs3"],
    ["Skills check", "Coaches confirm level-up", ""]]'::jsonb end;
$$;

-- The skills a student works through: id, group and name.
create function public.academy_skill_template(p_sport text) returns jsonb
language sql immutable set search_path = '' as $$
  select case when p_sport = 'badminton' then '[
    ["fw1", "Footwork", "Split-step"], ["fw2", "Footwork", "Recover to base"],
    ["fw3", "Footwork", "Lunge to the net"], ["st1", "Strokes", "Forehand clear"],
    ["st2", "Strokes", "Backhand clear"], ["st3", "Strokes", "Smash"],
    ["st4", "Strokes", "Net kill"], ["sv1", "Serve", "Low serve"],
    ["sv2", "Serve", "High serve"], ["gs1", "Game sense", "Rally of 10"],
    ["gs2", "Game sense", "Doubles positions"], ["gs3", "Game sense", "Scoring and calls"]]'::jsonb
  else '[
    ["fw1", "Footwork", "Ready position"], ["fw2", "Footwork", "Moving to the ball"],
    ["st1", "Strokes", "Forehand"], ["st2", "Strokes", "Backhand"],
    ["sv1", "Serve", "Serve"], ["gs1", "Game sense", "Rally of 10"],
    ["gs2", "Game sense", "Match play"], ["gs3", "Game sense", "Scoring and calls"]]'::jsonb end;
$$;

-- Classes held so far, and so this week's number.
create function public.academy_class_week(p_class uuid) returns int
language sql stable security definer set search_path = '' as $$
  select least(
    (select count(distinct held_on) from public.academy_attendance where class_id = p_class)::int + 1,
    (select term_weeks from public.academy_classes where id = p_class));
$$;

create function public.academy_class_json(p_class uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'id', c.id, 'academy_id', c.academy_id, 'name', c.name, 'level', c.level,
    'level_name', c.level_name, 'weekdays', c.weekdays, 'hour', c.hour,
    'minute', c.minute, 'minutes', c.minutes, 'ages', c.ages,
    'fee_cents', c.fee_cents, 'capacity', c.capacity,
    'enrolled', (select count(*) from public.academy_students where class_id = c.id),
    'coach', coalesce(public.academy_user_name(c.coach_id), ''),
    'coach_id', c.coach_id, 'court', c.court,
    'week', w.week, 'term_weeks', c.term_weeks,
    'lesson', coalesce(public.academy_default_plan(a.sport) -> (w.week - 1) ->> 0, ''),
    'focus_skill', coalesce(public.academy_default_plan(a.sport) -> (w.week - 1) ->> 2, ''))
  from public.academy_classes c
  join public.academies a on a.id = c.academy_id
  cross join lateral (select public.academy_class_week(c.id) as week) w
  where c.id = p_class;
$$;

create function public.academy_json(p_academy uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'id', a.id, 'name', a.name, 'sport', a.sport, 'area', a.area, 'blurb', a.blurb,
    'audience', a.audience, 'billing', a.billing,
    'makeups_per_month', a.makeups_per_month, 'verification', a.verification,
    'color', a.color, 'ink', a.ink, 'cover_color', a.cover_color,
    'students', (select count(*) from public.academy_students where academy_id = a.id),
    'my_role', case
      when exists (select 1 from public.academy_coaches where academy_id = a.id
                     and user_id = (select auth.uid()) and head) then 'headCoach'
      when public.academy_is_coach(a.id) then 'coach'
      when exists (select 1 from public.academy_students where academy_id = a.id
                     and parent_id = (select auth.uid())) then 'parent'
      else 'none' end,
    'pending_requests', case when public.academy_is_coach(a.id) then
      (select count(*) from public.academy_requests where academy_id = a.id and state = 'pending')
      else 0 end,
    'coaches', (select coalesce(jsonb_agg(jsonb_build_object(
        'id', k.user_id, 'name', public.academy_user_name(k.user_id),
        'role', k.role, 'head', k.head) order by k.head desc, k.created_at), '[]')
      from public.academy_coaches k where k.academy_id = a.id),
    'invited', (select coalesce(jsonb_agg(email order by created_at), '[]')
      from public.academy_coach_invites where academy_id = a.id),
    'classes', (select coalesce(jsonb_agg(public.academy_class_json(c.id)
        order by c.level, c.hour, c.minute), '[]')
      from public.academy_classes c where c.academy_id = a.id))
  from public.academies a where a.id = p_academy;
$$;

create function public.academy_can_see_student(p_student uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.academy_students s
                 where s.id = p_student
                   and (s.parent_id = (select auth.uid()) or public.academy_is_coach(s.academy_id)));
$$;

create function public.academy_student_json(p_student uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'id', s.id, 'name', s.name, 'age', s.age, 'academy_id', s.academy_id,
    'class_id', s.class_id, 'parent', coalesce(public.academy_user_name(s.parent_id), ''),
    'filming_consent', s.filming_consent, 'makeup_credits', s.makeup_credits,
    'credit_use_by', s.credit_use_by, 'notice', s.notice, 'notice_coming', s.notice_coming,
    'attended', (select count(*) from public.academy_attendance
                 where student_id = s.id and state in ('present', 'makeup')),
    'held', (select count(*) from public.academy_attendance where student_id = s.id),
    'missed_in_a_row', (select count(*) from (
        select state from public.academy_attendance where student_id = s.id
        order by held_on desc limit 2) x where x.state = 'absent'),
    'skills', (select jsonb_agg(jsonb_build_object(
        'id', t ->> 0, 'group', t ->> 1, 'name', t ->> 2,
        'status', coalesce(k.status, 'notYet'),
        'week', case when k.week is null then '' else 'Week ' || k.week end) order by o)
      from jsonb_array_elements(public.academy_skill_template(a.sport)) with ordinality as e(t, o)
      left join public.academy_skills k on k.student_id = s.id and k.skill_id = t ->> 0),
    'notes', (select coalesce(jsonb_agg(jsonb_build_object(
        'coach', coalesce(public.academy_user_name(n.coach_id), 'Coach'),
        'at', n.created_at, 'lesson', n.lesson, 'present', n.present, 'text', n.body,
        'got', n.got, 'practising', n.practising) order by n.created_at desc), '[]')
      from public.academy_notes n where n.student_id = s.id))
  from public.academy_students s join public.academies a on a.id = s.academy_id
  where s.id = p_student;
$$;

revoke execute on function public.academy_require_coach(uuid), public.academy_require_head(uuid),
  public.academy_user_name(uuid), public.academy_class_week(uuid), public.academy_class_json(uuid),
  public.academy_json(uuid), public.academy_can_see_student(uuid), public.academy_student_json(uuid)
from public, anon, authenticated;

-- ─── Browsing and joining ──────────────────────────────────────────────────

create function public.academy_list() returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(public.academy_json(id) order by created_at desc), '[]')
  from public.academies;
$$;

create function public.academy_get(p_academy uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v jsonb := public.academy_json(p_academy);
begin
  if v is null then raise exception 'This academy is no longer listed.'; end if;
  return v;
end;
$$;

-- Asks to enrol a student (or book a trial class).
create function public.academy_request(
  p_class uuid, p_student text, p_age int, p_note text, p_trial_at timestamptz
) returns void
language plpgsql security definer set search_path = '' as $$
declare
  c public.academy_classes;
  v_me uuid := (select auth.uid());
  v_name text;
  k uuid;
begin
  select * into c from public.academy_classes where id = p_class;
  if not found then raise exception 'This class no longer runs.'; end if;
  if coalesce(trim(p_student), '') = '' then raise exception 'Say who is joining.'; end if;
  if exists (select 1 from public.academy_requests
             where class_id = p_class and parent_id = v_me and state = 'pending'
               and lower(student) = lower(trim(p_student))) then
    raise exception 'You''ve already asked for % in this class.', trim(p_student);
  end if;
  insert into public.academy_requests (academy_id, class_id, parent_id, student, age, note, kind, trial_at)
  values (c.academy_id, p_class, v_me, trim(p_student), p_age, left(coalesce(p_note, ''), 500),
          case when p_trial_at is null then 'enrol' else 'trial' end, p_trial_at);
  v_name := coalesce(public.academy_user_name(v_me), 'A parent');
  for k in select user_id from public.academy_coaches where academy_id = c.academy_id and head loop
    perform public.notify(k,
      case when p_trial_at is null then 'Enrolment request' else 'Trial class booked' end,
      trim(p_student) || ' · ' || c.name || ' · from ' || v_name, '★',
      '/academies/' || c.academy_id || '/requests', '#16181B', '#C6FF00');
  end loop;
end;
$$;

-- ─── Parents ───────────────────────────────────────────────────────────────

create function public.academy_my_students() returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(public.academy_student_json(id) order by created_at), '[]')
  from public.academy_students where parent_id = (select auth.uid());
$$;

create function public.academy_student(p_student uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.academy_can_see_student(p_student) then
    raise exception 'This student has left.';
  end if;
  return public.academy_student_json(p_student);
end;
$$;

create function public.academy_lessons(p_student uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'week', w, 'title', coalesce(public.academy_default_plan(a.sport) -> (w - 1) ->> 0, 'Week ' || w),
    'attended', exists (select 1 from public.academy_attendance t
                        where t.student_id = s.id and t.week = w and t.state <> 'absent'))
    order by w), '[]')
  from public.academy_students s
  join public.academy_classes c on c.id = s.class_id
  join public.academies a on a.id = s.academy_id
  cross join generate_series(1, c.term_weeks) w
  where s.id = p_student and public.academy_can_see_student(p_student);
$$;

-- Same-level classes with space in the next two weeks, at least a day away.
create function public.academy_makeup_slots(p_student uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  with s as (select st.*, c.level from public.academy_students st
             join public.academy_classes c on c.id = st.class_id
             where st.id = p_student and public.academy_can_see_student(p_student))
  select coalesce(jsonb_agg(jsonb_build_object(
    'class_id', c.id, 'class_name', c.name,
    'at', (d + make_time(c.hour, c.minute, 0)) at time zone 'Asia/Singapore',
    'coach', coalesce(public.academy_user_name(c.coach_id), ''),
    'lesson', public.academy_class_json(c.id) ->> 'lesson',
    'spots', greatest(c.capacity - (select count(*) from public.academy_students x
                                    where x.class_id = c.id), 0))
    order by d, c.hour), '[]')
  from s
  join public.academy_classes c on c.academy_id = s.academy_id and c.level = s.level
  cross join generate_series(current_date + 1, current_date + 14, interval '1 day') d
  where extract(isodow from d)::int = any (c.weekdays)
    and (select count(*) from public.academy_students x where x.class_id = c.id) < c.capacity;
$$;

create function public.academy_book_makeup(p_student uuid, p_class uuid, p_at timestamptz)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  s public.academy_students;
begin
  select * into s from public.academy_students where id = p_student and parent_id = (select auth.uid());
  if not found then raise exception 'This student has left.'; end if;
  if s.makeup_credits < 1 then raise exception 'No make-up credits left.'; end if;
  update public.academy_students set makeup_credits = makeup_credits - 1 where id = p_student;
  insert into public.academy_makeups (student_id, class_id, at) values (p_student, p_class, p_at);
end;
$$;

-- The parent answers a change the coach sent. Missing a moved class earns
-- a make-up credit.
create function public.academy_answer_notice(p_student uuid, p_coming boolean) returns void
language plpgsql security definer set search_path = '' as $$
begin
  update public.academy_students
  set notice_coming = p_coming,
      makeup_credits = makeup_credits + case when p_coming or notice_coming is false then 0 else 1 end,
      credit_use_by = coalesce(credit_use_by, current_date + 30)
  where id = p_student and parent_id = (select auth.uid()) and notice is not null;
  if not found then raise exception 'There''s nothing to answer.'; end if;
end;
$$;

create function public.academy_filming(p_student uuid, p_own boolean) returns void
language plpgsql security definer set search_path = '' as $$
begin
  update public.academy_students set filming_consent = p_own
  where id = p_student and parent_id = (select auth.uid());
  if not found then raise exception 'Only the parent can change this.'; end if;
end;
$$;

create function public.academy_attendance_list(p_student uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(x order by (x->>'at') desc), '[]') from (
    select jsonb_build_object('at', (t.held_on + make_time(c.hour, c.minute, 0)) at time zone 'Asia/Singapore',
      'lesson', t.lesson,
      'state', case t.state when 'present' then 'Present' when 'absent' then 'Absent' else 'Make-up' end) as x
    from public.academy_attendance t join public.academy_classes c on c.id = t.class_id
    where t.student_id = p_student and public.academy_can_see_student(p_student)
  ) y;
$$;

-- ─── Coaches ───────────────────────────────────────────────────────────────

create function public.academy_request_list(p_academy uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.academy_require_coach(p_academy);
  return (select coalesce(jsonb_agg(jsonb_build_object(
      'id', r.id, 'academy_id', r.academy_id, 'student', r.student, 'age', r.age,
      'parent', coalesce(public.academy_user_name(r.parent_id), ''),
      'class_id', r.class_id, 'class_name', c.name,
      'note', case when r.kind = 'trial'
                   then concat_ws(' · ', 'Trial on ' || to_char(r.trial_at at time zone 'Asia/Singapore', 'Dy DD Mon, FMHH12:MI AM'), nullif(r.note, ''))
                   else r.note end,
      'state', r.state) order by r.state <> 'pending', r.created_at desc), '[]')
    from public.academy_requests r join public.academy_classes c on c.id = r.class_id
    where r.academy_id = p_academy);
end;
$$;

-- Accepting an enrolment adds the student to the class.
create function public.academy_decide(p_request uuid, p_state text) returns void
language plpgsql security definer set search_path = '' as $$
declare
  r public.academy_requests;
  c public.academy_classes;
begin
  select * into r from public.academy_requests where id = p_request;
  if not found then raise exception 'This request is no longer here.'; end if;
  perform public.academy_require_coach(r.academy_id);
  if r.state <> 'pending' then raise exception 'This request has been answered.'; end if;
  if p_state not in ('accepted', 'declined') then raise exception 'Accept or decline.'; end if;
  select * into c from public.academy_classes where id = r.class_id;
  if p_state = 'accepted' and r.kind = 'enrol'
     and (select count(*) from public.academy_students where class_id = c.id) >= c.capacity then
    raise exception '% is full.', c.name;
  end if;
  update public.academy_requests set state = p_state where id = p_request;
  if p_state = 'accepted' and r.kind = 'enrol' then
    insert into public.academy_students (academy_id, class_id, parent_id, name, age)
    values (r.academy_id, r.class_id, r.parent_id, r.student, r.age);
  end if;
  perform public.notify(r.parent_id,
    case when p_state = 'accepted' then r.student || ' is in ' || c.name
         else 'No space for ' || r.student || ' yet' end,
    (select name from public.academies where id = r.academy_id)
      || case when p_state = 'accepted' and r.kind = 'trial' then '. See you at the trial.'
              when p_state = 'accepted' then '. Pay the academy directly for fees.'
              else '. Try another class or ask again later.' end,
    case when p_state = 'accepted' then '✓' else '!' end,
    '/academies/' || r.academy_id, '#E3F7C8', '#2E5A00');
end;
$$;

create function public.academy_roster(p_class uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_academy uuid;
begin
  select academy_id into v_academy from public.academy_classes where id = p_class;
  perform public.academy_require_coach(v_academy);
  return (select coalesce(jsonb_agg(public.academy_student_json(id) order by name), '[]')
          from public.academy_students where class_id = p_class);
end;
$$;

-- Records a class: who came, the focus skill and a note for each student.
-- [p_absent] lists student ids; [p_skills] maps student id to a status.
create function public.academy_save_session(
  p_class uuid, p_absent uuid[], p_skills jsonb, p_note text
) returns void
language plpgsql security definer set search_path = '' as $$
declare
  c jsonb := public.academy_class_json(p_class);
  v_week int;
  s record;
  v_present boolean;
  v_status text;
begin
  if c is null then raise exception 'This class no longer runs.'; end if;
  perform public.academy_require_coach((c->>'academy_id')::uuid);
  v_week := (c->>'week')::int;
  for s in select * from public.academy_students where class_id = p_class loop
    v_present := not (s.id = any (coalesce(p_absent, '{}')));
    insert into public.academy_attendance (student_id, class_id, held_on, week, lesson, state)
    values (s.id, p_class, (now() at time zone 'Asia/Singapore')::date, v_week, c->>'lesson',
            case when v_present then 'present' else 'absent' end)
    on conflict (student_id, class_id, held_on) do update set state = excluded.state;
    v_status := p_skills ->> s.id::text;
    if v_status is not null and coalesce(c->>'focus_skill', '') <> '' then
      insert into public.academy_skills (student_id, skill_id, status, week)
      values (s.id, c->>'focus_skill', v_status, v_week)
      on conflict (student_id, skill_id) do update set status = excluded.status, week = excluded.week;
    end if;
    if coalesce(trim(p_note), '') <> '' then
      insert into public.academy_notes (student_id, coach_id, lesson, present, body)
      values (s.id, (select auth.uid()), 'Week ' || v_week || ' · ' || (c->>'lesson'), v_present, trim(p_note));
    end if;
  end loop;
  -- Make-up students booked for today count as present.
  insert into public.academy_attendance (student_id, class_id, held_on, week, lesson, state)
  select m.student_id, p_class, (now() at time zone 'Asia/Singapore')::date, v_week, c->>'lesson', 'makeup'
  from public.academy_makeups m
  where m.class_id = p_class
    and (m.at at time zone 'Asia/Singapore')::date = (now() at time zone 'Asia/Singapore')::date
  on conflict do nothing;
end;
$$;

-- What a coach should look at today.
create function public.academy_alerts(p_academy uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_pending int;
  v_unanswered int;
  v_makeups int;
  v jsonb := '[]';
begin
  perform public.academy_require_coach(p_academy);
  select count(*) into v_pending from public.academy_requests
  where academy_id = p_academy and state = 'pending';
  select count(*) into v_unanswered from public.academy_students
  where academy_id = p_academy and notice is not null and notice_coming is null;
  select count(*) into v_makeups from public.academy_makeups m
  join public.academy_classes c on c.id = m.class_id
  where c.academy_id = p_academy and m.at between now() and now() + interval '7 days';
  if v_pending > 0 then
    v := v || jsonb_build_object('title', v_pending || ' enrolment ' ||
      case when v_pending = 1 then 'request' else 'requests' end,
      'body', 'Reply within 2 working days.', 'tone', 'navy', 'action', 'Open');
  end if;
  if v_unanswered > 0 then
    v := v || jsonb_build_object('title', v_unanswered || ' ' ||
      case when v_unanswered = 1 then 'parent hasn''t' else 'parents haven''t' end
      || ' answered your class change', 'body', 'They see it on their child''s page.',
      'tone', 'yellow');
  end if;
  if v_makeups > 0 then
    v := v || jsonb_build_object('title', v_makeups || ' make-up ' ||
      case when v_makeups = 1 then 'booking' else 'bookings' end || ' this week',
      'body', 'They join a class at their level.', 'tone', 'navy');
  end if;
  return v;
end;
$$;

-- Moves, covers or cancels the next class and tells the parents. Returns
-- how many parents were told.
create function public.academy_change_class(
  p_class uuid, p_mode text, p_notice text, p_coach uuid
) returns int
language plpgsql security definer set search_path = '' as $$
declare
  c public.academy_classes;
  v_parents uuid[];
  v uuid;
begin
  select * into c from public.academy_classes where id = p_class;
  if not found then raise exception 'This class no longer runs.'; end if;
  perform public.academy_require_coach(c.academy_id);
  if coalesce(trim(p_notice), '') = '' then raise exception 'Write the notice for parents.'; end if;
  if p_mode = 'cover' and p_coach is not null then
    if not exists (select 1 from public.academy_coaches
                   where academy_id = c.academy_id and user_id = p_coach) then
      raise exception 'Pick one of the academy''s coaches.';
    end if;
  end if;
  update public.academy_students set notice = left(trim(p_notice), 300), notice_coming = null
  where class_id = p_class;
  select array_agg(distinct parent_id) into v_parents from public.academy_students where class_id = p_class;
  foreach v in array coalesce(v_parents, '{}') loop
    perform public.notify(v, c.name || ' has changed', left(trim(p_notice), 200), '!',
      '/academies/' || c.academy_id);
  end loop;
  return coalesce(cardinality(v_parents), 0);
end;
$$;

-- Lesson plans for a level: the default topics with any edits.
create function public.academy_curriculum(p_academy uuid, p_level int) returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'week', o, 'topic', t ->> 0, 'skills', t ->> 1,
    'drills', coalesce(p.drills, '[]'),
    'version', case when p.edited_at is null then '' else
      'Edited by ' || coalesce(public.academy_user_name(p.edited_by), 'a coach') end,
    'edited_at', p.edited_at) order by o), '[]')
  from public.academies a
  cross join jsonb_array_elements(public.academy_default_plan(a.sport)) with ordinality as e(t, o)
  left join public.academy_plans p on p.academy_id = a.id and p.level = p_level and p.week = o
  where a.id = p_academy and public.academy_is_coach(p_academy);
$$;

create function public.academy_save_plan(
  p_academy uuid, p_level int, p_week int, p_drills jsonb, p_note text
) returns void
language plpgsql security definer set search_path = '' as $$
begin
  perform public.academy_require_coach(p_academy);
  insert into public.academy_plans (academy_id, level, week, drills, note, edited_by, edited_at)
  values (p_academy, p_level, p_week, coalesce(p_drills, '[]'), coalesce(p_note, ''),
          (select auth.uid()), now())
  on conflict (academy_id, level, week) do update
    set drills = excluded.drills, note = excluded.note, edited_by = excluded.edited_by,
        edited_at = now();
end;
$$;

create function public.academy_invite_list(p_class uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_academy uuid;
begin
  select academy_id into v_academy from public.academy_classes where id = p_class;
  perform public.academy_require_coach(v_academy);
  return (select coalesce(jsonb_agg(jsonb_build_object('mobile', mobile, 'at', created_at)
            order by created_at desc), '[]')
          from public.academy_invites where class_id = p_class);
end;
$$;

-- Invites a parent by mobile. If they're on OlympusGO, they get a
-- notification with the academy page.
create function public.academy_invite(p_class uuid, p_mobile text) returns void
language plpgsql security definer set search_path = '' as $$
declare
  c public.academy_classes;
  v_digits text := regexp_replace(coalesce(p_mobile, ''), '[^0-9]', '', 'g');
  v_user uuid;
begin
  select * into c from public.academy_classes where id = p_class;
  if not found then raise exception 'This class no longer runs.'; end if;
  perform public.academy_require_coach(c.academy_id);
  if char_length(v_digits) < 8 then raise exception 'Enter a mobile number, like 9123 4567.'; end if;
  insert into public.academy_invites (class_id, mobile) values (p_class, trim(p_mobile));
  select id into v_user from auth.users
  where right(regexp_replace(coalesce(phone, ''), '[^0-9]', '', 'g'), 8) = right(v_digits, 8)
  limit 1;
  if v_user is not null then
    perform public.notify(v_user, 'You''re invited to ' || c.name,
      (select name from public.academies where id = c.academy_id) || '. Ask to enrol from the academy page.',
      '★', '/academies/' || c.academy_id || '/enrol', '#16181B', '#C6FF00');
  end if;
end;
$$;

-- A coach's note to a parent, with skill updates by skill id.
create function public.academy_parent_note(p_student uuid, p_skills jsonb, p_note text)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  s public.academy_students;
  k text;
  v_week int;
begin
  select * into s from public.academy_students where id = p_student;
  if not found then raise exception 'This student has left.'; end if;
  perform public.academy_require_coach(s.academy_id);
  v_week := public.academy_class_week(s.class_id);
  for k in select jsonb_object_keys(coalesce(p_skills, '{}')) loop
    insert into public.academy_skills (student_id, skill_id, status, week)
    values (p_student, k, p_skills ->> k, v_week)
    on conflict (student_id, skill_id) do update set status = excluded.status, week = excluded.week;
  end loop;
  if coalesce(trim(p_note), '') <> '' then
    insert into public.academy_notes (student_id, coach_id, lesson, body)
    values (p_student, (select auth.uid()), 'Note from the coach', trim(p_note));
  end if;
  perform public.notify(s.parent_id, 'A note about ' || s.name,
    left(coalesce(nullif(trim(p_note), ''), 'Skills updated'), 200), '✎',
    '/students/' || s.id, '#E3F7C8', '#2E5A00');
end;
$$;

-- ─── Running the academy ───────────────────────────────────────────────────

-- Creates the academy with its owner as head coach. Coaches who already
-- have an account join straight away; others are kept as invites.
create function public.academy_create(p jsonb) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_id uuid;
  v_me uuid := (select auth.uid());
  e text;
  v_user uuid;
begin
  if char_length(trim(coalesce(p->>'name', ''))) < 2 then
    raise exception 'Give your academy a name.';
  end if;
  insert into public.academies (owner_id, name, sport, area, blurb, audience, venues,
    billing, makeups_per_month, documents, verification)
  values (v_me, trim(p->>'name'), coalesce(p->>'sport', 'badminton'),
    coalesce(p->>'area', ''), left(coalesce(p->>'blurb', ''), 300),
    left(coalesce(p->>'audience', ''), 80),
    coalesce((select array_agg(x) from jsonb_array_elements_text(p->'venues') x), '{}'),
    coalesce(p->>'billing', 'month'), coalesce((p->>'makeups')::int, 2),
    coalesce((select array_agg(x) from jsonb_array_elements_text(p->'documents') x), '{}'),
    case when jsonb_array_length(coalesce(p->'documents', '[]')) > 0 then 'submitted' else 'none' end)
  returning id into v_id;
  insert into public.academy_coaches (academy_id, user_id, role, head)
  values (v_id, v_me, 'Head coach', true);
  for e in select lower(trim(x)) from jsonb_array_elements_text(coalesce(p->'coaches', '[]')) x loop
    continue when e = '' or e !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$';
    select id into v_user from auth.users where lower(email) = e;
    if v_user is not null and v_user <> v_me then
      insert into public.academy_coaches (academy_id, user_id) values (v_id, v_user)
      on conflict do nothing;
      perform public.notify(v_user, 'You''re a coach at ' || trim(p->>'name'),
        'Open the academy to see your classes.', '★', '/academies/' || v_id || '/today');
    elsif v_user is null then
      insert into public.academy_coach_invites (academy_id, email) values (v_id, e)
      on conflict do nothing;
    end if;
  end loop;
  return v_id;
end;
$$;

-- Coaches who signed up after being invited by email join on their own.
create function public.academy_claim_invites() returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_me uuid := (select auth.uid());
  v_email text := (select lower(email) from auth.users where id = (select auth.uid()));
begin
  insert into public.academy_coaches (academy_id, user_id)
  select academy_id, v_me from public.academy_coach_invites where email = v_email
  on conflict do nothing;
  delete from public.academy_coach_invites where email = v_email;
end;
$$;

create function public.academy_update(p_academy uuid, p jsonb) returns void
language plpgsql security definer set search_path = '' as $$
begin
  perform public.academy_require_head(p_academy);
  update public.academies set
    billing = coalesce(p->>'billing', billing),
    makeups_per_month = coalesce((p->>'makeups')::int, makeups_per_month),
    blurb = coalesce(p->>'blurb', blurb),
    verification = case when p ? 'documents' and verification = 'none'
                        and jsonb_array_length(p->'documents') > 0 then 'submitted' else verification end,
    documents = case when p ? 'documents'
                     then (select coalesce(array_agg(x), '{}') from jsonb_array_elements_text(p->'documents') x)
                     else documents end
  where id = p_academy;
end;
$$;

-- Adds a coach by username, or removes one (never the head coach).
create function public.academy_set_coach(p_academy uuid, p_username text, p_add boolean)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid;
begin
  perform public.academy_require_head(p_academy);
  -- A user id (from the coach list) or a username.
  if p_username ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    v_user := p_username::uuid;
  else
    select id into v_user from public.profiles
    where lower(username::text) = lower(trim(both '@' from trim(p_username)));
  end if;
  if v_user is null then raise exception 'No player has that username.'; end if;
  if p_add then
    insert into public.academy_coaches (academy_id, user_id) values (p_academy, v_user)
    on conflict do nothing;
    perform public.notify(v_user, 'You''re a coach at ' ||
      (select name from public.academies where id = p_academy),
      'Open the academy to see your classes.', '★', '/academies/' || p_academy || '/today');
  else
    delete from public.academy_coaches where academy_id = p_academy and user_id = v_user and not head;
    update public.academy_classes set coach_id = null where academy_id = p_academy and coach_id = v_user;
  end if;
end;
$$;

-- Adds or edits a weekly class.
create function public.academy_save_class(p_academy uuid, p jsonb) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_id uuid := nullif(p->>'id', '')::uuid;
  v_coach uuid := nullif(p->>'coach_id', '')::uuid;
  v_days int[] := (select array_agg(x::int) from jsonb_array_elements_text(p->'weekdays') x);
begin
  perform public.academy_require_head(p_academy);
  if v_coach is not null and not exists (select 1 from public.academy_coaches
                                         where academy_id = p_academy and user_id = v_coach) then
    raise exception 'Pick one of the academy''s coaches.';
  end if;
  if coalesce(cardinality(v_days), 0) = 0 then raise exception 'Pick at least one day.'; end if;
  if v_id is null then
    insert into public.academy_classes (academy_id, name, level, level_name, weekdays, hour, minute,
      minutes, ages, fee_cents, capacity, coach_id, court, term_weeks)
    values (p_academy, trim(p->>'name'), coalesce((p->>'level')::int, 1),
      coalesce(p->>'level_name', ''), v_days, (p->>'hour')::int, coalesce((p->>'minute')::int, 0),
      coalesce((p->>'minutes')::int, 90), coalesce(p->>'ages', ''),
      coalesce((p->>'fee_cents')::int, 0), (p->>'capacity')::int, v_coach,
      coalesce(p->>'court', ''), coalesce((p->>'term_weeks')::int, 10))
    returning id into v_id;
  else
    update public.academy_classes set name = trim(p->>'name'), level = coalesce((p->>'level')::int, level),
      level_name = coalesce(p->>'level_name', level_name), weekdays = v_days,
      hour = (p->>'hour')::int, minute = coalesce((p->>'minute')::int, 0),
      minutes = coalesce((p->>'minutes')::int, minutes), ages = coalesce(p->>'ages', ages),
      fee_cents = coalesce((p->>'fee_cents')::int, fee_cents),
      capacity = (p->>'capacity')::int, coach_id = v_coach, court = coalesce(p->>'court', court)
    where id = v_id and academy_id = p_academy;
    if not found then raise exception 'This class isn''t in your academy.'; end if;
  end if;
  return v_id;
end;
$$;

-- Closes the academy and tells every parent.
create function public.academy_close(p_academy uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v uuid;
  v_name text;
begin
  perform public.academy_require_head(p_academy);
  select name into v_name from public.academies where id = p_academy;
  for v in select distinct parent_id from public.academy_students where academy_id = p_academy loop
    perform public.notify(v, v_name || ' has closed',
      'Its classes have stopped. Contact the academy about any fees you paid.', '!', null);
  end loop;
  delete from public.academies where id = p_academy;
end;
$$;

do $$
declare
  f text;
begin
  foreach f in array array[
    'academy_is_coach(uuid)', 'academy_default_plan(text)', 'academy_skill_template(text)',
    'academy_list()', 'academy_get(uuid)',
    'academy_request(uuid, text, int, text, timestamptz)', 'academy_my_students()',
    'academy_student(uuid)', 'academy_lessons(uuid)', 'academy_makeup_slots(uuid)',
    'academy_book_makeup(uuid, uuid, timestamptz)', 'academy_answer_notice(uuid, boolean)',
    'academy_filming(uuid, boolean)', 'academy_attendance_list(uuid)',
    'academy_request_list(uuid)', 'academy_decide(uuid, text)', 'academy_roster(uuid)',
    'academy_save_session(uuid, uuid[], jsonb, text)', 'academy_alerts(uuid)',
    'academy_change_class(uuid, text, text, uuid)', 'academy_curriculum(uuid, int)',
    'academy_save_plan(uuid, int, int, jsonb, text)', 'academy_invite_list(uuid)',
    'academy_invite(uuid, text)', 'academy_parent_note(uuid, jsonb, text)',
    'academy_create(jsonb)', 'academy_claim_invites()', 'academy_update(uuid, jsonb)',
    'academy_set_coach(uuid, text, boolean)', 'academy_save_class(uuid, jsonb)',
    'academy_close(uuid)']
  loop
    execute format('revoke execute on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end;
$$;
