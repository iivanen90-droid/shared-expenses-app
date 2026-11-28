# Google authentication

Task [Trello #31](https://trello.com/c/4kkCz6jm).

Authentication is optional. Profile opens the independent typed `/auth` route.
Home, the group form, and local ObjectBox groups remain available without an account.
The Google button starts the browser OAuth flow. Supabase creates an Auth user on the
first successful sign-in and restores the existing account on later sign-ins.
The sign-in page returns to Home after confirmed authentication. Profile owns normal sign-out.
A storage error with an active SDK session keeps an Account action for cleanup in Profile.
Neither page displays personal profile data. Existing local groups remain independent of accounts;
new signed-in group uploads use the ownership rules in [database setup](supabase-database.md).

Apple authentication is deferred by the project owner. Email/password authentication
and full server group synchronization remain outside the authentication scope.
Database tables and initial group uploads are documented in the separate database stage.


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

AuthCubit uses initial/loading/cancelling/error/authenticated states and has no stream
subscription or independent busy flag. AuthInteractor owns one attempt per screen:
it subscribes to non-replayed service changes before launching the browser and returns
one Future containing the final result, not merely launch success. Repository delegates
SDK access; core retains transport-specific callback queues and safe persistence.
The interactor ignores session updates while cancelling, waits for an in-flight browser
launch, then invokes core cleanup. Closing the page cancels an unfinished attempt.
Profile separately observes application session changes and owns sign-out; it preserves
busy status until cleanup actually completes. Successful logout opens a fresh auth route.

SecureStorage is the reusable encrypted key/value interface; SecureStorageImpl wraps
flutter_secure_storage. SecureAuthStorage adapts it to Supabase session/PKCE APIs and
retains environment/project namespacing, ordered writes and per-key failure tracking.
SDK/plugin failures are normalized in core as Either failures, not raw UI stream errors.

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
change access to device-local groups. Server uploads use explicit ownership and
RLS policies described in [database setup](supabase-database.md).

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
See the [OAuth reference](https://supabase.com/docs/reference/dart/auth-signinwithoauth)
and [auth events](https://supabase.com/docs/reference/dart/auth-onauthstatechange).
A successful browser launch is therefore not a final sign-in result.

`AuthInteractor.signInWithGoogle()` returns one shared **operation** Future to all
callers. A received SDK result is a separate internal signal. Cancellation and
page disposal must still clear the session if that signal arrived while the
browser-launch Future was pending. Cleanup failure wins over an earlier success;
successful cancellation returns cancelled to every caller. No second provider
or generic provider parameter is introduced in this refactor.

The small `_PendingSignIn` object holds only the event result, browser launch,
shared operation and optional cleanup Future. There is no independently mutable
cancelling flag: cancellation is derived from the cleanup Future. The object
exists because these asynchronous steps have different completion boundaries;
removing it by spreading the same fields over the Interactor would not simplify
the protocol.

`AuthService.snapshot` reads the current session and safe persistence failure.
`watchStatus()` now publishes **future changes only**: the custom replay stream
and its boolean mode were removed. Auth initializes from snapshot; Profile reads
snapshot and observes future changes. Old errors are not replayed into a new
sign-in attempt. The service derives session presence directly from the SDK,
without a second mutable status field. Failure notifications use one emission
path, including failed logout cleanup.

`SecureAuthStorage` is retained as the SDK-required `LocalStorage` and
`GotrueAsyncStorage` adapter, not as another encrypted-storage implementation.
The locked SDK calls `persistSession`/`removePersistedSession` itself during auth
events; a Repository that writes SecureStorage manually would not replace those
hooks. The adapter delegates encryption to SecureStorage, namespaces keys by
project/environment, serializes writes, and remembers failed keys. Removing
these guarantees would regress late-refresh/logout and storage-failure tests.
The callback queue also remains: the SDK's in-flight code exchange can install
a session after sign-out, so cleanup drains the exchange before reporting success.

Regression tests cover early signed-in events followed by cancellation/disposal,
duplicate callers waiting on the same operation, and failure to clear an already
active session. SDK tests retain real fake-transport session restore, late PKCE
exchange, safe storage failures, and offline cleanup coverage.
