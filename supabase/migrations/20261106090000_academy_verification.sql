-- P4c-01: verification, coaches who agreed to coach, students who are real
-- accounts, make-up credits that follow R-ACD-3, and closing without deleting.

insert into public.app_settings (key, value, description) values
  ('academy.credit_days', '30', 'How long a make-up credit lasts (R-ACD-3)'),
  ('academy.makeup_notice_hours', '24', 'How far ahead a make-up must be booked (R-ACD-3)');

-- ─── Verification ──────────────────────────────────────────────────────────

alter table public.academies
  add column uen text check (uen ~ '^[0-9A-Z]{9,10}$'),
  add column licence_path text check (char_length(licence_path) <= 300),
  add column rejected_reason text check (char_length(rejected_reason) <= 300),
  add column reviewed_at timestamptz,
  add column closed_at timestamptz;
alter table public.academies drop constraint academies_verification_check;
alter table public.academies add constraint academies_verification_check
  check (verification in ('none', 'submitted', 'verified', 'rejected'));

-- A tick the owner set was never a check. Nothing was reviewed.
update public.academies set verification = 'none' where verification = 'submitted';
alter table public.academies drop column documents;

-- One licence per person, whichever academies they coach at.
create table public.coach_licences (
  user_id uuid primary key references auth.users (id) on delete cascade,
  nroc_number text not null check (char_length(trim(nroc_number)) between 3 and 30),
  expires_on date not null,
  status text not null default 'submitted' check (status in ('submitted', 'verified', 'rejected')),
  file_path text check (char_length(file_path) <= 300),
  rejected_reason text check (char_length(rejected_reason) <= 300),
  -- Set once. A renewal under review doesn't take away the classes they have.
  verified_at timestamptz,
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.coach_licences enable row level security;

create table public.coach_profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  headline text not null default '' check (char_length(headline) <= 80),
  bio text not null default '' check (char_length(bio) <= 500),
  years_coaching int check (years_coaching between 0 and 70),
  updated_at timestamptz not null default now()
);
alter table public.coach_profiles enable row level security;

-- Files are seen only by review staff, and go once the check is done.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('verification-docs', 'verification-docs', false, 5242880,
  array['image/jpeg', 'image/png', 'image/heic', 'application/pdf']);

create policy "Owners upload their own verification files" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'verification-docs'
    and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "Review staff read verification files" on storage.objects
  for select to authenticated
  using (bucket_id = 'verification-docs' and private.is_staff('content'));
create policy "Review staff delete verification files" on storage.objects
  for delete to authenticated
  using (bucket_id = 'verification-docs' and private.is_staff('content'));

-- ─── Coaches agree first ───────────────────────────────────────────────────

alter table public.academy_coaches add column accepted_at timestamptz;
update public.academy_coaches set accepted_at = created_at;

create or replace function public.academy_is_coach(p_academy uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: called on tables the caller can't read. Closed means nobody coaches here.
  select exists (select 1 from public.academy_coaches k
                 join public.academies a on a.id = k.academy_id
                 where k.academy_id = p_academy and k.user_id = (select auth.uid())
                   and k.accepted_at is not null and a.closed_at is null);
$$;

-- Was ever verified and hasn't been refused since. Keeps the classes they have.
create function private.licence_ok(p_user uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: coach_licences has no client access.
  select exists (select 1 from public.coach_licences l
    where l.user_id = p_user and l.verified_at is not null and l.status <> 'rejected');
$$;

-- Good for new classes and slots (R-ACD-1).
create function private.licence_current(p_user uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: coach_licences has no client access.
  select exists (select 1 from public.coach_licences l
    where l.user_id = p_user and l.status = 'verified'
      and l.expires_on >= (now() at time zone 'Asia/Singapore')::date);
$$;

create or replace function public.academy_require_coach(p_academy uuid) returns void
language plpgsql stable security definer set search_path = '' as $$
-- Definer: reads coach rows and licences. A coach sees children, so only a
-- verified one gets past here.
begin
  if not public.academy_is_coach(p_academy) then
    raise exception 'Only the academy''s coaches can do this.';
  end if;
  if not private.licence_ok(auth.uid()) then
    raise exception 'We need to verify your coaching licence first.';
  end if;
end;
$$;

create or replace function public.academy_require_head(p_academy uuid) returns void
language plpgsql stable security definer set search_path = '' as $$
-- Definer: reads coach rows.
begin
  if not public.academy_is_coach(p_academy) or not exists (select 1 from public.academy_coaches
      where academy_id = p_academy and user_id = (select auth.uid()) and head) then
    raise exception 'Only the head coach can do this.';
  end if;
end;
$$;

-- The coach's answer. Nobody joins an academy, or sees its children, without one.
create function public.academy_coach_answer(p_academy uuid, p_accept boolean) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: academy_coaches has no client write path.
declare
  me uuid := auth.uid();
begin
  if p_accept and private.is_minor(me) then raise exception 'Coaches must be 18 or over.'; end if;
  if p_accept then
    update public.academy_coaches set accepted_at = now()
    where academy_id = p_academy and user_id = me and accepted_at is null;
  else
    delete from public.academy_coaches
    where academy_id = p_academy and user_id = me and accepted_at is null;
  end if;
  if not found then raise exception 'This invitation has ended.'; end if;
end;
$$;

create function public.academy_my_coach_invites() returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: academy_coaches has no client access.
  select coalesce(jsonb_agg(jsonb_build_object('academy_id', a.id, 'name', a.name)
    order by k.created_at), '[]')
  from public.academy_coaches k join public.academies a on a.id = k.academy_id
  where k.user_id = auth.uid() and k.accepted_at is null and a.closed_at is null;
$$;

-- ─── Profiles and licences ─────────────────────────────────────────────────

create function public.coach_profile_save(p_headline text, p_bio text, p_years int) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: coach_profiles has no client write path.
begin
  if private.is_minor(auth.uid()) then raise exception 'Coaches must be 18 or over.'; end if;
  if private.text_problem(concat_ws(' ', p_headline, p_bio)) is not null then
    raise exception 'Please change the wording.';
  end if;
  insert into public.coach_profiles (user_id, headline, bio, years_coaching)
  values (auth.uid(), left(coalesce(trim(p_headline), ''), 80), left(coalesce(trim(p_bio), ''), 500), p_years)
  on conflict (user_id) do update
    set headline = excluded.headline, bio = excluded.bio, years_coaching = excluded.years_coaching,
        updated_at = now();
end;
$$;

-- A coach's public page: only an adult with a current licence at a verified
-- academy. Anyone else looks the same as nobody.
create function public.coach_profile_get(p_user uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: reads profiles, licences and academies.
declare
  v_academies jsonb;
begin
  select jsonb_agg(jsonb_build_object('id', a.id, 'name', a.name, 'role', k.role) order by a.name)
  into v_academies
  from public.academy_coaches k join public.academies a on a.id = k.academy_id
  where k.user_id = p_user and k.accepted_at is not null
    and a.closed_at is null and a.verification = 'verified';
  if v_academies is null or private.is_minor(p_user) or not private.licence_current(p_user)
     or public.is_blocked_between(auth.uid(), p_user) then
    raise exception 'This coach isn''t listed.';
  end if;
  return (select jsonb_build_object('id', p_user, 'name', public.academy_user_name(p_user),
      'avatar_url', (select r.avatar_url from public.profiles r where r.id = p_user),
      'headline', coalesce(c.headline, ''), 'bio', coalesce(c.bio, ''),
      'years_coaching', c.years_coaching, 'academies', v_academies, 'licence_verified', true)
    from (select 1) x left join public.coach_profiles c on c.user_id = p_user);
end;
$$;

-- What the coach sees of their own check. No file path comes back.
create function public.coach_licence_my() returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: coach_licences has no client access.
  select jsonb_build_object('status', coalesce(l.status, 'none'), 'nroc_number', l.nroc_number,
    'expires_on', l.expires_on, 'rejected_reason', l.rejected_reason,
    'current', private.licence_current(auth.uid()),
    'headline', coalesce(c.headline, ''), 'bio', coalesce(c.bio, ''), 'years_coaching', c.years_coaching)
  from (select 1) x
  left join public.coach_licences l on l.user_id = auth.uid()
  left join public.coach_profiles c on c.user_id = auth.uid();
$$;

create function private.doc_uploaded(p_path text) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: the caller can't read the bucket. The path must be in their folder.
  select split_part(p_path, '/', 1) = auth.uid()::text
    and exists (select 1 from storage.objects o where o.bucket_id = 'verification-docs' and o.name = p_path);
$$;

create function public.coach_licence_submit(p_number text, p_expires date, p_path text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: coach_licences has no client write path.
declare
  me uuid := auth.uid();
begin
  if private.is_minor(me) then raise exception 'Coaches must be 18 or over.'; end if;
  if char_length(coalesce(trim(p_number), '')) < 3 then raise exception 'Enter your NROC number.'; end if;
  if p_expires is null or p_expires <= (now() at time zone 'Asia/Singapore')::date then
    raise exception 'This licence has expired.';
  end if;
  if not private.doc_uploaded(p_path) then raise exception 'Add a photo of your licence.'; end if;
  insert into public.coach_licences (user_id, nroc_number, expires_on, file_path)
  values (me, left(trim(p_number), 30), p_expires, p_path)
  on conflict (user_id) do update
    set nroc_number = excluded.nroc_number, expires_on = excluded.expires_on,
        file_path = excluded.file_path, status = 'submitted', rejected_reason = null,
        updated_at = now();
end;
$$;

create function public.academy_submit_business(p_academy uuid, p_uen text, p_path text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: verification is never written by a client.
declare
  a public.academies;
  v_uen text := upper(trim(coalesce(p_uen, '')));
begin
  select * into a from public.academies where id = p_academy for update;
  if a.owner_id is distinct from auth.uid() or a.closed_at is not null then
    raise exception 'Only the owner can do this.';
  end if;
  if a.verification = 'verified' then raise exception 'This academy is verified. Contact us to change it.'; end if;
  if v_uen !~ '^[0-9A-Z]{9,10}$' then raise exception 'Enter your UEN. It has 9 or 10 characters.'; end if;
  if not private.doc_uploaded(p_path) then raise exception 'Add your business licence.'; end if;
  update public.academies
  set uen = v_uen, licence_path = p_path, verification = 'submitted', rejected_reason = null
  where id = p_academy;
end;
$$;

-- The owner's checklist: what's done and what's still needed.
create function public.academy_verification(p_academy uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: reads licences and the payout account of the academy's coaches.
declare
  a public.academies;
begin
  perform public.academy_require_head(p_academy);
  select * into a from public.academies where id = p_academy;
  return jsonb_build_object('verification', a.verification, 'uen', a.uen,
    'rejected_reason', a.rejected_reason,
    'payout_ready', exists (select 1 from public.vendors v where v.owner_id = a.owner_id and v.status = 'verified'),
    'is_owner', a.owner_id = auth.uid(),
    'coaches', (select coalesce(jsonb_agg(jsonb_build_object('id', k.user_id,
        'name', public.academy_user_name(k.user_id), 'head', k.head, 'accepted', k.accepted_at is not null,
        'licence', case when private.licence_current(k.user_id) then 'verified'
          else coalesce((select l.status from public.coach_licences l where l.user_id = k.user_id), 'none') end)
        order by k.head desc, k.created_at), '[]')
      from public.academy_coaches k where k.academy_id = p_academy));
end;
$$;

-- ─── Students are accounts ─────────────────────────────────────────────────

alter table public.academy_students
  add column player_id uuid references auth.users (id) on delete cascade,
  add column notice_at timestamptz;
alter table public.academy_requests
  add column player_id uuid references auth.users (id) on delete cascade;
create unique index academy_students_one_player on public.academy_students (class_id, player_id);
create index academy_students_player_idx on public.academy_students (player_id);

-- May act for this student. A revoked link ends it, whoever enrolled them.
create function private.academy_acts_for(s public.academy_students) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: reads guardian links.
  select case when s.player_id is null then s.parent_id = auth.uid()
    when private.is_minor(s.player_id) then private.is_guardian_of(auth.uid(), s.player_id)
    else s.player_id = auth.uid() end;
$$;

create function private.player_age(p_user uuid) returns int
language sql stable security definer set search_path = '' as $$
  -- Definer: birthdays are private to their owner. Only the age leaves here.
  select private.age_years(ap.birthday, c.timezone)
  from public.account_private ap left join public.country_config c on c.country_code = ap.country_code
  where ap.id = p_user;
$$;

create or replace function public.academy_can_see_student(p_student uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: reads students and coaches on the caller's behalf.
  select exists (select 1 from public.academy_students s
    where s.id = p_student
      and (private.academy_acts_for(s) or s.player_id = (select auth.uid())
        or (public.academy_is_coach(s.academy_id) and private.licence_ok((select auth.uid())))));
$$;

create or replace function public.academy_my_students() returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: reads guardian links.
  select coalesce(jsonb_agg(public.academy_student_json(s.id) order by s.created_at), '[]')
  from public.academy_students s join public.academies a on a.id = s.academy_id
  where a.closed_at is null and (private.academy_acts_for(s) or s.player_id = (select auth.uid()));
$$;

-- Who this person may enrol: themself if adult, plus linked children.
create function public.academy_my_players() returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: reads guardian links and ages.
  select coalesce(jsonb_agg(jsonb_build_object('id', x.id, 'name', public.academy_user_name(x.id),
      'age', private.player_age(x.id), 'self', x.id = auth.uid()) order by x.id <> auth.uid(), x.id), '[]')
  from (
    select auth.uid() as id where not private.is_minor(auth.uid())
    union
    select l.child_id from public.guardian_links l
    where l.parent_id = auth.uid() and l.status = 'approved' and private.is_minor(l.child_id)) x;
$$;

-- Refuses anyone the caller can't enrol, and any block between them and the academy.
create function private.academy_check_player(p_academy uuid, p_player uuid) returns void
language plpgsql stable security definer set search_path = '' as $$
-- Definer: reads guardian links and blocks.
declare
  me uuid := auth.uid();
begin
  if p_player = me and private.is_minor(me) then
    raise exception 'A parent needs to do this for you.';
  end if;
  if p_player is null or (p_player <> me and not private.is_guardian_of(me, p_player)) then
    raise exception 'You can enrol yourself or a child linked to your account.';
  end if;
  if exists (select 1 from public.academy_coaches k
      where k.academy_id = p_academy
        and (public.is_blocked_between(me, k.user_id) or public.is_blocked_between(p_player, k.user_id)))
     or exists (select 1 from public.academies a where a.id = p_academy
        and (public.is_blocked_between(me, a.owner_id) or public.is_blocked_between(p_player, a.owner_id))) then
    raise exception 'This class isn''t available.';
  end if;
end;
$$;

create function private.academy_open_to_all(a public.academies) returns boolean
language sql stable set search_path = '' as $$
  select a.closed_at is null and a.verification = 'verified';
$$;

create function private.academy_visible(a public.academies) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: reads coach and student rows.
  select private.academy_open_to_all(a)
    or (a.closed_at is null and (a.owner_id = auth.uid()
      or exists (select 1 from public.academy_coaches k where k.academy_id = a.id and k.user_id = auth.uid())
      or exists (select 1 from public.academy_students s where s.academy_id = a.id
        and (private.academy_acts_for(s) or s.player_id = auth.uid()))));
$$;

create or replace function public.academy_list() returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: reads what the client can't.
  select coalesce(jsonb_agg(public.academy_json(a.id) order by a.created_at desc), '[]')
  from public.academies a where private.academy_visible(a);
$$;

create or replace function public.academy_get(p_academy uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: reads what the client can't.
declare
  a public.academies;
begin
  select * into a from public.academies where id = p_academy;
  if a.id is null or not private.academy_visible(a) then
    raise exception 'This academy is no longer listed.';
  end if;
  return public.academy_json(p_academy);
end;
$$;

create or replace function public.academy_json(p_academy uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'id', a.id, 'name', a.name, 'sport', a.sport, 'area', a.area, 'blurb', a.blurb,
    'audience', a.audience, 'billing', a.billing,
    'makeups_per_month', a.makeups_per_month, 'verification', a.verification,
    'color', a.color, 'ink', a.ink, 'cover_color', a.cover_color,
    'students', (select count(*) from public.academy_students where academy_id = a.id),
    'my_role', case
      when exists (select 1 from public.academy_coaches where academy_id = a.id and accepted_at is not null
                     and user_id = (select auth.uid()) and head) then 'headCoach'
      when public.academy_is_coach(a.id) then 'coach'
      when exists (select 1 from public.academy_students s where s.academy_id = a.id
                     and (private.academy_acts_for(s) or s.player_id = (select auth.uid()))) then 'parent'
      else 'none' end,
    'pending_requests', case when public.academy_is_coach(a.id) and private.licence_ok((select auth.uid())) then
      (select count(*) from public.academy_requests where academy_id = a.id and state = 'pending')
      else 0 end,
    'coaches', (select coalesce(jsonb_agg(jsonb_build_object(
        'id', k.user_id, 'name', public.academy_user_name(k.user_id),
        'role', k.role, 'head', k.head, 'licensed', private.licence_current(k.user_id))
        order by k.head desc, k.created_at), '[]')
      from public.academy_coaches k where k.academy_id = a.id and k.accepted_at is not null),
    -- Invited people's emails are for the head coach only.
    'invited', case when exists (select 1 from public.academy_coaches where academy_id = a.id
                       and user_id = (select auth.uid()) and head and accepted_at is not null)
      then (select coalesce(jsonb_agg(email order by created_at), '[]')
            from public.academy_coach_invites where academy_id = a.id)
      else '[]'::jsonb end,
    'classes', (select coalesce(jsonb_agg(public.academy_class_json(c.id)
        order by c.level, c.hour, c.minute), '[]')
      from public.academy_classes c where c.academy_id = a.id))
  from public.academies a where a.id = p_academy;
$$;

-- ─── Asking to enrol ───────────────────────────────────────────────────────

drop function public.academy_request(uuid, text, int, text, timestamptz);
create function public.academy_request(
  p_class uuid, p_player uuid, p_note text, p_trial_at timestamptz
) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: academy_requests has no client write path.
declare
  c public.academy_classes;
  a public.academies;
  v_me uuid := (select auth.uid());
  v_name text;
  k uuid;
begin
  select * into c from public.academy_classes where id = p_class;
  if not found then raise exception 'This class no longer runs.'; end if;
  select * into a from public.academies where id = c.academy_id;
  if not private.academy_open_to_all(a) then raise exception 'This academy is no longer listed.'; end if;
  perform private.academy_check_player(c.academy_id, p_player);
  if private.text_problem(p_note) is not null then raise exception 'Please change the wording.'; end if;
  if exists (select 1 from public.academy_requests
             where class_id = p_class and player_id = p_player and state = 'pending'
               and kind = case when p_trial_at is null then 'enrol' else 'trial' end) then
    raise exception 'You''ve already asked for this class.';
  end if;
  if exists (select 1 from public.academy_students where class_id = p_class and player_id = p_player) then
    raise exception 'They''re already in this class.';
  end if;
  v_name := public.academy_user_name(p_player);
  insert into public.academy_requests (academy_id, class_id, parent_id, player_id, student, age, note, kind, trial_at)
  values (c.academy_id, p_class, v_me, p_player, v_name, private.player_age(p_player), left(coalesce(p_note, ''), 500),
          case when p_trial_at is null then 'enrol' else 'trial' end, p_trial_at);
  for k in select user_id from public.academy_coaches
           where academy_id = c.academy_id and head and accepted_at is not null loop
    perform public.notify(k,
      case when p_trial_at is null then 'Enrolment request' else 'Trial class booked' end,
      c.name, '★', '/academies/' || c.academy_id || '/requests', '#16181B', '#C6FF00');
  end loop;
end;
$$;

create or replace function public.academy_decide(p_request uuid, p_state text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: students have no client write path.
declare
  r public.academy_requests;
  c public.academy_classes;
begin
  select * into r from public.academy_requests where id = p_request;
  if not found then raise exception 'This request is no longer here.'; end if;
  perform public.academy_require_coach(r.academy_id);
  if p_state not in ('accepted', 'declined') then raise exception 'Accept or decline.'; end if;
  -- Under the class lock, so two yeses can't overfill it.
  select * into c from public.academy_classes where id = r.class_id for update;
  select * into r from public.academy_requests where id = p_request for update;
  if r.state <> 'pending' then raise exception 'This request has been answered.'; end if;
  if p_state = 'accepted' and r.kind = 'enrol' then
    if r.player_id is null then raise exception 'Ask them to enrol from their own account.'; end if;
    if (select count(*) from public.academy_students where class_id = c.id) >= c.capacity then
      raise exception '% is full.', c.name;
    end if;
    insert into public.academy_students (academy_id, class_id, parent_id, player_id, name, age)
    values (r.academy_id, r.class_id, r.parent_id, r.player_id, r.student, private.player_age(r.player_id));
  end if;
  update public.academy_requests set state = p_state where id = p_request;
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

-- ─── Make-up credits (R-ACD-3) ─────────────────────────────────────────────

-- Each credit has its own 30 days, and each source gives one, once.
create table public.academy_makeup_credits (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.academy_students (id) on delete cascade,
  source text not null unique,
  expires_on date not null,
  used_at timestamptz,
  created_at timestamptz not null default now()
);
create index academy_makeup_credits_student_idx on public.academy_makeup_credits (student_id);
alter table public.academy_makeup_credits enable row level security;

insert into public.academy_makeup_credits (student_id, source, expires_on)
select s.id, 'old:' || s.id || ':' || n, coalesce(s.credit_use_by, (now() at time zone 'Asia/Singapore')::date + 30)
from public.academy_students s cross join generate_series(1, s.makeup_credits) n;
alter table public.academy_students drop column makeup_credits, drop column credit_use_by;

create unique index academy_makeups_once on public.academy_makeups (student_id, class_id, at);

-- Classes already called off, so a second notice gives no second credit.
create table public.academy_cancellations (
  class_id uuid not null references public.academy_classes (id) on delete cascade,
  held_on date not null,
  created_at timestamptz not null default now(),
  primary key (class_id, held_on)
);
alter table public.academy_cancellations enable row level security;

create function private.academy_grant_credit(p_student uuid, p_source text) returns void
language sql security definer set search_path = '' as $$
  -- Definer: credits have no client write path.
  insert into public.academy_makeup_credits (student_id, source, expires_on)
  values (p_student, p_source, (now() at time zone 'Asia/Singapore')::date
    + private.setting_int('academy.credit_days'))
  on conflict (source) do nothing;
$$;

-- Everyone who takes a place in this class at this moment.
create function private.class_taken(p_class uuid, p_at timestamptz) returns int
language sql stable security definer set search_path = '' as $$
  -- Definer: reads students and bookings.
  select ((select count(*) from public.academy_students where class_id = p_class)
    + (select count(*) from public.academy_makeups where class_id = p_class and at = p_at))::int;
$$;

create function private.class_meets_at(c public.academy_classes, p_at timestamptz) returns boolean
language sql stable set search_path = '' as $$
  select extract(isodow from l)::int = any (c.weekdays)
    and extract(hour from l)::int = c.hour and extract(minute from l)::int = c.minute
    and extract(second from l) = 0
  from (select p_at at time zone 'Asia/Singapore' as l) x;
$$;

create function private.class_next_date(c public.academy_classes) returns date
language sql stable set search_path = '' as $$
  select min(d) from generate_series(0, 7) n
  cross join lateral (select (now() at time zone 'Asia/Singapore')::date + n as d) y
  where extract(isodow from d)::int = any (c.weekdays)
    and (d + make_time(c.hour, c.minute, 0)) at time zone 'Asia/Singapore' > now();
$$;

create or replace function public.academy_student_json(p_student uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'id', s.id, 'name', s.name, 'academy_id', s.academy_id, 'player_id', s.player_id,
    'age', coalesce(private.player_age(s.player_id), s.age),
    'class_id', s.class_id, 'parent', coalesce(public.academy_user_name(s.parent_id), ''),
    'filming_consent', s.filming_consent,
    'can_act', private.academy_acts_for(s),
    'makeup_credits', (select count(*) from public.academy_makeup_credits k
      where k.student_id = s.id and k.used_at is null
        and k.expires_on >= (now() at time zone 'Asia/Singapore')::date),
    'credit_use_by', (select min(k.expires_on) from public.academy_makeup_credits k
      where k.student_id = s.id and k.used_at is null
        and k.expires_on >= (now() at time zone 'Asia/Singapore')::date),
    'notice', s.notice, 'notice_coming', s.notice_coming,
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

-- Same-level classes with space, at least a day away.
create or replace function public.academy_makeup_slots(p_student uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: reads classes on the student's behalf.
  with s as (select st.*, c.level from public.academy_students st
             join public.academy_classes c on c.id = st.class_id
             where st.id = p_student and public.academy_can_see_student(p_student))
  select coalesce(jsonb_agg(jsonb_build_object(
    'class_id', c.id, 'class_name', c.name, 'at', x.at,
    'coach', coalesce(public.academy_user_name(c.coach_id), ''),
    'lesson', public.academy_class_json(c.id) ->> 'lesson',
    'spots', c.capacity - private.class_taken(c.id, x.at))
    order by x.at), '[]')
  from s
  join public.academy_classes c on c.academy_id = s.academy_id and c.level = s.level
  cross join generate_series(0, 14) n
  cross join lateral (select (now() at time zone 'Asia/Singapore')::date + n as d) y
  cross join lateral (select (d + make_time(c.hour, c.minute, 0)) at time zone 'Asia/Singapore' as at) x
  where extract(isodow from d)::int = any (c.weekdays)
    and x.at >= now() + make_interval(hours => private.setting_int('academy.makeup_notice_hours'))
    and private.class_taken(c.id, x.at) < c.capacity;
$$;

create or replace function public.academy_book_makeup(p_student uuid, p_class uuid, p_at timestamptz)
returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: credits and make-ups have no client write path.
declare
  s public.academy_students;
  c public.academy_classes;
  a public.academies;
  v_level int;
  v_credit uuid;
  v_month date := date_trunc('month', now() at time zone 'Asia/Singapore')::date;
begin
  -- The student first, so one credit can't be spent twice at once.
  select * into s from public.academy_students where id = p_student for update;
  if not found or not private.academy_acts_for(s) then raise exception 'This student has left.'; end if;
  select level into v_level from public.academy_classes where id = s.class_id;
  select * into c from public.academy_classes where id = p_class for update;
  if not found or c.academy_id <> s.academy_id then raise exception 'Pick a class at your academy.'; end if;
  select * into a from public.academies where id = s.academy_id;
  if a.closed_at is not null then raise exception 'This academy has closed.'; end if;
  if c.level <> v_level then raise exception 'Make-ups are for classes at the same level.'; end if;
  if not private.class_meets_at(c, p_at) then raise exception 'This class doesn''t run then.'; end if;
  if p_at < now() + make_interval(hours => private.setting_int('academy.makeup_notice_hours')) then
    raise exception 'Book a make-up at least 24 hours ahead.';
  end if;
  if exists (select 1 from public.academy_makeups m where m.student_id = p_student and m.class_id = p_class and m.at = p_at) then
    raise exception 'This make-up is already booked.';
  end if;
  if (select count(*) from public.academy_makeups m where m.student_id = p_student
      and (m.at at time zone 'Asia/Singapore')::date >= v_month
      and (m.at at time zone 'Asia/Singapore')::date < v_month + interval '1 month') >= a.makeups_per_month then
    raise exception 'This academy allows % make-ups a month.', a.makeups_per_month;
  end if;
  if private.class_taken(c.id, p_at) >= c.capacity then raise exception 'This class is full.'; end if;
  select id into v_credit from public.academy_makeup_credits
  where student_id = p_student and used_at is null
    and expires_on >= (now() at time zone 'Asia/Singapore')::date
  order by expires_on, created_at limit 1 for update;
  if v_credit is null then raise exception 'No make-up credits left.'; end if;
  update public.academy_makeup_credits set used_at = now() where id = v_credit;
  insert into public.academy_makeups (student_id, class_id, at) values (p_student, p_class, p_at);
end;
$$;

-- The parent answers a change the coach sent. Can't make it gives one credit.
create or replace function public.academy_answer_notice(p_student uuid, p_coming boolean) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: students have no client write path.
declare
  s public.academy_students;
begin
  select * into s from public.academy_students where id = p_student for update;
  if not found or not private.academy_acts_for(s) or s.notice is null then
    raise exception 'There''s nothing to answer.';
  end if;
  update public.academy_students set notice_coming = p_coming where id = p_student;
  if not p_coming then
    perform private.academy_grant_credit(p_student, 'notice:' || p_student || ':' || coalesce(s.notice_at::text, 'old'));
  end if;
end;
$$;

create or replace function public.academy_filming(p_student uuid, p_own boolean) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: students have no client write path.
declare
  s public.academy_students;
begin
  select * into s from public.academy_students where id = p_student for update;
  if not found or not private.academy_acts_for(s) then raise exception 'Only the parent can change this.'; end if;
  update public.academy_students set filming_consent = p_own where id = p_student;
end;
$$;

-- Moves, covers or cancels the next class and tells the parents. Returns how
-- many were told. Cancelling gives every student one credit.
create or replace function public.academy_change_class(
  p_class uuid, p_mode text, p_notice text, p_coach uuid
) returns int
language plpgsql security definer set search_path = '' as $$
-- Definer: writes students' notices and credits.
declare
  c public.academy_classes;
  v_parents uuid[];
  v uuid;
  v_on date;
begin
  select * into c from public.academy_classes where id = p_class for update;
  if not found then raise exception 'This class no longer runs.'; end if;
  perform public.academy_require_coach(c.academy_id);
  if coalesce(trim(p_notice), '') = '' then raise exception 'Write the notice for parents.'; end if;
  if p_mode in ('coach', 'cover') and p_coach is not null then
    if not exists (select 1 from public.academy_coaches
                   where academy_id = c.academy_id and user_id = p_coach and accepted_at is not null) then
      raise exception 'Pick one of the academy''s coaches.';
    end if;
    if not private.licence_current(p_coach) then
      raise exception 'That coach''s licence isn''t verified.';
    end if;
  end if;
  if p_mode = 'cancel' then
    v_on := private.class_next_date(c);
    insert into public.academy_cancellations (class_id, held_on) values (p_class, v_on)
    on conflict do nothing;
    if found then
      perform private.academy_grant_credit(s.id, 'cancel:' || p_class || ':' || v_on || ':' || s.id)
      from public.academy_students s where s.class_id = p_class;
    end if;
  end if;
  update public.academy_students
  set notice = left(trim(p_notice), 300), notice_coming = null, notice_at = now()
  where class_id = p_class;
  select array_agg(distinct parent_id) into v_parents from public.academy_students where class_id = p_class;
  foreach v in array coalesce(v_parents, '{}') loop
    perform public.notify(v, c.name || ' has changed', left(trim(p_notice), 200), '!',
      '/academies/' || c.academy_id);
  end loop;
  return coalesce(cardinality(v_parents), 0);
end;
$$;

-- ─── Running the academy ───────────────────────────────────────────────────

-- An unverified head coach still sets up, so these don't need a licence.
create or replace function public.academy_alerts(p_academy uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: reads what the client can't.
declare
  v_pending int;
  v_unanswered int;
  v_makeups int;
  v jsonb := '[]';
begin
  if not public.academy_is_coach(p_academy) then
    raise exception 'Only the academy''s coaches can do this.';
  end if;
  if not private.licence_ok(auth.uid()) then return v; end if;
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

create or replace function public.academy_save_plan(
  p_academy uuid, p_level int, p_week int, p_drills jsonb, p_note text
) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: plans have no client write path. Holds no child's data.
begin
  if not public.academy_is_coach(p_academy) then
    raise exception 'Only the academy''s coaches can do this.';
  end if;
  insert into public.academy_plans (academy_id, level, week, drills, note, edited_by, edited_at)
  values (p_academy, p_level, p_week, coalesce(p_drills, '[]'), coalesce(p_note, ''),
          (select auth.uid()), now())
  on conflict (academy_id, level, week) do update
    set drills = excluded.drills, note = excluded.note, edited_by = excluded.edited_by,
        edited_at = now();
end;
$$;

-- Creates the academy with its owner as head coach. Other coaches are invited,
-- and join when they say yes.
create or replace function public.academy_create(p jsonb) returns uuid
language plpgsql security definer set search_path = '' as $$
-- Definer: academies have no client write path.
declare
  v_id uuid;
  v_me uuid := (select auth.uid());
  e text;
  v_user uuid;
begin
  if private.is_minor(v_me) then raise exception 'Academies are run by adults.'; end if;
  if char_length(trim(coalesce(p->>'name', ''))) < 2 then
    raise exception 'Give your academy a name.';
  end if;
  insert into public.academies (owner_id, name, sport, area, blurb, audience, venues,
    billing, makeups_per_month)
  values (v_me, trim(p->>'name'), coalesce(p->>'sport', 'badminton'),
    coalesce(p->>'area', ''), left(coalesce(p->>'blurb', ''), 300),
    left(coalesce(p->>'audience', ''), 80),
    coalesce((select array_agg(x) from jsonb_array_elements_text(p->'venues') x), '{}'),
    coalesce(p->>'billing', 'month'), coalesce((p->>'makeups')::int, 2))
  returning id into v_id;
  insert into public.academy_coaches (academy_id, user_id, role, head, accepted_at)
  values (v_id, v_me, 'Head coach', true, now());
  for e in select lower(trim(x)) from jsonb_array_elements_text(coalesce(p->'coaches', '[]')) x loop
    continue when e = '' or e !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$';
    select id into v_user from public.account_private where email = e and email_verified_at is not null;
    if v_user is not null and v_user <> v_me then
      if not private.is_minor(v_user) then
        insert into public.academy_coaches (academy_id, user_id) values (v_id, v_user)
        on conflict do nothing;
        perform public.notify(v_user, 'Coach at ' || trim(p->>'name') || '?',
          'Open it to say yes or no.', '★', '/academies/' || v_id || '/coach-invite');
      end if;
    elsif v_user is null then
      insert into public.academy_coach_invites (academy_id, email) values (v_id, e)
      on conflict do nothing;
    end if;
  end loop;
  return v_id;
end;
$$;

-- Coaches who signed up after being invited by email still get to say yes.
create or replace function public.academy_claim_invites() returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes coach rows.
declare
  v_me uuid := (select auth.uid());
  v_email text := (select email from public.account_private where id = (select auth.uid()) and email_verified_at is not null);
begin
  if v_email is null or private.is_minor(v_me) then return; end if;
  insert into public.academy_coaches (academy_id, user_id)
  select academy_id, v_me from public.academy_coach_invites where email = v_email
  on conflict do nothing;
  delete from public.academy_coach_invites where email = v_email;
end;
$$;

create or replace function public.academy_update(p_academy uuid, p jsonb) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: academies have no client write path.
begin
  perform public.academy_require_head(p_academy);
  update public.academies set
    billing = coalesce(p->>'billing', billing),
    makeups_per_month = coalesce((p->>'makeups')::int, makeups_per_month),
    blurb = coalesce(p->>'blurb', blurb)
  where id = p_academy;
end;
$$;

-- Invites a coach by username, or removes one (never the head coach).
create or replace function public.academy_set_coach(p_academy uuid, p_username text, p_add boolean)
returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes coach rows.
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
    if private.is_minor(v_user) then raise exception 'Coaches must be 18 or over.'; end if;
    if public.is_blocked_between(auth.uid(), v_user) then raise exception 'No player has that username.'; end if;
    insert into public.academy_coaches (academy_id, user_id) values (p_academy, v_user)
    on conflict do nothing;
    if found then
      perform public.notify(v_user, 'Coach at ' ||
        (select name from public.academies where id = p_academy) || '?',
        'Open it to say yes or no.', '★', '/academies/' || p_academy || '/coach-invite');
    end if;
  else
    delete from public.academy_coaches where academy_id = p_academy and user_id = v_user and not head;
    update public.academy_classes set coach_id = null where academy_id = p_academy and coach_id = v_user;
  end if;
end;
$$;

-- Adds or edits a weekly class. A new coach on it must hold a current licence.
create or replace function public.academy_save_class(p_academy uuid, p jsonb) returns uuid
language plpgsql security definer set search_path = '' as $$
-- Definer: classes have no client write path.
declare
  v_id uuid := nullif(p->>'id', '')::uuid;
  v_coach uuid := nullif(p->>'coach_id', '')::uuid;
  v_days int[] := (select array_agg(x::int) from jsonb_array_elements_text(p->'weekdays') x);
  v_was uuid;
begin
  perform public.academy_require_head(p_academy);
  if v_coach is not null and not exists (select 1 from public.academy_coaches
      where academy_id = p_academy and user_id = v_coach and accepted_at is not null) then
    raise exception 'Pick one of the academy''s coaches.';
  end if;
  if coalesce(cardinality(v_days), 0) = 0 then raise exception 'Pick at least one day.'; end if;
  if v_id is not null then
    select coach_id into v_was from public.academy_classes where id = v_id and academy_id = p_academy for update;
    if not found then raise exception 'This class isn''t in your academy.'; end if;
  end if;
  if v_coach is not null and v_coach is distinct from v_was and not private.licence_current(v_coach) then
    raise exception 'We need to verify that coach''s licence first. Save the class without a coach for now.';
  end if;
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
  end if;
  return v_id;
end;
$$;

-- Closes the academy and tells every parent. Rows stay: a child's record and
-- any money outlive it.
create or replace function public.academy_close(p_academy uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes the academy.
declare
  v uuid;
  v_name text;
begin
  perform public.academy_require_head(p_academy);
  update public.academies set closed_at = now() where id = p_academy and closed_at is null
  returning name into v_name;
  for v in select distinct parent_id from public.academy_students where academy_id = p_academy loop
    perform public.notify(v, v_name || ' has closed',
      'Its classes have stopped. Contact the academy about any fees you paid.', '!', null);
  end loop;
end;
$$;

-- ─── Staff ─────────────────────────────────────────────────────────────────

create function public.staff_verification_list() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: staff read what clients can't. Waiting first, then anything with a file left.
begin
  perform private.staff_require('content');
  return jsonb_build_object(
    'academies', (select coalesce(jsonb_agg(jsonb_build_object('id', a.id, 'name', a.name, 'sport', a.sport,
        'uen', a.uen, 'verification', a.verification, 'file_path', a.licence_path,
        'rejected_reason', a.rejected_reason,
        'payout_ready', exists (select 1 from public.vendors v where v.owner_id = a.owner_id and v.status = 'verified'),
        'head_licensed', exists (select 1 from public.academy_coaches k where k.academy_id = a.id and k.head
          and private.licence_current(k.user_id)))
        order by a.verification <> 'submitted', a.created_at), '[]')
      from public.academies a
      where a.closed_at is null and (a.verification <> 'none' or a.licence_path is not null)),
    'licences', (select coalesce(jsonb_agg(jsonb_build_object('user_id', l.user_id,
        'name', public.academy_user_name(l.user_id), 'nroc_number', l.nroc_number,
        'expires_on', l.expires_on, 'status', l.status, 'file_path', l.file_path)
        order by l.status <> 'submitted', l.updated_at), '[]')
      from public.coach_licences l));
end;
$$;

create function public.staff_academy_decide(p_academy uuid, p_approve boolean, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: verification is only ever written here.
declare
  a public.academies;
begin
  perform private.staff_require('content');
  select * into a from public.academies where id = p_academy for update;
  if a.id is null then raise exception 'Not found.' using errcode = 'P0001'; end if;
  if a.verification not in ('submitted', 'verified') then raise exception 'There''s nothing to review.'; end if;
  if coalesce(trim(p_reason), '') = '' then raise exception 'Give a reason.'; end if;
  if p_approve then
    if a.uen is null then raise exception 'This academy has no UEN.'; end if;
    if not exists (select 1 from public.academy_coaches k where k.academy_id = a.id and k.head
        and private.licence_current(k.user_id)) then
      raise exception 'The head coach''s licence isn''t verified yet.';
    end if;
    if not exists (select 1 from public.vendors v where v.owner_id = a.owner_id and v.status = 'verified') then
      raise exception 'The owner''s payout account isn''t verified yet.';
    end if;
  end if;
  update public.academies
  set verification = case when p_approve then 'verified' else 'rejected' end,
      rejected_reason = case when p_approve then null else left(p_reason, 300) end,
      reviewed_at = now()
  where id = a.id;
  perform public.notify(a.owner_id,
    case when p_approve then a.name || ' is verified' else 'We need more for ' || a.name end,
    case when p_approve then 'Parents can find it now.' else left(p_reason, 200) end,
    case when p_approve then '✓' else '!' end, '/academies/' || a.id || '/verify');
  perform private.staff_audit('academy_verification', 'academy', a.id::text, p_reason,
    jsonb_build_object('approved', p_approve));
end;
$$;

create function public.staff_licence_decide(p_user uuid, p_approve boolean, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: licence status is only ever written here.
declare
  l public.coach_licences;
begin
  perform private.staff_require('content');
  select * into l from public.coach_licences where user_id = p_user for update;
  if l.user_id is null then raise exception 'Not found.' using errcode = 'P0001'; end if;
  if coalesce(trim(p_reason), '') = '' then raise exception 'Give a reason.'; end if;
  if p_approve and l.expires_on <= (now() at time zone 'Asia/Singapore')::date then
    raise exception 'This licence has expired.';
  end if;
  update public.coach_licences
  set status = case when p_approve then 'verified' else 'rejected' end,
      verified_at = case when p_approve then coalesce(verified_at, now()) else verified_at end,
      rejected_reason = case when p_approve then null else left(p_reason, 300) end,
      reviewed_by = auth.uid(), reviewed_at = now(), updated_at = now()
  where user_id = p_user;
  perform public.notify(p_user,
    case when p_approve then 'Your coaching licence is verified' else 'We couldn''t verify your licence' end,
    case when p_approve then 'You can take classes now.' else left(p_reason, 200) end,
    case when p_approve then '✓' else '!' end, '/academies');
  perform private.staff_audit('licence_verification', 'user', p_user::text, p_reason,
    jsonb_build_object('approved', p_approve));
end;
$$;

-- The admin app deletes the file from storage, then clears the path here.
create function public.staff_doc_removed(p_kind text, p_id uuid, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes the path staff have just deleted.
begin
  perform private.staff_require('content');
  if p_kind = 'academy' then
    update public.academies set licence_path = null where id = p_id;
  elsif p_kind = 'licence' then
    update public.coach_licences set file_path = null where user_id = p_id;
  else
    raise exception 'Not found.' using errcode = 'P0001';
  end if;
  perform private.staff_audit('verification_file_deleted', p_kind, p_id::text, p_reason);
end;
$$;

do $$
declare
  f text;
begin
  foreach f in array array[
    'academy_coach_answer(uuid, boolean)', 'academy_my_coach_invites()',
    'coach_profile_save(text, text, integer)', 'coach_profile_get(uuid)', 'coach_licence_my()',
    'coach_licence_submit(text, date, text)', 'academy_submit_business(uuid, text, text)',
    'academy_verification(uuid)', 'academy_my_players()',
    'academy_request(uuid, uuid, text, timestamptz)', 'staff_verification_list()',
    'staff_academy_decide(uuid, boolean, text)', 'staff_licence_decide(uuid, boolean, text)',
    'staff_doc_removed(text, uuid, text)']
  loop
    execute format('revoke execute on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end;
$$;
