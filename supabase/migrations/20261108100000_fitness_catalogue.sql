-- P5-04: the starter exercises and three templates. A coach reviews these before
-- launch (Q168, Q169). Only bodyweight and band work is cleared for under-18s.

insert into public.exercises
  (slug, name, mark, muscle_group, muscles, equipment, steps, tip, unit, weighted, minors_ok, sort)
values
  -- Legs
  ('back-squat', 'Back squat', 'SQ', 'legs', '{Quads,Glutes,Core}', 'Barbell',
    '{"Bar on your upper back, feet shoulder-width apart","Sit back and down until thighs are level with the floor","Keep your chest up and knees over your toes","Drive up through your heels"}',
    'Good for badminton: stronger lunges and a quicker push back to base.', 'reps', true, false, 10),
  ('goblet-squat', 'Goblet squat', 'GS', 'legs', '{Quads,Glutes}', 'Dumbbell',
    '{"Hold one dumbbell at your chest","Feet shoulder-width apart","Sit down between your knees","Stand up tall"}',
    '', 'reps', true, false, 20),
  ('bodyweight-squat', 'Bodyweight squat', 'BS', 'legs', '{Quads,Glutes}', 'Bodyweight',
    '{"Feet shoulder-width apart","Sit back and down","Keep your heels on the floor","Stand up tall"}',
    '', 'reps', false, true, 30),
  ('walking-lunge', 'Walking lunge', 'LU', 'legs', '{Quads,Glutes}', 'Dumbbells',
    '{"Hold a dumbbell in each hand","Step forward and lower your back knee","Push through your front heel","Step through into the next lunge"}',
    'Good for badminton: the same movement as reaching for a net shot.', 'reps', true, false, 40),
  ('forward-lunge', 'Forward lunge', 'FL', 'legs', '{Quads,Glutes}', 'Bodyweight',
    '{"Stand tall with hands on your hips","Step forward and lower your back knee","Push back to the start","Swap legs"}',
    'Good for badminton: the same movement as reaching for a net shot.', 'reps', false, true, 50),
  ('side-lunge', 'Side lunge', 'SL', 'legs', '{Quads,Glutes,Inner thighs}', 'Bodyweight',
    '{"Stand with your feet together","Step wide to one side","Sit back into that hip","Push back to the start"}',
    'Good for badminton: helps with wide reaches on the forecourt.', 'reps', false, true, 60),
  ('romanian-deadlift', 'Romanian deadlift', 'RD', 'legs', '{Hamstrings,Glutes}', 'Barbell',
    '{"Hold the bar at your thighs","Push your hips back with a soft knee bend","Lower the bar along your legs","Stand by squeezing your glutes"}',
    '', 'reps', true, false, 70),
  ('glute-bridge', 'Glute bridge', 'GB', 'legs', '{Glutes,Hamstrings}', 'Bodyweight',
    '{"Lie on your back with knees bent","Feet flat on the floor","Lift your hips until your body is straight","Lower slowly"}',
    '', 'reps', false, true, 80),
  ('step-up', 'Step-up', 'SU', 'legs', '{Quads,Glutes}', 'Bench or box',
    '{"Stand facing a low, steady box","Step up with one foot","Stand tall on top","Step down slowly and swap legs"}',
    '', 'reps', false, true, 90),
  ('calf-raise', 'Calf raise', 'CR', 'legs', '{Calves}', 'Bodyweight',
    '{"Stand with feet hip-width apart","Rise onto your toes","Pause at the top","Lower slowly"}',
    'Good for badminton: springier first steps.', 'reps', false, true, 100),
  ('split-step-jump', 'Split-step jump', 'SJ', 'legs', '{Calves,Quads}', 'Bodyweight',
    '{"Stand in your ready position","Make a small hop","Land softly on both feet, a little wider","Hop again as soon as you land"}',
    'Good for badminton: the small hop before every first step.', 'reps', false, true, 110),
  ('lateral-shuffle', 'Lateral shuffle', 'LS', 'legs', '{Quads,Calves}', 'Bodyweight',
    '{"Stand low with your feet apart","Shuffle sideways without crossing your feet","Stay low the whole way","Change direction at each end"}',
    'Good for badminton: quicker moves across the midcourt.', 'seconds', false, true, 120),
  ('wall-sit', 'Wall sit', 'WS', 'legs', '{Quads}', 'Bodyweight',
    '{"Lean your back against a wall","Slide down until thighs are level with the floor","Keep your knees over your ankles","Hold"}',
    '', 'seconds', false, true, 130),
  ('leg-press', 'Leg press', 'LP', 'legs', '{Quads,Glutes}', 'Machine',
    '{"Sit with your back flat on the pad","Feet shoulder-width apart on the plate","Lower until your knees are bent","Press without locking your knees"}',
    '', 'reps', true, false, 140),
  -- Core
  ('plank', 'Plank', 'PL', 'core', '{Core}', 'Bodyweight',
    '{"Forearms on the floor, elbows under shoulders","Straight line from head to heels","Tuck your hips slightly","Hold and keep breathing"}',
    '', 'seconds', false, true, 210),
  ('side-plank', 'Side plank', 'SP', 'core', '{Obliques,Core}', 'Bodyweight',
    '{"Lie on your side, elbow under your shoulder","Lift your hips until your body is straight","Hold","Swap sides"}',
    '', 'seconds', false, true, 220),
  ('russian-twist', 'Russian twist', 'RT', 'core', '{Obliques}', 'Medicine ball',
    '{"Sit with your knees bent and lean back slightly","Hold the ball at your chest","Turn from side to side","Keep your chest up"}',
    'Good for badminton: more turn through your smash.', 'reps', true, false, 230),
  ('dead-bug', 'Dead bug', 'DB', 'core', '{Core}', 'Bodyweight',
    '{"Lie on your back, arms up, knees over hips","Lower one arm and the opposite leg","Keep your back flat","Return and swap sides"}',
    '', 'reps', false, true, 240),
  ('bird-dog', 'Bird dog', 'BD', 'core', '{Core,Lower back}', 'Bodyweight',
    '{"Start on your hands and knees","Reach one arm forward and the opposite leg back","Pause without tipping","Return and swap sides"}',
    '', 'reps', false, true, 250),
  ('mountain-climber', 'Mountain climber', 'MC', 'core', '{Core,Shoulders}', 'Bodyweight',
    '{"Start at the top of a push-up","Drive one knee towards your chest","Swap legs quickly","Keep your hips low"}',
    '', 'seconds', false, true, 260),
  ('hollow-hold', 'Hollow hold', 'HH', 'core', '{Core}', 'Bodyweight',
    '{"Lie on your back","Press your lower back into the floor","Lift your shoulders and legs a little","Hold"}',
    '', 'seconds', false, true, 270),
  ('crunch', 'Crunch', 'CC', 'core', '{Core}', 'Bodyweight',
    '{"Lie on your back with knees bent","Hands beside your head","Curl your shoulders off the floor","Lower slowly"}',
    '', 'reps', false, true, 280),
  ('reverse-crunch', 'Reverse crunch', 'RC', 'core', '{Core}', 'Bodyweight',
    '{"Lie on your back with knees bent","Curl your hips off the floor","Pause","Lower slowly"}',
    '', 'reps', false, true, 290),
  ('hanging-knee-raise', 'Hanging knee raise', 'HK', 'core', '{Core}', 'Bar',
    '{"Hang from a bar","Lift your knees towards your chest","Pause","Lower without swinging"}',
    '', 'reps', false, false, 300),
  ('cable-woodchop', 'Cable woodchop', 'CW', 'core', '{Obliques,Shoulders}', 'Cable machine',
    '{"Stand side-on to the machine","Hold the handle with both hands","Pull across your body as you turn","Return slowly"}',
    'Good for badminton: more turn through your smash.', 'reps', true, false, 310),
  ('farmer-carry', 'Farmer carry', 'FC', 'core', '{Core,Forearms}', 'Dumbbells',
    '{"Hold a heavy dumbbell in each hand","Stand tall","Walk with short, steady steps","Put the weights down with care"}',
    '', 'seconds', true, false, 320),
  -- Upper
  ('push-up', 'Push-up', 'PU', 'upper', '{Chest,Shoulders,Triceps}', 'Bodyweight',
    '{"Hands under your shoulders","Straight line from head to heels","Lower your chest to the floor","Press back up"}',
    '', 'reps', false, true, 410),
  ('incline-push-up', 'Incline push-up', 'IP', 'upper', '{Chest,Shoulders}', 'Bench or box',
    '{"Hands on a low, steady bench","Straight line from head to heels","Lower your chest to the bench","Press back up"}',
    '', 'reps', false, true, 420),
  ('pull-up', 'Pull-up', 'UP', 'upper', '{Back,Biceps}', 'Bar',
    '{"Hang from the bar with hands apart","Pull until your chin passes the bar","Lower slowly","Don''t swing"}',
    '', 'reps', false, false, 430),
  ('band-row', 'Band row', 'BR', 'upper', '{Back,Biceps}', 'Band',
    '{"Fix the band in front of you","Pull your hands to your ribs","Squeeze your shoulder blades","Return slowly"}',
    '', 'reps', false, true, 440),
  ('dumbbell-row', 'Dumbbell row', 'DR', 'upper', '{Back,Biceps}', 'Dumbbell',
    '{"One hand and knee on a bench","Pull the dumbbell to your hip","Pause","Lower slowly"}',
    '', 'reps', true, false, 450),
  ('overhead-press', 'Overhead press', 'OH', 'upper', '{Shoulders,Triceps}', 'Barbell',
    '{"Hold the bar at your collarbones","Press straight overhead","Keep your ribs down","Lower slowly"}',
    '', 'reps', true, false, 460),
  ('bench-press', 'Bench press', 'BP', 'upper', '{Chest,Shoulders,Triceps}', 'Barbell',
    '{"Lie on the bench with feet flat","Lower the bar to your chest","Press up","Use a spotter for heavy sets"}',
    '', 'reps', true, false, 470),
  ('dumbbell-curl', 'Dumbbell curl', 'DC', 'upper', '{Biceps}', 'Dumbbells',
    '{"Stand with a dumbbell in each hand","Curl up without swinging","Pause","Lower slowly"}',
    '', 'reps', true, false, 480),
  ('tricep-dip', 'Tricep dip', 'TD', 'upper', '{Triceps,Shoulders}', 'Bench or box',
    '{"Hands on a steady bench behind you","Bend your elbows to lower","Keep your shoulders down","Press back up"}',
    '', 'reps', false, false, 490),
  ('rotator-cuff-rotation', 'Rotator cuff external rotation', 'RE', 'upper', '{Shoulders}', 'Band',
    '{"Hold the band with your elbow at your side","Bend your elbow to a right angle","Turn your forearm outwards","Return slowly"}',
    '', 'reps', false, true, 500),
  ('band-pull-apart', 'Band pull-apart', 'BA', 'upper', '{Shoulders,Back}', 'Band',
    '{"Hold the band at chest height, arms straight","Pull your hands apart","Squeeze your shoulder blades","Return slowly"}',
    '', 'reps', false, true, 510),
  ('wrist-curl', 'Wrist curl', 'WC', 'upper', '{Forearms}', 'Dumbbell',
    '{"Rest your forearm on your thigh","Hold a light dumbbell","Curl your wrist up","Lower slowly"}',
    'Good for badminton: firmer grip on the racket.', 'reps', true, false, 520),
  ('face-pull', 'Face pull', 'FP', 'upper', '{Shoulders,Back}', 'Band',
    '{"Fix the band at head height","Pull your hands towards your face","Elbows high and wide","Return slowly"}',
    '', 'reps', false, true, 530),
  ('shoulder-tap', 'Shoulder tap', 'ST', 'upper', '{Shoulders,Core}', 'Bodyweight',
    '{"Start at the top of a push-up","Tap one shoulder","Keep your hips still","Swap hands"}',
    '', 'reps', false, true, 540);

update public.exercises set safety = 'Stop if you feel pain.';
update public.exercises set safety = 'Stop if you feel pain in your knees or lower back.'
where slug in ('back-squat', 'goblet-squat', 'romanian-deadlift', 'leg-press');

do $$
declare
  v_templates jsonb := $json$[
    {"name": "Court speed", "days": [
      {"name": "Footwork", "items": [
        ["split-step-jump", 3, 12, null, 60], ["lateral-shuffle", 3, null, 30, 60],
        ["forward-lunge", 3, 12, null, 60], ["side-lunge", 3, 10, null, 60], ["calf-raise", 3, 15, null, 45]]},
      {"name": "Legs and core", "items": [
        ["bodyweight-squat", 3, 15, null, 60], ["step-up", 3, 10, null, 60], ["wall-sit", 3, null, 30, 60],
        ["plank", 3, null, 45, 60], ["side-plank", 2, null, 30, 45]]}]},
    {"name": "Mobility and balance", "days": [
      {"name": "Upper body", "items": [
        ["rotator-cuff-rotation", 3, 12, null, 45], ["band-pull-apart", 3, 12, null, 45],
        ["face-pull", 3, 12, null, 45], ["shoulder-tap", 3, 12, null, 45]]},
      {"name": "Lower body", "items": [
        ["glute-bridge", 3, 12, null, 45], ["bird-dog", 3, 10, null, 45], ["dead-bug", 3, 10, null, 45],
        ["side-lunge", 3, 10, null, 45]]}]},
    {"name": "Off-season strength", "days": [
      {"name": "Legs", "items": [
        ["back-squat", 4, 5, null, 120], ["romanian-deadlift", 3, 8, null, 120],
        ["walking-lunge", 3, 12, null, 90], ["calf-raise", 3, 15, null, 60]]},
      {"name": "Upper body", "items": [
        ["bench-press", 4, 5, null, 120], ["dumbbell-row", 3, 8, null, 90],
        ["overhead-press", 3, 8, null, 90], ["face-pull", 3, 12, null, 60]]},
      {"name": "Core", "items": [
        ["plank", 3, null, 45, 60], ["russian-twist", 3, 20, null, 60],
        ["hanging-knee-raise", 3, 10, null, 60], ["farmer-carry", 3, null, 40, 60]]}]}
  ]$json$;
  v_t jsonb;
  v_day jsonb;
  v_item jsonb;
  v_program uuid;
  v_day_id uuid;
  v_d int;
  v_i int;
begin
  for v_t in select * from jsonb_array_elements(v_templates) loop
    insert into public.programs (name) values (v_t ->> 'name') returning id into v_program;
    v_d := 0;
    for v_day in select * from jsonb_array_elements(v_t -> 'days') loop
      v_d := v_d + 1;
      insert into public.program_days (program_id, position, name)
      values (v_program, v_d, v_day ->> 'name') returning id into v_day_id;
      v_i := 0;
      for v_item in select * from jsonb_array_elements(v_day -> 'items') loop
        v_i := v_i + 1;
        insert into public.program_items (day_id, exercise_id, position, sets, reps, seconds, rest_seconds)
        select v_day_id, e.id, v_i, (v_item ->> 1)::int, (v_item ->> 2)::int, (v_item ->> 3)::int, (v_item ->> 4)::int
        from public.exercises e where e.slug = v_item ->> 0;
        if not found then raise exception 'No exercise %', v_item ->> 0; end if;
      end loop;
    end loop;
  end loop;
end;
$$;
