# Physical tab integration handoff

## Android Studio / IntelliJ

Open the repository root, with the Flutter and Dart plugins enabled. If running
**Healthiez Android** reports `Unknown run configuration type FlutterRunConfigurationType`,
install/enable **Flutter** and **Dart** in Settings > Plugins, then restart Android
Studio. The Flutter plugin supplies this type; changing the run configuration XML
does not install it. Select the
Flutter SDK in Settings > Languages & Frameworks > Flutter. The verified local
toolchain is Flutter 3.47.8 / Dart 3.13.7; `pubspec.yaml` requires Dart ^3.13.5.
For this machine, the Flutter SDK is `D:/programming/flutter` and the Dart SDK
is `D:/programming/flutter/bin/cache/dart-sdk` (select the SDK directory, not `bin`).
If Dart is reported missing after installing the plugins, enable Dart support for
the Healthiez module in Settings > Languages & Frameworks > Dart with that path.
Run `flutter --version` in the IDE terminal and compare it with the configured
SDK before diagnosing the reported version mismatch. The IDE name alone does
not identify the SDK. Do not lower dependency constraints without resolving and
testing against the team's actual SDK.

Copy `supabase.example.json` to `supabase.local.json` and supply the project URL
and publishable key. Never use a management or service-role token. Select the
shared **Healthiez Android** run configuration and an Android device/emulator.
If the IDE does not discover `.run/Healthiez Android.run.xml`, create a Flutter
configuration targeting `lib/main.dart` with this additional run argument:

```text
--dart-define-from-file=supabase.local.json
```

Run `flutter pub get`, then start the configuration. Step sensor behavior must
be verified on a real phone. Emulator execution alone does not verify counting.

## Android build troubleshooting

`permission_handler_android` requires compile SDK 37; the app explicitly selects
37 because this Flutter SDK defaults to 36. Install the matching Android platform
in SDK Manager when setting up another machine.

On Windows, Kotlin incremental compilation can fail with `this and base files
have different roots` when Pub packages are on C: and this project is on D:.
`android/gradle.properties` disables Kotlin incremental compilation to avoid that
cache failure. This may slow Kotlin rebuilds; reconsider the workaround when the
project and Pub cache share a drive or the compiler fixes cross-drive paths.

## Deployment requirement

**First merge defaults to the deployed snapshot schema and needs no new SQL.**
`PhysicalStore` only uses profile RPCs when constructed with
`useProfileStorage: true` or built with `--dart-define=PHYSICAL_PROFILE_STORAGE=true`.
Leave this off for the first working merge. The profile migrations are prepared
and tested, not deployed. Guest storage still works locally.

Enabling profile storage requires both SQL migrations below before use.
Deploy the auth lookup change alongside the owner-only profile policy; do not
deploy that policy alone while the login branch still queries anonymous profiles.

1. [Signup seed](sql/20261101_seed_physical_on_profile.sql).
2. [Decimal profiles, owner-only reads and atomic RPCs](sql/20261101_profile_measurements.sql).

Run [signup verification](sql/test_signup_physical.sql) and
[profile verification](sql/test_profile_measurements.sql) afterward. Both tests
roll back their fixtures. The complete migration/profile test passed in a
fully rolled-back development rehearsal, including decimal preservation,
failed-save rollback, water isolation, cross-account and anonymous access.

## Database contract after enabling profile storage

`PhysicalStore.table` is `physical_health_records`. The composite primary key is
`(user_id, kind, device_id)`. The current physical branch does not query
`daily_record`, `daily_records`, or `mental_health_records`; the reported missing
relation needs the failing statement/trigger from the merged app to locate its
actual source.

| Record | kind | device_id | Required payload |
| --- | --- | --- | --- |
| Today's water | `physical` | empty string | `waterMl`, `waterDate`; legacy height/weight slots are null on new saves |
| Installation step counter | `steps` | 32 lowercase hex characters generated on the device | `date`, `steps`, `last` |

`profiles.height` (cm) and `profiles.weight` (kg) own measurements after migration.
The migration widens smallint columns to numeric without rounding and backfills
empty profile fields from existing physical snapshots. Existing non-null profile
fields take precedence. Legacy copies remain until the next save so the migration
does not delete the only copy of data belonging to an absent profile. Older
installed clients must be upgraded: their snapshot measurement saves no longer
update the authoritative profile.

Development schema inspection on 2026-11-01 confirmed `profiles.id` (UUID),
`height` and `weight` (nullable smallint). Decimal preservation therefore needs
a column-type migration; the user approved decimal preservation and owner-only
profile reads. The updated login, mental and merged branches all request Dart
^3.13.5, like physical. This does not identify teammates' installed SDKs.

`read_physical_health()` composes the controller payload from the signed-in
profile and water snapshot. `save_physical_health(p_payload, p_measurements)`
commits measurements and water atomically. `p_measurements=false` updates water
without overwriting measurements changed by the profile feature. RPCs run as
the caller, filter by `auth.uid()` and are executable only by authenticated
users. Steps keep their existing per-installation storage. A partial measurement
pair is presented as unset until both values are saved; individual profile
columns remain untouched by reads and water saves.

Missing physical rows are supported: the app starts with empty measurements and
zero water, and upserts on the first save. Missing step rows are also supported.
Never seed a step sensor baseline on signup: it belongs to an installation.

## Valid optional signup seed

The inspected live chain is `auth.users` -> `handle_new_user()` -> `profiles`
-> `handle_new_profile()`. The last function currently inserts a mental record
only; it does not reference `daily_record`. The ready-to-review migration is
[20261101_seed_physical_on_profile.sql](sql/20261101_seed_physical_on_profile.sql).
It preserves the mental insert and adds the physical seed. The migration and
[signup test](sql/test_signup_physical.sql) passed together in a transaction
that was fully rolled back against development. **It has not been deployed.**

For reference, the physical insert inside `handle_new_profile()` is:

```sql
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
```

An empty `{}` payload violates the current table constraint. Do not copy the
placeholder `GIÁ_TRỊ_KIND` / `GIÁ_TRỊ_DEVICE_ID` from the chat into production.
The seed date is the database session date; the client resets water against its
local calendar on load. A zero-water seed therefore does not transfer water
between dates. Signup seeding is optional for this client and does not fix a
separate trigger that references a missing `daily_record` table.

## Home tab consumption

For the signed-in user, call `read_physical_health()` for BMI inputs and water. Only show
`waterMl` as today's water when `waterDate` matches the user's local date.
Calculate BMI from the returned confirmed height/weight.
Step snapshots contain device-specific sensor baselines; do not sum rows across
phones or expose `last` as the daily total. The actual daily count is `steps`,
valid only when `date` is today. Decide which device Home represents before
adding a cross-device dashboard. Row-level security restricts account access.

## Auth teammate change required

The inspected broad `Public profiles are viewable by everyone.` SELECT policy
exposes the entire profile. The user approved removing it before moving health
measurements into that table. Remaining inspected profile policies restrict
reads/writes to `auth.uid() = id`.

In `lib/services/auth_service.dart` on `origin/feature/login`, both
`signInWithUsername` and `getEmailByUsername` currently query `profiles` before
authentication. These calls will no longer work after the privacy migration.
The auth teammate must use email login/recovery or implement a server-side
username sign-in/recovery endpoint with rate limits and generic errors. Do not
restore public profile reads to make those two calls work. Email/password login,
own-profile reads and profile creation are compatible with the new policy.
This physical branch does not contain the teammate's auth service, so that
change belongs in the integrated/auth branch.

## Branch inspection and pending evidence

- Team Flutter/Dart versions and the full physical-branch error.
- Auth teammate's replacement for anonymous username lookup before deployment.
- Integrated app/device verification after coordinated deployment.
- Physical mockup is blank; the pink canvas is outside the app frames. Supplied
  app colors are purple/blue, pale background, dark text, and rounded controls.

The user approved designing the physical layout from these cues. The implemented
screen uses a gradient header, pale background, rounded white cards and fields,
and section icons. Its colors match the cached login branch's `AppColors`.
Header widget previews are in `physical_style.dart` and use no native plugins.

GitHub access was restored using the already-authenticated `tu3lam` account for
the fetch command only; the active `tue8` account was unchanged. Latest refs were
fetched on 2026-11-01. The merged branch at `45caf2d` has empty Home repository,
model and MainShell files; it cannot establish a working dashboard data contract.
Mental currently reads `mental_health_records`; its water/sleep model fields do
not implement physical history. Daily snapshots here provide no sleep/history
data, and no such data was invented for the integration.

After changes, run `dart format` on changed Dart files, `flutter analyze`, and
`flutter test`. Verify signup, returning login, account switching and restored
measurements on the integrated app before treating the team handoff as complete.
