# home_feature

Home reads and creates local groups in ObjectBox through the feature repository. Rules: [CLAUDE.md](../../CLAUDE.md).
Data → domain → ui; public access is through `home_feature.dart` only.
Home presents the sheet above the tab shell. Start opens a typed creation route and Join opens a typed route above the tab shell. The join Cubit controls when the notice is shown.
Keep the ObjectBox model and generated bindings committed.
Do not add expense business features without an agreed task.
Generate from this package: `fvm dart run build_runner build --force-jit`.
Verify from this package: `fvm flutter test`.
