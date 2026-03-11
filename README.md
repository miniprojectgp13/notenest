# NoteNest

Flutter student productivity app with Supabase-backed authentication.

## Supabase Setup

1. Open your project dashboard:
`https://supabase.com/dashboard/project/zmtytwilsdpcpzbhjeac`
2. Go to `SQL Editor` and run `supabase/schema.sql` from this repository.
3. Go to `Project Settings > API` and copy:
- `Project URL` (already configured by default in `lib/main.dart`)
- `anon public` key (required at runtime)
4. In `SQL Editor`, run the full `supabase/schema.sql` script after every schema change.

## Run Locally (Chrome)

Use this command from project root:

```bash
flutter run -d chrome --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Or use file-based defines (recommended):

1. Copy `env.example.json` to `env.json`
2. Put your real Supabase anon key in `env.json`
3. Run:

```bash
flutter run -d chrome --dart-define-from-file=env.json
```

VS Code launch profile is already added:
`NoteNest (Chrome + Supabase)`

Optional (if you want custom URL):

```bash
flutter run -d chrome \
	--dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
	--dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

## Deploy On Vercel

This project is a Flutter web app, so Vercel will not run it correctly with default settings.

Required:
- Add `SUPABASE_ANON_KEY` in Vercel Project Settings > Environment Variables
- Keep the project root at repository root
- Use the included `vercel.json`

What was blocking deployment:
- No Vercel build config for Flutter
- Vercel does not include Flutter SDK by default
- App throws at startup if `SUPABASE_ANON_KEY` is missing
- Flutter web needs SPA rewrite to `index.html`

After adding the environment variable, redeploy the project.

## Auth Flow Implemented

- Signup: `name + phone + college + password`
- Login: `username OR phone + password`
- Session persistence: user stays logged in after app close/reopen (stored locally in app state)

Notes:
- Phone is validated as 10 digits in app.
- No email-based auth is used in this flow.
- User data is stored in `public.student_users` via secure RPC functions.