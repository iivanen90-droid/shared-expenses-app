# main_shell_feature

Two-tab shell without business logic. Router declares typed routes and supplies
StatefulNavigationShell to MainShellPage, which renders it and switches branches locally.
Placeholder pages call typed router routes directly from their button handlers;
do not pass navigation callbacks from route builders.
Do not import other feature packages. Keep data/domain/ui resolvers empty
until dependencies are agreed upon; do not invent Cubits or interactors.
Translation keys come from common; the theme comes from ui_kit.
Navigation integration tests are in mobile/test.
Primary rules: [CLAUDE.md](../../CLAUDE.md).
