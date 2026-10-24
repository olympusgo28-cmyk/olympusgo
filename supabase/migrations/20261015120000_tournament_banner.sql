-- Tournaments must carry a banner title. NOT VALID keeps tournaments made
-- before this rule; every new or edited tournament has to follow it.
alter table public.activities
  add constraint activities_tournament_banner
  check (kind <> 'tournament' or char_length(trim(cover_title)) > 0) not valid;
