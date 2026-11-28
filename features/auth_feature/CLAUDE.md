# Authentication feature

Google OAuth is optional. Profile opens the independent authentication page.
Cubit awaits one final signIn(source: ...) result through the stateless Interactor.
AuthRepository adapts SDK launch and session confirmation into that result.
Read-only account state has its own Source/Repository/Interactor; command Repository exposes only signIn/signOut.
Core owns Supabase callback processing and secure persistence; no SDK details in the feature.
States are initial/loading/cancelling/error/authenticated. Never equate browser launch with sign-in.
Closing a pending page cancels its attempt. Normal sign-out belongs to Profile.
Preserve the actual session on storage failure, including the Account recovery action.
Apple and additional providers are deferred. Local groups remain usable without authentication.
