# Tricount development workflow

Primary rules: [AGENTS.md](AGENTS.md). Commands: [README.md](README.md).
[Current architecture](docs/architecture.md), [Inspiro reference](docs/inspiro-architecture-guide.md),
[future Tricount modules](docs/tricount-architecture.md).

## Architecture rules

- Implemented workspace: mobile, core, ui_kit, common, router, splash_feature, home_feature, main_shell_feature.
  Financial features are not implemented. Do not copy Inspiro's editor, purchases, or integrations.
- Core and ui_kit are independent of other workspace packages. Features do not import other features.
  Access other packages through public barrels, never their `src/` directories.
- Page → Cubit → Interactor → Repository → Source. Source/Repository/Interactor use interface + Impl.
  Use constructor injection with required named parameters and private fields. Cubits do not call repositories.
- Cubits extend SafeCubitWrapper. Use one freezed state with a status enum. Pages create Cubits through DI.
- Await ApplicationInitializer.initialize() before runApp: error handlers and startup readiness.
- Register each feature's three DI resolvers in common after core, in data → domain → ui order.
- Routes are typed in router. Start at splash; buildPlatformPage uses SDK MaterialPage / CupertinoPage by platform.
  StatefulShellRoute already provides two tabs with independent stacks. Do not add business screens outside the task.
- UI uses standard `package:flutter/material.dart`; access the theme through AppThemeProvider and context.colors/texts/icons.
  material_ui and cupertino_ui are not used directly; CupertinoPage only supplies iOS transitions for Material widgets.
  Use Flutter's default font without font assets. Strings use LocaleKeys and easy_localization; assets use flutter_gen.
- Use Either<Failure,T> and handle exceptions in data/domain. Add DTO/json_serializable and ObjectBox only with
  an agreed API or structured data. Do not add empty network/database scenarios.
- Track analytics from Cubits using screen-specific event classes. Do not log financial/personal payloads or exception messages.
- Use `package:` imports. Avoid widget functions, nested ternaries, unchecked `!`, and context after await without mounted.
- Never edit generated files manually. Keep the shared `pubspec.lock` in Git.
  `.fvmrc` is local and ignored; Flutter version and post-clone setup are in README.
- Write repository documentation and agent instructions in English; communicate with the user in Ukrainian.

## Adding functionality

Agree on the screen, behavior, data, and scope. Add the package, layers/index/barrel, and a short CLAUDE.md;
update workspace registration and common/router dependencies. Implement DI, interactor, Cubit, typed route,
localization, theme, and Semantics identifiers. Add interactor/Cubit tests and a page widget test.
The detailed process is in [docs/architecture.md](docs/architecture.md).

## Generation and checks

```sh
fvm flutter pub get
fvm dart tools/workspace.dart generate
fvm dart tools/workspace.dart check
```

For translation-only changes, use `bash tools/tr_keys_gen.sh` or the README command without Bash.
Run build_runner from the owning package. Run tests in each package.
Dev/prod launch and Android build commands are in README. iOS requires macOS/Xcode;
explicitly report unavailable checks. Do not commit SDK paths, secrets, build output, or private environments.

## Branches and review

Use a separate `codex/<name>` branch from the current origin/develop for each task and submit a PR to develop.
Direct pushes to main/develop, force pushes, and deleting develop are prohibited.
Before merging, require code review and one independent approval; authors do not approve their own PRs.
New commits dismiss approvals. Codex review does not replace the required approval.
Protection applies to administrators: never bypass or weaken it.
Preserve uncommitted changes; use a separate worktree when needed.
If the GitHub plan or permissions do not support protection, notify the user and agree on the next step.
