-- P5-06: a hash match opens a case nobody reported, which left its reasons null
-- and took down the staff list.
do $$
declare
  n text := 'public.staff_case_list()';
  d text := pg_get_functiondef(n::regprocedure);
  fixed text := replace(d,
    $a$'reasons', (select jsonb_agg(distinct r.reason) from public.case_reports r where r.case_id = c.id))$a$,
    $a$'reasons', (select coalesce(jsonb_agg(distinct r.reason), '[]'::jsonb) from public.case_reports r where r.case_id = c.id))$a$);
begin
  if fixed = d then raise exception 'staff_case_list did not change'; end if;
  execute fixed;
end;
$$;
