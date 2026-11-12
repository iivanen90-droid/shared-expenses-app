# home_feature

Home screen with a read-only demo group list and a modal sheet for future creation and invitation flows. Rules: [CLAUDE.md](../../CLAUDE.md).
Data → domain → ui; public access is through `home_feature.dart` only.
Home presents the sheet above the tab shell. Join opens a typed route above the shell and shows a local notice on submit. Start remains a placeholder.
Do not add expense business features without an agreed task.
Generate from this package: `fvm dart run build_runner build --force-jit`.
Verify from this package: `fvm flutter test`.
