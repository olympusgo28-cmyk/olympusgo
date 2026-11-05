# Developer set-up (P0-01, P0-04)

Versions in use on 30 Oct 2026:

| Tool | Version |
| --- | --- |
| Flutter | 3.47.4 (Dart 3.13.3) |
| Supabase CLI | 2.122.0 |
| Deno | 2.9.8 |
| Xcode | 26.4.1 |
| Docker | through Colima (`colima start --cpu 4 --memory 6`) |

`flutter doctor` is clean apart from Android licences, which need `flutter doctor --android-licenses` run by a person.

## Every check

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
supabase db reset
supabase test db
supabase db lint --level error   # one known false error, in shop_checkout's temp table
deno fmt --line-width 110 --check supabase/functions
deno lint supabase/functions
deno test --no-check=remote -A supabase/functions
```

The integration tests need the local stack and are otherwise skipped:

```bash
export LOCAL_SUPABASE_URL=http://127.0.0.1:54321
export LOCAL_SUPABASE_KEY=$(supabase status -o json | jq -r .ANON_KEY)
export LOCAL_SUPABASE_SERVICE_KEY=$(supabase status -o json | jq -r .SERVICE_ROLE_KEY)
flutter test
```

After changing a Freezed model or a Riverpod provider: `dart run build_runner build --delete-conflicting-outputs`.

After a deliberate design change: `flutter test --update-goldens test/design_golden_test.dart`.

## Test accounts

`+65 8000 0001` to `+65 8000 0999`, and any `@test.local` address, take the fixed code `123456`. This only works on a local stack.
