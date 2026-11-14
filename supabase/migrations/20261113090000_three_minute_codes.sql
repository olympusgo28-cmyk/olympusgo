-- Q248 (owner, 8 Nov 2026): sign-in and contact codes last 3 minutes, and the
-- app offers a new one after 3 minutes (R-ACC-2, R-ACC-3).
update public.app_settings
set value = '3', description = 'How long a sign-in code lasts (R-ACC-2, Q248)'
where key = 'auth.code_minutes';
