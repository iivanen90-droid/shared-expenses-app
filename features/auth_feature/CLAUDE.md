# Authentication feature

Google OAuth is optional. Profile opens the independent authentication page.
Cubit awaits a single final sign-in result; Interactor owns the temporary attempt subscription.
Core owns Supabase callback processing and secure persistence; no SDK details in the feature.
States are initial/loading/cancelling/error/authenticated. Never equate browser launch with sign-in.
Closing a pending page cancels its attempt. Normal sign-out belongs to Profile.
Preserve the actual session on storage failure, including the Account recovery action.
Apple and additional providers are deferred. Local groups remain usable without authentication.
