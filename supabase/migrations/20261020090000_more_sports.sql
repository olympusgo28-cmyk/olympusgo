-- The app offers squash and Hyrox as Passport sports too.
alter table public.player_sports drop constraint player_sports_sport_check;
alter table public.player_sports add constraint player_sports_sport_check check (sport in (
  'badminton', 'pickleball', 'tennis', 'padel', 'table_tennis',
  'basketball', 'football', 'running', 'swimming', 'cycling',
  'squash', 'hyrox'
));
