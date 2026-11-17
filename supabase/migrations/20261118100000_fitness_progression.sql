-- Q277, slice 3: progression suggestions on the workout screen (owner,
-- 17 Nov 2026). The app suggests the next weight, reps or time from the
-- player's own history. It is a suggestion: nothing is applied without a tap,
-- and it earns nothing (R-FIT-4, R-FIT-11).
--
-- The numbers are config, so they can change without a new app. They ride on
-- exercise_history, which the workout screen already calls. Under-18s get
-- none from it, so the app shows them no suggestion (Q277 d). The numbers are
-- not secret (app_settings is readable); this decides what the app shows.

insert into public.app_settings (key, value, description) values
  ('fitness.progress_step_g', '2500', 'Weight to add when every set hit its reps, in grams (Q277 c)'),
  ('fitness.progress_stall_sessions', '3', 'Sessions in a row of missed reps before suggesting less weight (Q277 c)'),
  ('fitness.progress_deload_pct', '10', 'How much less weight to suggest after those sessions, in percent (Q277 c)'),
  ('fitness.progress_rep_step', '1', 'Reps to add when every set hit its reps, with no weight (Q277 c)'),
  ('fitness.progress_rep_cap', '20', 'Reps a suggestion never goes past (Q277 c)'),
  ('fitness.progress_seconds_step', '5', 'Seconds to add when every set held its time (Q277 c)'),
  ('fitness.progress_seconds_cap', '120', 'Seconds a suggestion never goes past (Q277 c)');

-- The caller's best set, times done and last 30 sets, as before, plus the
-- progression numbers for an adult. Same grants and rate limit as before.
create or replace function public.exercise_history(p_exercise uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: returns the caller's own sets, to nobody else.
declare
  v_user uuid := auth.uid();
  v_minor boolean := private.fitness_gate();
  v_progress jsonb;
begin
  -- Under-18s get no suggestions (Q277 d). The numbers are simply not sent.
  if not v_minor then
    -- A missing or unreadable number means no suggestions, never a failed
    -- history: "last time" must keep working whatever the config holds.
    begin
      v_progress := jsonb_build_object(
        'step_g', private.setting_int_or_null('fitness.progress_step_g'),
        'stall_sessions', private.setting_int_or_null('fitness.progress_stall_sessions'),
        'deload_pct', private.setting_int_or_null('fitness.progress_deload_pct'),
        'rep_step', private.setting_int_or_null('fitness.progress_rep_step'),
        'rep_cap', private.setting_int_or_null('fitness.progress_rep_cap'),
        'seconds_step', private.setting_int_or_null('fitness.progress_seconds_step'),
        'seconds_cap', private.setting_int_or_null('fitness.progress_seconds_cap'));
      -- Every number must be there and inside what a set can hold (500 kg,
      -- 200 reps, 3,600 seconds, the 30 sets the history keeps), so a typo
      -- in config can't turn into a wild suggestion.
      if exists (select 1 from jsonb_each(v_progress) e where e.value = 'null'::jsonb)
          or (v_progress ->> 'step_g')::int not between 1 and 500000
          or (v_progress ->> 'stall_sessions')::int not between 1 and 30
          or (v_progress ->> 'deload_pct')::int not between 1 and 99
          or (v_progress ->> 'rep_step')::int not between 1 and 200
          or (v_progress ->> 'rep_cap')::int not between 1 and 200
          or (v_progress ->> 'seconds_step')::int not between 1 and 3600
          or (v_progress ->> 'seconds_cap')::int not between 1 and 3600 then
        v_progress := null;
      end if;
    -- A setting that is not a whole number. Anything else is a real fault and
    -- is not hidden.
    exception when data_exception then
      v_progress := null;
    end;
  end if;
  return (with mine as (
      select s.reps, s.seconds, s.weight_g, w.started_at, w.id as workout_id, s.position
      from public.workout_sets s join public.workouts w on w.id = s.workout_id
      where w.user_id = v_user and s.exercise_id = p_exercise
    )
    select jsonb_build_object(
      'times', (select count(distinct m.workout_id) from mine m),
      'best', (select to_jsonb(b) from (select m.reps, m.seconds, m.weight_g, m.started_at as at from mine m
        order by m.weight_g desc nulls last, m.reps desc nulls last, m.seconds desc nulls last, m.started_at
        limit 1) b),
      'recent', (select coalesce(jsonb_agg(jsonb_build_object('reps', r.reps, 'seconds', r.seconds,
          'weight_g', r.weight_g, 'at', r.started_at) order by r.started_at desc, r.position desc), '[]')
        from (select * from mine m order by m.started_at desc, m.position desc limit 30) r),
      'progress', v_progress));
end;
$$;
