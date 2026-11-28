# Profile and language preferences

Task: [Trello card 33](https://trello.com/c/u2vWq78b).
Depends on the shared Supabase authentication implementation in PR #28, not the
database upload work in PR #29.

## Profile

The existing Profile tab now has its own Cubit, Interactor, Repository and Source
inside main_shell_feature. The read-only core AuthSessionSource exposes a minimal current-session
profile: trimmed `full_name` (falling back to `name`) and email. The SDK session
remains the source of identity; no second user table or persisted profile cache is created.
Session changes refresh the profile, and signed-out snapshots discard identity.
Missing fields have translated placeholders. Guests can open the existing auth
route. Profile editing, avatars downloaded from providers, notifications and a
theme toggle are outside this card's implementation.

Names and emails are displayed only in the app. They are not written to settings,
analytics, logs, documentation or PR examples. AuthenticationProfile and ProfileState
diagnostic strings exclude these fields. Tests use fictional `.invalid` addresses.
Supabase's existing encrypted session storage still owns session persistence.

## One durable language preference

`LanguagePreferences` in core owns the `app.language` key through PreferencesStorage
and supports `en` and `uk`. The bootstrap loads it before the first application
frame, using a supported device language or English when no choice exists.
Profile saves the choice first, then applies it with easy_localization to the
whole application without recreating the router. A failed write shows an error
and retains the previous language. Sign-out never clears this setting.

easy_localization runs with `saveLocale: false`. It renders translations and handles
runtime locale changes; it does not write a competing setting. The first load
migrates its old `locale` key from legacy SharedPreferences into the canonical
PreferencesStorage backend, then removes the legacy key. An existing canonical
choice wins. Failed migration preserves the old value for retry.

For easy_localization 3.0.8, `ensureInitialized()` caches that legacy value even
when persistence will be disabled. Bootstrap therefore migrates preferences before
calling it. Startup order is binding/debug semantics, awaited portrait request,
DI registration, language restore/migration, localization initialization,
ApplicationInitializer, then runApp with the restored locale.

## Logout and local data

Profile invokes the same cancellation-safe AuthService sign-out used by the auth
page. While pending, controls are disabled. On failure, it stays on Profile and
shows a translated retry message; session updates still reflect the actual SDK
state. Only successful completion navigates with typed `go(AuthRoute)` instead of
pushing it. This removes the tab shell and its nested stacks, so Back cannot
reopen the previous authenticated Profile or group route.

ObjectBox groups are not deleted or reassigned. In the current app they are
device-local and remain visible when Home is opened again, including after an
account switch. This does not implement local account isolation. PR #29 separately
limits remote groups to their owner and does not upload existing anonymous groups.
Do not describe logout as deleting local data or providing account-isolated storage.

## Verification

Tests cover real SDK profile mapping/removal, safe diagnostic strings, persistence,
legacy migration and conflicting settings, failed language writes, profile/session
changes, duplicate/failed logout and disposal. Mobile integration exercises visible
identity, immediate translation of the navigation labels, persisted language,
logout retry, cleared navigation history, and preserved local groups. Bootstrap
verification checks the restored locale before the first frame.

For a live development session, open Profile and verify name/email or placeholders,
switch languages, restart, and verify the choice. Sign out, check that Back cannot
return to Profile, restart, and check language and local groups. No new native
platform configuration, provider setup or server migration is required for this card.
