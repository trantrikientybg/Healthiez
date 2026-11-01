-- Run after 20261101_seed_physical_on_profile.sql. Fixtures are rolled back.
begin;

insert into auth.users (id, email, raw_user_meta_data)
values ('d9817703-e768-4e96-8908-394b562aacf1',
        'signup-physical-test@example.invalid', '{"username":"physical-fixture"}');

do $$
declare
  fixture_id constant uuid := 'd9817703-e768-4e96-8908-394b562aacf1';
  record jsonb;
begin
  if not exists (select 1 from public.profiles where id = fixture_id
      and username = 'physical-fixture') then
    raise exception 'Signup did not preserve profile creation';
  end if;
  if not exists (select 1 from public.mental_health_records where user_id = fixture_id) then
    raise exception 'Signup did not preserve mental record creation';
  end if;
  select payload into strict record from public.physical_health_records
    where user_id = fixture_id and kind = 'physical' and device_id = '';
  if record <> jsonb_build_object('heightCm', null, 'weightKg', null,
      'waterMl', 0, 'waterDate', to_char(current_date, 'YYYY-MM-DD')) then
    raise exception 'Signup created an invalid physical seed';
  end if;
  if exists (select 1 from public.physical_health_records
      where user_id = fixture_id and kind = 'steps') then
    raise exception 'Signup must not create device sensor baselines';
  end if;
end;
$$;

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"d9817703-e768-4e96-8908-394b562aacf1","role":"authenticated"}', true);
do $$ begin
  if (select count(*) from public.physical_health_records) <> 1 then
    raise exception 'New user cannot read own seed or can read another account';
  end if;
  update public.physical_health_records
    set payload = jsonb_set(payload, '{waterMl}', '250') where kind = 'physical';
  if not found then raise exception 'New user cannot save water'; end if;
end $$;
reset role;

select 'Signup profile, mental, physical seed and first water save passed' as result;
rollback;
