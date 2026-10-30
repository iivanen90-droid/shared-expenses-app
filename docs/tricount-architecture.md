# Tricount development roadmap

Design decisions originate in the [Inspiro guide](inspiro-architecture-guide.md).
Implemented packages, layers, initialization, navigation, and generation are described in the
[current architecture](architecture.md). The workspace and initial shell already exist.
The working name is Tricount; the home screen retains the localized Shared expenses title.
Expense business logic, groups, expense persistence, and a backend are not implemented yet.

## Preliminary module map

This is a planning proposal, not an approved screen list or a list of implemented features.
Add each package when its corresponding scenario is agreed upon.

| Module | Purpose | Details to clarify from screenshots and requirements |
|---|---|---|
| `splash_feature` | Check startup readiness and select the next route | Transition conditions and required startup checks |
| `groups_feature` | List, create, and view shared-expense groups | Fields, ordering, editing, and archiving |
| `participants_feature` | Group participants | Adding, renaming, and deletion restrictions |
| `expenses_feature` | Enter, view, and edit expenses | Payers, shares, currency, categories, and validation |
| `balances_feature` | Calculate balances and display debts | Allocation rules and result presentation |
| `settlements_feature` | Record repayments between participants | Partial repayment, corrections, and cancellation |
| `settings_feature` | Language, appearance, and other agreed settings | The actual set of settings |

Define authentication, backend, synchronization, notifications, and external integrations separately
if they become requirements. The guide is not Tricount's product specification.

Splash and home are implemented as the initial shell. Other modules in the table remain planned
and will be created from agreed screenshots. Add ObjectBox structured data and DTO/json_serializable
only with the relevant scenario. StatefulShellRoute already provides a two-tab shell without financial logic.

## Financial data rules

- Store amounts as `int` minor currency units or an exact decimal type; do not use `double`.
- Allocated shares must sum exactly to the expense total; rounding remainder allocation must be explicit and reproducible.
- Currency is part of the monetary value. Do not sum different currencies without an agreed conversion mechanism.
- Balances include expenses and repayments according to agreed business rules.
- Define failure/retry behavior for persistence and server-side access checks for server interactions.

## Next steps

1. Agree on the first product scenario: screen, fields, states, transitions, and data rules.
2. Add the feature with the full Page → Cubit → Interactor → Repository → Source flow.
3. Connect the required storage/API, mappers, and error handling. Do not copy unrelated Inspiro business code.
4. Verify calculations, rounding, currencies, and recovery when those behaviors are introduced.
5. Add unit/widget/e2e checks for the agreed behavior; verify Android and iOS where the environment allows it.

Versions in the guide are an Inspiro snapshot; the root pubspec.lock records the agreed versions.
Select Flutter 3.47.7 locally with `fvm use 3.47.7`; `.fvmrc` is ignored by Git.
Firebase, purchases, attribution, and integrations are not added automatically.
Rules are in [CLAUDE.md](../CLAUDE.md) and [AGENTS.md](../AGENTS.md); commands are in [README](../README.md).
Submit changes through a separate PR to develop, with code review and one independent approval.
