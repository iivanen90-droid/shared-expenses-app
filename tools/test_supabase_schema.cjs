// Isolated PostgreSQL WASM test. No live Supabase credentials or user data.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { PGlite } = require(process.env.PGLITE_MODULE || '@electric-sql/pglite');

async function main() {
  const db = new PGlite();
  const a = '10000000-0000-4000-8000-000000000001';
  const b = '10000000-0000-4000-8000-000000000002';
  const id = '20000000-0000-4000-8000-000000000001';
  let assertions = 0;
  const check = (actual, expected) => { assert.deepEqual(actual, expected); assertions++; };
  const denied = async (operation, codes = ['42501']) => {
    await assert.rejects(operation, error => codes.includes(error.code));
    assertions++;
  };
  const asUser = async user => {
    await db.exec('reset role; set role authenticated;');
    await db.query("select set_config('request.jwt.claim.sub', $1, false)", [user]);
  };
  const create = (groupId, owner = a, names = ['Alex', 'Sam'], title = 'Trip', currency = 'UAH') =>
    db.query('select public.create_expense_group($1,$2,$3,$4,$5,$6::text[]) as id',
      [groupId, owner, title, '🌍', currency, names]);
  try {
    await db.exec(`
      create role anon; create role authenticated;
      create schema auth;
      create table auth.users(id uuid primary key);
      insert into auth.users values ('${a}'), ('${b}');
      create function auth.uid() returns uuid language sql stable as
        $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
      grant usage on schema auth to anon, authenticated;
      grant execute on function auth.uid() to anon, authenticated;
    `);
    await db.exec(fs.readFileSync(path.join(__dirname, '../supabase/migrations/20261118140000_expense_groups.sql'), 'utf8'));
    await asUser(a);
    check((await create(id)).rows[0].id, id);
    check((await create(id)).rows[0].id, id);
    check((await db.query('select count(*)::int as n from public.expense_groups')).rows[0].n, 1);
    check((await db.query('select name from public.group_participants order by position')).rows, [{ name: 'Alex' }, { name: 'Sam' }]);
    await denied(() => create(id, a, ['Changed']), ['23505']);
    await denied(() => create(id, a, ['Alex', 'Sam'], 'Changed'), ['23505']);
    await denied(() => create('20000000-0000-4000-8000-000000000002', a, [' ']), ['22023']);
    await denied(() => db.query('update public.expense_groups set owner_id=$1 where id=$2', [b, id]));
    check((await db.query('update public.expense_groups set name=$1 where id=$2 returning name', ['Updated', id])).rows, [{ name: 'Updated' }]);
    await asUser(b);
    check((await db.query('select * from public.expense_groups')).rows, []);
    check((await db.query('select * from public.group_participants')).rows, []);
    check((await db.query('update public.expense_groups set name=$1 where id=$2 returning id', ['Stolen', id])).rows, []);
    check((await db.query('delete from public.expense_groups where id=$1 returning id', [id])).rows, []);
    await denied(() => create('20000000-0000-4000-8000-000000000003', a));
    await denied(() => create(id, b));
    await denied(() => db.query('insert into public.group_participants values ($1,5,$2)', [id, 'Intruder']));
    check((await db.query('update public.group_participants set name=$1 where group_id=$2 returning name', ['Intruder', id])).rows, []);
    check((await db.query('delete from public.group_participants where group_id=$1 returning name', [id])).rows, []);
    check((await create('20000000-0000-4000-8000-000000000004', b, [])).rows[0].id, '20000000-0000-4000-8000-000000000004');
    await db.exec('reset role; set role anon;');
    await denied(() => db.query('select * from public.expense_groups'));
    await denied(() => db.query('select * from public.group_participants'));
    await denied(() => create(id));
    await db.exec(`reset role;
      create function public.fail_test_participant() returns trigger language plpgsql as
      $$ begin raise exception 'Test failure' using errcode='23514'; end; $$;
      create trigger test_participant_failure before insert on public.group_participants
        for each row execute function public.fail_test_participant();
    `);
    await asUser(a);
    await denied(() => create('20000000-0000-4000-8000-000000000005'), ['23514']);
    check((await db.query('select id from public.expense_groups where id=$1', ['20000000-0000-4000-8000-000000000005'])).rows, []);
    await db.exec('reset role; drop trigger test_participant_failure on public.group_participants;');
    await asUser(a);
    await db.query('delete from public.expense_groups where id=$1', [id]);
    check((await db.query('select * from public.group_participants')).rows, []);
    console.log(`Passed ${assertions} PostgreSQL assertions (RLS, CRUD, replay, atomicity, cascade).`);
  } finally { await db.close(); }
}
main().catch(error => { console.error(error); process.exitCode = 1; });
