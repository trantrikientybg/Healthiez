-- Run after the profile measurement migration. All fixtures are rolled back.
begin;
insert into auth.users (id, email, raw_user_meta_data) values
  ('d9817703-e768-4e96-8908-394b562aacf2', 'profile-physical-a@example.invalid', '{}'),
  ('d9817703-e768-4e96-8908-394b562aacf3', 'profile-physical-b@example.invalid', '{}');

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"d9817703-e768-4e96-8908-394b562aacf2","role":"authenticated"}', true);
select public.save_physical_health(
  '{"heightCm":170.5,"weightKg":65.5,"waterMl":250,"waterDate":"2026-11-01"}', true);
do $$ begin
  if (select height from public.profiles where id = auth.uid()) <> 170.5
    or (select weight from public.profiles where id = auth.uid()) <> 65.5 then
    raise exception 'Decimal measurements did not persist in profile';
  end if;
  if (public.read_physical_health()->>'heightCm')::numeric <> 170.5 then
    raise exception 'Physical read did not use profile measurements';
  end if;
  if (select count(*) from public.profiles) <> 1 then
    raise exception 'Profile reads are not owner-only';
  end if;
  begin
    perform public.save_physical_health(
      '{"heightCm":180.5,"weightKg":70.5,"waterMl":-1,"waterDate":"2026-11-01"}', true);
    raise exception 'Invalid water accepted';
  exception when check_violation then null;
  end;
  if (select height from public.profiles where id = auth.uid()) <> 170.5 then
    raise exception 'Failed water write partially saved measurements';
  end if;
end $$;

update public.profiles set weight = 66.5 where id = auth.uid();
select public.save_physical_health(
  '{"heightCm":170.5,"weightKg":65.5,"waterMl":500,"waterDate":"2026-11-01"}', false);
do $$ begin
  if (public.read_physical_health()->>'weightKg')::numeric <> 66.5 then
    raise exception 'Water save overwrote externally edited profile weight';
  end if;
  if (public.read_physical_health()->>'waterMl')::integer <> 500 then
    raise exception 'Water save failed';
  end if;
end $$;

select set_config('request.jwt.claims',
  '{"sub":"d9817703-e768-4e96-8908-394b562aacf3","role":"authenticated"}', true);
do $$ begin
  if exists (select 1 from public.profiles
      where id = 'd9817703-e768-4e96-8908-394b562aacf2') then
    raise exception 'Other account can read measurements';
  end if;
  update public.profiles set weight = 100
    where id = 'd9817703-e768-4e96-8908-394b562aacf2';
  if found then raise exception 'Other account can modify measurements'; end if;
  if (public.read_physical_health()->>'waterMl')::integer <> 0 then
    raise exception 'RPC leaked other account water';
  end if;
end $$;

set local role anon;
select set_config('request.jwt.claims', '{"role":"anon"}', true);
do $$ begin
  begin
    if exists (select 1 from public.profiles) then
      raise exception 'Anonymous profile read allowed';
    end if;
  exception when insufficient_privilege then null; end;
  begin
    perform public.read_physical_health();
    raise exception 'Anonymous physical RPC allowed';
  exception when insufficient_privilege then null; end;
end $$;
reset role;
select 'Decimal profile storage, atomic saves, water isolation and owner-only reads passed' as result;
rollback;
