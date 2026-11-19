# main_shell_feature

Router declares typed routes and supplies
StatefulNavigationShell to MainShellPage, which renders it and switches branches locally.
The shell exposes Home and Profile. Profile uses Page → Cubit → Interactor → Repository → Source
for the current AuthService identity, LanguagePreferences and sign-out. Guests can open auth.
Do not import other feature packages. Keep personal fields out of diagnostics and settings.
Save language before applying it. Only successful logout replaces the root route with auth.
Do not delete/reassign device-local groups. Details: [Profile](../../docs/profile.md).
Translation keys come from common. The shell inherits the app theme.
Navigation integration tests are in mobile/test.
Primary rules: [CLAUDE.md](../../CLAUDE.md).
