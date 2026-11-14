-- Audit of 10 Nov 2026, finding S1 (Q267): a player could set
-- profiles.avatar_url to any address, and the app sent each viewer's session
-- token to it. A photo address is now only ever the owner's own file in the
-- avatars bucket, stored without a host, so nothing a player writes here can
-- point anywhere else. The app builds the full address from its own project
-- URL.

-- ─── 1. Existing values ────────────────────────────────────────────────────

-- The app used to store the full public URL. Keep the path.
update public.profiles
set avatar_url = regexp_replace(avatar_url, '^https?://[^/]+', '')
where avatar_url ~ '^https?://';

-- Anything that still isn't the owner's own file was never a photo of ours.
update public.profiles
set avatar_url = null
where avatar_url is not null
  and avatar_url !~ ('^/storage/v1/object/public/avatars/' || id::text
    || '/avatar\.(jpeg|png)(\?v=[0-9]{1,15})?$');

-- ─── 2. The rule ───────────────────────────────────────────────────────────

-- A constraint, not a policy, so it binds definer functions and staff tools
-- too. Anchored at both ends: no host, no other folder, no trailing text.
alter table public.profiles add constraint profiles_avatar_own_file check (
  avatar_url is null
  or avatar_url ~ ('^/storage/v1/object/public/avatars/' || id::text
    || '/avatar\.(jpeg|png)(\?v=[0-9]{1,15})?$')
);

comment on column public.profiles.avatar_url is
  'The owner''s own file in the avatars bucket, as a path with no host: '
  '/storage/v1/object/public/avatars/<id>/avatar.(jpeg|png)[?v=n]. Never an '
  'address a client may be sent to with a session token (Q267).';
