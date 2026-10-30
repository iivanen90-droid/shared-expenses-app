# home_feature

Initial Tricount shell module. Rules: [CLAUDE.md](../../CLAUDE.md).
Data → domain → ui; public access is through `home_feature.dart` only.
UI button handlers call typed routes through the public router barrel; do not inject navigation callbacks.
Do not add expense business features without an agreed task.
Generate from this package: `fvm dart run build_runner build --force-jit`.
Verify from this package: `fvm flutter test`.
