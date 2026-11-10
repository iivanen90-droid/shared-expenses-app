# main_shell_feature

Two-tab shell without business logic. Router declares typed routes and supplies
StatefulNavigationShell to MainShellPage, which renders it and switches branches locally.
The shell exposes Home and Profile. Profile is a blank placeholder.
Do not import other feature packages. Keep data/domain/ui resolvers empty
until dependencies are agreed upon; do not invent Cubits or interactors.
Translation keys come from common. The shell inherits the app theme.
Navigation integration tests are in mobile/test.
Primary rules: [CLAUDE.md](../../CLAUDE.md).
