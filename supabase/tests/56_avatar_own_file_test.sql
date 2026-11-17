-- Q267 (audit S1): a photo address is only ever the owner's own file in the
-- avatars bucket, stored without a host. Nothing a player writes can send
-- another player's app, and its session token, anywhere else.
begin;
\ir helpers/setup.psql
select no_plan();

select t.player('e6000000-0000-0000-0000-000000000001');  -- the player
select t.player('e6000000-0000-0000-0000-000000000002');  -- someone else

create function t.set_avatar(p_value text) returns text language plpgsql as $$
begin
  update public.profiles set avatar_url = p_value where id = (select auth.uid());
  return (select avatar_url from public.profiles where id = (select auth.uid()));
end;
$$;
grant execute on function t.set_avatar(text) to authenticated;

create function t.refused(p_value text, p_what text) returns text language sql as $f$
  select throws_ok(format('select t.set_avatar(%L)', p_value), '23514', null, p_what);
$f$;
grant execute on function t.refused(text, text) to authenticated;

select t.as_user('e6000000-0000-0000-0000-000000000001');

-- ─── What a player may store ───────────────────────────────────────────────

select is(t.set_avatar('/storage/v1/object/public/avatars/e6000000-0000-0000-0000-000000000001/avatar.jpeg'),
  '/storage/v1/object/public/avatars/e6000000-0000-0000-0000-000000000001/avatar.jpeg',
  'their own jpeg');
select is(t.set_avatar('/storage/v1/object/public/avatars/e6000000-0000-0000-0000-000000000001/avatar.png?v=1794400000000'),
  '/storage/v1/object/public/avatars/e6000000-0000-0000-0000-000000000001/avatar.png?v=1794400000000',
  'their own png, with the cache number');
select is(t.set_avatar(null), null, 'no photo');

-- ─── What they may not ─────────────────────────────────────────────────────

select t.refused('https://attacker.example/x.png', 'an outside address is refused');
select t.refused('https://attacker.example/storage/v1/object/public/avatars/e6000000-0000-0000-0000-000000000001/avatar.png',
  'the right path on an outside host is refused');
select t.refused('http://127.0.0.1:54321/storage/v1/object/public/avatars/e6000000-0000-0000-0000-000000000001/avatar.png',
  'so is a full address on our own host: no host is ever stored');
select t.refused('//attacker.example/storage/v1/object/public/avatars/e6000000-0000-0000-0000-000000000001/avatar.png',
  'a protocol-relative address is refused');
select t.refused('/storage/v1/object/public/avatars/e6000000-0000-0000-0000-000000000002/avatar.png',
  'another player''s folder is refused');
select t.refused('/storage/v1/object/public/chat-photos/e6000000-0000-0000-0000-000000000001/avatar.png',
  'another bucket is refused');
select t.refused('/storage/v1/object/public/avatars/e6000000-0000-0000-0000-000000000001/other.png',
  'another file name is refused');
select t.refused('/storage/v1/object/public/avatars/e6000000-0000-0000-0000-000000000001/../e6000000-0000-0000-0000-000000000002/avatar.png',
  'a path that climbs out is refused');
select t.refused('/storage/v1/object/public/avatars/e6000000-0000-0000-0000-000000000001/avatar.png?v=1&next=https://attacker.example',
  'text after the cache number is refused');
select t.refused('/storage/v1/object/public/avatars/e6000000-0000-0000-0000-000000000001/avatar.png#@attacker.example',
  'a fragment is refused');
select t.refused(E'/storage/v1/object/public/avatars/e6000000-0000-0000-0000-000000000001/avatar.png\nhttps://attacker.example',
  'a second line is refused');
select t.refused('/storage/v1/object/public/avatars/e6000000-0000-0000-0000-000000000001/avatar.svg',
  'another file type is refused');
select t.refused('/storage/v1/object/public/avatars/E6000000-0000-0000-0000-000000000001/avatar.png',
  'the id in upper case is refused');
select t.refused(E'/storage/v1/object/public/avatars/e6000000-0000-0000-0000-000000000001/avatar.png\n',
  'a trailing new line is refused');
select t.refused('/storage/v1/object/public/avatars/e6000000-0000-0000-0000-000000000001/avatar.png?v=',
  'an empty cache number is refused');
select t.refused('javascript:alert(1)', 'a script address is refused');
select t.refused('', 'an empty string is refused: no photo is null');

-- Someone else's row is still out of reach (existing RLS).
update public.profiles
set avatar_url = '/storage/v1/object/public/avatars/e6000000-0000-0000-0000-000000000002/avatar.png'
where id = 'e6000000-0000-0000-0000-000000000002';
select t.reset();
select is((select avatar_url from public.profiles where id = 'e6000000-0000-0000-0000-000000000002'),
  null, 'a player cannot set another player''s photo');

-- ─── It binds everyone, not only players ───────────────────────────────────

select throws_ok(
  $$update public.profiles set avatar_url = 'https://attacker.example/x.png'
    where id = 'e6000000-0000-0000-0000-000000000001'$$,
  '23514', null, 'the database owner is refused too, so no definer function can store one');
select is((select count(*)::int from public.profiles
           where avatar_url is not null
             and avatar_url !~ ('^/storage/v1/object/public/avatars/' || id::text
               || '/avatar\.(jpeg|png)(\?v=[0-9]{1,15})?$')),
  0, 'no stored photo address points anywhere else');
select ok((select convalidated from pg_constraint where conname = 'profiles_avatar_own_file'),
  'the constraint is validated against existing rows');

select * from finish();
rollback;
