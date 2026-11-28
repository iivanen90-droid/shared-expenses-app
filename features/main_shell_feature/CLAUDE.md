# main_shell_feature

Two-tab shell with an optional Profile account entry and sign-out. Router declares typed routes and supplies
StatefulNavigationShell to MainShellPage, which renders it and switches branches locally.
The shell exposes Home and Profile. Profile opens the optional authentication route.
Do not import other feature packages. Profile account actions follow Page → Cubit →
Interactor → Repository → core AuthService; each layer uses its DI resolver.
Translation keys come from common. The shell inherits the app theme.
Navigation integration tests are in mobile/test.
Primary rules: [CLAUDE.md](../../CLAUDE.md).
