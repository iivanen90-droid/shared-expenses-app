# main_shell_feature

Two-tab shell without business logic. Router owns navigation;
this package renders NavigationBar and placeholder pages and receives callbacks.
Do not import other feature packages. Keep data/domain/ui resolvers empty
until dependencies are agreed upon; do not invent Cubits or interactors.
Translation keys come from common; the theme comes from ui_kit.
Navigation integration tests are in mobile/test.
Primary rules: [CLAUDE.md](../../CLAUDE.md).
