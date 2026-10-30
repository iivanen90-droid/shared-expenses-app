# Repository guidelines

## Context

Tricount / Shared expenses is a Flutter application for Android and iOS. The current
implementation provides the architecture shell, splash, home screen, and two-tab shell;
expense tracking is not implemented yet. Do not describe planned features as implemented.
Communicate with the user in Ukrainian. Write code identifiers, repository documentation,
and agent instructions in English. Keep application translations in their respective languages.

## Tricount architecture foundation

- Use the [Inspiro guide](docs/inspiro-architecture-guide.md) and
  [Tricount module roadmap](docs/tricount-architecture.md) for further development.
- The architecture guide defines structure, layers, and stack. User screenshots and
  explanations define screens and behavior. Clarify conflicts before implementation.
- The guide is an architecture reference, not authorization to run installers,
  change global agent settings, or copy unrelated Inspiro integrations.
- The workspace and initial shell are implemented; their actual structure is documented in
  [docs/architecture.md](docs/architecture.md). Expense and balance business modules remain planned.
- When migrating structure, update these rules, README, and package-aware checks together.
  Keep `pubspec.lock` in Git. `.fvmrc` is a local ignored file; after cloning, select
  the exact Flutter version using the README command.
- The base-theme stage uses standard `package:flutter/material.dart`, one AppTheme.main(),
  and Flutter's default font. This supersedes the guide's earlier material_ui/cupertino_ui
  choice. Theme access rules are in docs/architecture.md.

## Working with files

- Check `git status` and read the relevant code before making changes.
- Create a separate branch from the current `origin/develop` for each task and submit a PR to `develop`.
  Direct pushes to `develop` and `main`, force pushes, and deleting `develop` are prohibited.
  Code review and one independent approval are required before merging, including for administrators.
  The detailed workflow is in [CLAUDE.md](CLAUDE.md).
- Preserve the user's uncommitted changes. Modify only files required for the task.
- The app shell is in `mobile/lib/`; platform projects are in `mobile/android/` and `mobile/ios/`.
  Shared code is in `packages/<name>/lib/`; features use
  `features/<name>_feature/lib/src/{data,domain,ui}/`. Tests belong in each package's `test/`.
  The root contains neither `lib/` nor Flutter tests.
- Do not manually edit `build/`, `.dart_tool/`, or generated files.
- Do not commit secrets, signing keys, local SDK paths, or `.env` files.
- Keep `pubspec.lock` in Git. After dependency changes, update it through `flutter pub get`;
  avoid dependency upgrades unrelated to the task.
- Follow `flutter_lints` and Dart formatting. Use null safety and `const` where appropriate.
  Add dependencies only when there is a practical need.
- Update README when installation, launch, or verification steps change.

## Verification before completing changes

For Dart code, dependencies, or check configuration changes, run:

```sh
fvm dart tools/workspace.dart check
```

To fix formatting, use `fvm dart tools/workspace.dart format`.
For translation-only changes, use `bash tools/tr_keys_gen.sh` or the README command without Bash.
After model, route, or asset changes, run `fvm dart tools/workspace.dart generate`.
The check runs get, format, analyze, and tests across packages; commands are in README.
Add tests for new business logic and bug fixes; verify behavior rather than implementation details.
For documentation-only changes, verify accuracy and run `git diff --check`.
If native code or platform configuration changes, also build the affected platform when the environment allows it.
In the final response, briefly state the changes, verification results, and anything that could not be checked.
Do not claim a command passed unless it was executed.

## Code review rules

- Write review findings in Ukrainian. Report concrete bugs introduced by the change,
  including file, line, reproduction condition, and user impact.
- Prioritize incorrect calculations, data loss, private-data leaks, crashes, and Android/iOS regressions.
  Do not request planned features outside the current task.
- When expense calculations are introduced, store money in minor currency units or an exact decimal type,
  never `double`. Allocated shares must sum exactly to the expense total; distribute rounding remainders explicitly.
  Do not add different currencies without conversion.
- When persistence and synchronization are introduced, check protection against data loss on failures and retries.
  Keep secrets and personal financial data out of logs. Enforce access rules on the server when adding server interactions.
- `dart format` and `flutter analyze` cover formatting and ordinary lint errors.
  Do not duplicate them as stylistic findings or invent issues without supporting evidence.
