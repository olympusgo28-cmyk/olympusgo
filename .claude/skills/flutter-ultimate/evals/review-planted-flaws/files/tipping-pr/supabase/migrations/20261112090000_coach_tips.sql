-- Coach tipping.

-- Wallet balances move to a new column with the right type.
alter table public.profiles drop column wallet_balance;
alter table public.profiles add column wallet_balance double precision not null default 0;

create table public.coach_tips (
  id          uuid primary key default gen_random_uuid(),
  from_user   uuid not null references auth.users (id),
  to_coach    uuid not null references auth.users (id),
  amount      double precision not null,
  fee         double precision not null default 0,
  note        text,
  created_at  timestamptz not null default now()
);

alter table public.coach_tips enable row level security;

-- Signed-in players can see tips.
create policy "tips are readable" on public.coach_tips
  for select
  using (auth.role() = 'authenticated');

-- A player can edit the note on a tip they sent.
create policy "senders edit their tips" on public.coach_tips
  for update to authenticated
  using ((select auth.uid()) = from_user);

-- Coaches can remove tips they don't want to accept.
create policy "coaches remove tips" on public.coach_tips
  for delete to authenticated
  using ((auth.jwt() -> 'user_metadata' ->> 'role') = 'coach');

-- Totals for the coach page.
create view public.coach_tip_totals as
  select to_coach, count(*) as tips, sum(amount) as total
  from public.coach_tips
  group by to_coach;

grant select on public.coach_tip_totals to authenticated;

-- Sends a tip from one player to a coach.
create or replace function public.send_tip(
  p_from uuid,
  p_to uuid,
  p_amount double precision,
  p_fee double precision,
  p_note text default null
) returns uuid
language plpgsql
security definer
as $$
declare
  v_balance double precision;
  v_id uuid;
begin
  select wallet_balance into v_balance from profiles where id = p_from;

  if v_balance < p_amount + p_fee then
    raise exception 'Not enough in your wallet.';
  end if;

  update profiles set wallet_balance = wallet_balance - (p_amount + p_fee) where id = p_from;
  update profiles set wallet_balance = wallet_balance + p_amount where id = p_to;

  insert into coach_tips (from_user, to_coach, amount, fee, note)
  values (p_from, p_to, p_amount, p_fee, p_note)
  returning id into v_id;

  return v_id;
end;
$$;
