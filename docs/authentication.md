# Google authentication

Task [Trello #31](https://trello.com/c/4kkCz6jm).

Authentication is optional. Profile opens the independent typed `/auth` route.
Home, the group form, and local ObjectBox groups remain available without an account.
The Google button starts the browser OAuth flow. Supabase creates an Auth user on the
first successful sign-in and restores the existing account on later sign-ins.
The sign-in page returns to Home after confirmed authentication. Profile owns normal sign-out.
A storage error with an active SDK session keeps an Account action for cleanup in Profile.
Profile displays name/email through the read-only account source; local groups remain device-wide.

Apple authentication is deferred by the project owner; a second provider is not part of this refactor. Email/password authentication,
server group synchronization, database tables, and account-based group access are outside this change.

## Supabase project

Use the Free project. Paid features are unnecessary for this flow. Current Free allowances
include 50,000 monthly active users, a 500 MB database, and 1 GB file storage.
Check [Supabase pricing](https://supabase.com/pricing) before changing project usage.
Auth works independently of the Data API toggle. This feature performs no table or storage requests.

Enable Google in Authentication → Sign In / Providers and save the Google Web OAuth
Client ID and Client Secret there. In Google Auth Platform, register the exact Supabase
callback URL from the provider page as an authorized redirect URI.
Keep the consent screen in Testing and add the Google accounts used for testing.
Configure only the identity scopes required by Supabase.

In Supabase Authentication → URL Configuration, allow:

- Dev `sharedexpenses-dev://auth-callback`
- Prod `sharedexpenses-prod://auth-callback` in the separate production project when used

Google redirects to the HTTPS Supabase callback. Supabase exchanges the provider result
and returns a PKCE code to the application callback. The app exchanges that code using
its saved verifier. Callback processing accepts only the current flavor's scheme,
the exact `auth-callback` host, an empty path, and a code or error query parameter.
Flutter's built-in deep link handler is disabled so the router does not interpret OAuth URLs.

## Native callback settings and environments

AndroidManifest.xml registers a VIEW/BROWSABLE intent filter for the flavor callback
scheme and exact auth-callback host. iOS Info.plist registers the corresponding URL
scheme. Both disable Flutter's built-in deep-link routing: app_links forwards these
OAuth callbacks to the core SDK adapter instead of treating them as application pages.
These settings are necessary for browser sign-in to return to the application.

The repository supports dev/prod build flavors; this does not provision two hosted
Supabase projects. Only development setup and Android provider-backed login have been
confirmed. Production Supabase provisioning and credentials are not verified or supplied.
Keep production setup separate; never reuse live user data in development tests.

## Local configuration and launch

Copy `envs/supabase.dev.example.json` to ignored `envs/supabase.dev.json`.
Fill `SUPABASE_URL` with the HTTPS project URL and `SUPABASE_PUBLISHABLE_KEY` with the
`sb_publishable_...` key. Only public publishable keys are accepted.

From `mobile/` run:

```sh
fvm flutter run --flavor dev --dart-define-from-file=../envs/dev.example.json --dart-define-from-file=../envs/supabase.dev.json
```

In IntelliJ's Flutter run configuration, use `mobile/lib/main.dart`, the `mobile/`
working directory, and the same arguments. Rebuild after changing dart-defines.
The app can also start without Supabase configuration. It displays an unavailable notice
on the authentication page and continues to support local groups.

Keep the Google Client Secret, database password, secret/service-role keys, and Apple
credentials in the provider dashboard or password manager. They do not belong in
dart-defines, source code, PR descriptions, screenshots, or logs. Project URLs and
publishable keys are client configuration, not server authorization boundaries.

## Ownership and screen lifecycle

AuthCubit uses initial/loading/cancelling/error/authenticated states without a stream
subscription or independent busy flag. It calls `AuthInteractor.signIn(source: AuthSource.google)`
and awaits one final result. Interactor delegates only `signIn` and `signOut`.
The command Repository exposes exactly those two methods. Its implementation subscribes
before opening the browser, combines launch and confirmation into one Future, and cancels
its temporary subscription when that operation finishes. Account reads use a separate
`AuthSessionSource` -> `AuthSessionRepository` -> `AuthSessionInteractor` path.
Profile observes the shared read-only account state independently and owns normal logout.

`AuthSessionStore` publishes one atomic `(session, failure)` snapshot per update.
Consumers read `current` when opening, then observe future changes; stale errors are not
replayed into new sign-in attempts. A persistence error includes the actual session, so
an already authenticated account remains available for cleanup.

`SecureStorageImpl` owns encryption delegation, ordered writes, sanitized failures, and
per-key failure tracking. `flush()` waits for SDK fire-and-forget writes and reports failed
keys until those keys are successfully rewritten or deleted. `SupabaseStorageAdapter`
only maps the SDK-required LocalStorage/GotrueAsyncStorage methods onto this interface
and adds project/environment key prefixes. Existing key names remain unchanged.

## Session lifecycle and privacy

ApplicationInitializer awaits the core Supabase wrapper before marking startup ready.
Supabase restores and refreshes the saved session. The session and PKCE verifier use
flutter_secure_storage with separate namespaces for each flavor and project host.
Android uses encrypted storage and disables application backup. iOS uses this-device
Keychain accessibility and separate flavor URL schemes.

The page waits for an actual authentication event after launching the browser. If the
browser was dismissed, Cancel sign-in stops accepting callbacks and waits for an already
running code exchange to finish before removing its session. Its late authentication event
is suppressed while cancellation is pending. A new attempt is available after cleanup.
Callbacks received after cancellation are ignored until a new attempt starts.
Signing out removes the saved session before reporting success and
uses local sign-out scope, preserving sessions on other devices. It also works offline.

The http dev dependency is used only by SDK integration tests to inject delayed/failing
HTTP responses through MockClient; it is not a second application networking layer.

SDK debug output is disabled. Failures contain only a safe kind, and Cubit state contains
no email, provider response, token, or raw exception. An authentication identity does not
grant access to local groups or future server tables. Server synchronization will require
explicit account ownership and RLS policies when that feature is implemented.

## Manual verification

On an Android dev emulator, open Profile → Account → Continue with Google. Finish consent
with an authorized test user. Verify the signed-in notice, restart the app, reopen Account,
and verify Profile shows Sign out. Sign out from Profile, restart, and verify the Account entry opens the Google action.
Also close the browser before consenting, cancel on the page, and retry. Check that
Home and existing local groups work throughout.

iOS callback and Keychain changes require a macOS/Xcode build and device verification.
Provider-backed sign-in requires the configured project and user interaction with Google.
Automated tests use fake sessions and do not prove a live provider login.

Sources [Supabase Google setup](https://supabase.com/docs/guides/auth/social-sign-in/auth-google),
[Flutter OAuth](https://supabase.com/docs/reference/dart/auth-signinwithoauth),
[auth stream errors](https://supabase.com/docs/reference/dart/auth-onauthstatechange),
[secure storage](https://pub.dev/packages/flutter_secure_storage).

## Review simplification and cancellation boundary (2026-11-28)

The locked SDK (`supabase_flutter` 2.18.3) launches OAuth with a `Future<bool>`;
it reports the confirmed session separately through `onAuthStateChange`.
A successful browser launch is therefore not a final sign-in result.
`AuthService.launchSignIn(source: ...)` explicitly names that technical SDK action.
Feature callers use `AuthRepository.signIn(source: ...)`, which waits for confirmation.
Only Google is implemented; the source parameter does not enable Apple or other providers.

The Interactor has no attempt object, subscription, cancellation state, or disposal logic.
There is no `_PendingSignIn` class. The Repository tracks one active operation, its browser
launch, confirmation, and cleanup. Repeated callers share the same operation Future.
Cancellation waits for launch and cleanup even if a successful SDK event arrived earlier;
a cleanup failure takes precedence over success. Closing a busy Cubit calls the same
signOut command and prevents late UI emissions.

Core retains transport-specific callback serialization because an in-flight PKCE exchange
can install a session after sign-out. Cleanup drains that exchange before removing its
session and reporting success. This is separate from coordinating the screen command.
The SDK storage adapter remains because the SDK invokes its session/verifier hooks itself;
it contains no separate encrypted-storage engine or write queue.

Regression tests cover early signed-in events followed by cancellation or actual Cubit
closure, duplicate callers, failed cleanup, atomic session/storage-error delivery, encrypted
key compatibility, delayed writes, session restoration, and offline cleanup.
