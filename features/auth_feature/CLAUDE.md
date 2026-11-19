# Authentication feature

Google OAuth is optional. The independent authentication page is opened from Profile.
The page calls its Cubit, interactor, repository, and the core AuthService in that order.
The core wrapper owns Supabase, secure session persistence, and callback processing.
Cubit state contains status and safe failure kinds, without tokens or personal data.
Apple sign-in is deferred by the project owner. Local groups remain available without signing in.
