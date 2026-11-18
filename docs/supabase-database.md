# Supabase database and offline support

Task: [Trello card 32](https://trello.com/c/W1fh5dpL).
Research checked on 2026-11-18 for the locked `supabase_flutter` 2.18.3 SDK.

## Offline decision

Keep ObjectBox. Supabase Flutter database requests use the remote PostgREST API.
The database API does not provide an ObjectBox-equivalent persistent local store,
offline write queue surviving process death, or automatic reconciliation of local
writes after reconnecting. This conclusion follows from the documented SDK APIs
and Supabase's separate offline integration guidance; session persistence is not
database persistence.
The SDK's `stream()` retains its current result in memory for a live subscription;
that is not a durable cache and does not survive process restart.

| Capability | Supabase Flutter SDK | Current application |
| --- | --- | --- |
| Remote SQL reads and writes | Yes, through PostgREST/RPC | Generic core wrapper |
| Live row updates | `stream()` combines an initial query with Realtime | Not enabled here |
| Durable local database/cache | Not supplied by the database API | ObjectBox retained |
| Writes with no connection | No durable SDK database queue | Save locally; mark remote write unconfirmed |
| Queue restored after app restart | Not supplied by the database API | Not implemented |
| Automatic local/remote reconciliation | Not supplied by the database API | Separate future stage |

Official references:

- [Flutter database reads](https://supabase.com/docs/reference/dart/select),
  [writes](https://supabase.com/docs/reference/dart/insert), and
  [RPC](https://supabase.com/docs/reference/dart/rpc).
- [Flutter stream](https://supabase.com/docs/reference/dart/stream) describes
  PostgREST plus Realtime; it does not document durable offline delivery.
- [Supabase's Brick tutorial](https://supabase.com/blog/offline-first-flutter-apps)
  adds SQLite caching and a retry queue through **Brick**, a third-party package.
  These are integration capabilities, not native Supabase Flutter guarantees.
- [PowerSync's Flutter documentation](https://docs.powersync.com/client-sdk-references/flutter)
  describes another third-party local SQLite/sync stack. It requires a separate
  architecture/service assessment, including cost and data access. Neither Brick
  nor PowerSync is installed or enabled by this change.

## Current data flow

`RemoteDatabase` in core provides filtered reads, inserts, filtered updates/deletes,
and RPC calls. It uses the same initialized Supabase client/session as auth; it
never initializes a second client. Failures contain only safe kinds, not server
messages, row values, keys or URLs. Calls time out after 15 seconds. A timeout
cannot prove rollback: the server may have committed before the response was lost.
Update/delete require filters to prevent accidental unfiltered mutations.

The Home repository saves a group to ObjectBox **before** any remote request.
A UUID is generated once and stored as `stableId`; the server's group `id` is
exactly this UUID. The integer ObjectBox ID remains a device-local routing key.
Existing records receive UUIDs on opening without changing their numeric IDs,
participants or ownership. Old and anonymous groups remain local-only and are
never silently uploaded when somebody signs in.

For a newly created group, capture the signed-in owner's ID before local saving.
Send the group and ordered participant names in one `create_expense_group` RPC.
The server derives access from `auth.uid()`, rejects a mismatching owner, and
commits the group and participants atomically. Repeating an identical UUID and
payload returns that same group; a changed payload with that ID conflicts instead
of overwriting existing data. Participants use `(group_id, position)` as their
stable creation identity. They are names, not invited accounts.

Home shows local-only, uploaded, or unconfirmed status. A remote error preserves
the local group and gives a localized notice. The persisted `pending` state also
displays as unconfirmed after a crash. An uploaded badge means the initial group
and participant transaction was acknowledged, not ongoing synchronization.
No startup upload, background queue, reconnect retry, account migration, remote
downloads, invitations, or conflict resolution is implemented in this stage.

Local groups remain device-wide as before: signing out does not delete them or
hide their names from another person using the same device. Server records are
owner-only. Local account isolation is a separate product/security decision.

## Server deployment

Requires the auth PR first. Apply
`supabase/migrations/20261118140000_expense_groups.sql` once to the **development**
project using Supabase SQL Editor or an authorized migration runner. It creates
new tables, indexes, constraints, owner-only RLS policies and an invoker RPC.
No existing application data is removed. Never paste database passwords, Google
client secrets, access tokens, or service-role/secret keys into source or PRs.
The app continues to use the ignored URL/publishable-key configuration from auth.

Enable the Data API for the public schema if it was disabled at project creation.
Tables grant no access to `anon`; enabling the API alone is not a substitute for
these RLS policies. Test the migration before uploading real participant names.
The owner cannot be changed with a table update. No sharing policies are added.
See [RLS](https://supabase.com/docs/guides/database/postgres/row-level-security)
and [invoker functions](https://supabase.com/docs/guides/database/functions).

Run `node tools/test_supabase_schema.cjs` after installing `@electric-sql/pglite`
in a temporary folder and setting `PGLITE_MODULE` to its absolute module path.
This test uses isolated PostgreSQL WASM with mocked Auth roles/UIDs, not a live
Supabase project. It validates RLS for two users and anon, atomicity and replay.
Live deployment, PostgREST schema exposure, and end-to-end tests with two real
development users still require a configured development project.

## Next synchronization stage

Agree on local account isolation/anonymous adoption first. Add an ObjectBox outbox
transactionally with local changes, scoped to owner and project, with durable
operation IDs, explicit retry/backoff and surfaced permanent failures. Reuse the
stable UUIDs for idempotent delivery. Add server versions/tombstones, an explicit
conflict policy, remote download checkpoints and permission-revocation handling.
Verify offline create/restart/reconnect, lost acknowledgements, concurrent edits,
account switches and deletion before claiming complete offline synchronization.
