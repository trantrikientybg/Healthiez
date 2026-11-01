-- PREPARED ONLY. User approved decimal columns and owner-only profile reads.
-- Auth teammate must change anonymous username lookup before this is deployed.
begin;

drop policy if exists "Public profiles are viewable by everyone." on public.profiles;
-- The inspected remaining SELECT/ALL policies require auth.uid() = id.

alter table public.profiles
  alter column height type numeric using height::numeric,
  alter column weight type numeric using weight::numeric;

-- Preserve profile values already maintained by the team; fill only empty fields.
update public.profiles p
set height = coalesce(p.height, (r.payload->>'heightCm')::numeric),
    weight = coalesce(p.weight, (r.payload->>'weightKg')::numeric)
from public.physical_health_records r
where r.user_id = p.id and r.kind = 'physical' and r.device_id = ''
  and (p.height is null or p.weight is null);

create or replace function public.read_physical_health()
returns jsonb
language plpgsql stable security invoker set search_path = ''
as $$
declare
  profile public.profiles%rowtype;
  data jsonb;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select * into profile from public.profiles where id = auth.uid();
  select payload into data from public.physical_health_records
    where user_id = auth.uid() and kind = 'physical' and device_id = '';
  return jsonb_build_object(
    'heightCm', case when profile.height is not null and profile.weight is not null then profile.height end,
    'weightKg', case when profile.height is not null and profile.weight is not null then profile.weight end,
    'waterMl', coalesce(data->'waterMl', '0'::jsonb),
    'waterDate', coalesce(data->>'waterDate', to_char(current_date, 'YYYY-MM-DD'))
  );
end;
$$;

create or replace function public.save_physical_health(p_payload jsonb, p_measurements boolean default false)
returns void
language plpgsql security invoker set search_path = ''
as $$
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_measurements then
    if jsonb_typeof(p_payload->'heightCm') is distinct from 'number'
      or jsonb_typeof(p_payload->'weightKg') is distinct from 'number'
      or (p_payload->>'heightCm')::numeric <= 0
      or (p_payload->>'weightKg')::numeric <= 0 then
      raise exception 'Positive numeric height and weight required';
    end if;
    update public.profiles
      set height = (p_payload->>'heightCm')::numeric,
          weight = (p_payload->>'weightKg')::numeric,
          updated_at = now()
      where id = auth.uid();
    if not found then raise exception 'Own profile not found'; end if;
  end if;
  -- Null measurement slots retain compatibility with the original payload check.
  -- Measurements themselves are now owned by profiles, including on water saves.
  insert into public.physical_health_records (user_id, kind, device_id, payload)
  values (auth.uid(), 'physical', '',
    p_payload || jsonb_build_object('heightCm', null, 'weightKg', null))
  on conflict (user_id, kind, device_id) do update set payload = excluded.payload;
end;
$$;

revoke all on function public.read_physical_health() from public, anon;
revoke all on function public.save_physical_health(jsonb, boolean) from public, anon;
grant execute on function public.read_physical_health() to authenticated;
grant execute on function public.save_physical_health(jsonb, boolean) to authenticated;

-- Keep legacy payload copies during transition so old installed clients can
-- still read them. New saves clear those slots; profiles is authoritative.
notify pgrst, 'reload schema';
commit;
