-- Prepared against the development schema inspected on 2026-11-01.
-- This migration preserves the existing auth -> profiles -> mental trigger chain.
begin;

create or replace function public.handle_new_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.mental_health_records (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  insert into public.physical_health_records (user_id, kind, device_id, payload)
  values (
    new.id,
    'physical',
    '',
    jsonb_build_object(
      'heightCm', null,
      'weightKg', null,
      'waterMl', 0,
      'waterDate', to_char(current_date, 'YYYY-MM-DD')
    )
  )
  on conflict (user_id, kind, device_id) do nothing;

  return new;
end;
$$;

commit;
