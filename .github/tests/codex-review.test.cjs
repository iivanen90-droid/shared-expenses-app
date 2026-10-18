const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { test } = require('node:test');
const { join } = require('node:path');

const workflow = readFileSync(join(__dirname, '../workflows/codex-review.yml'), 'utf8')
  .replace(/\r\n/g, '\n');
const script = workflow.split('          script: |\n')[1]
  .split('\n').map(line => line.replace(/^ {12}/, '')).join('\n');
const execute = new (Object.getPrototypeOf(async function () {}).constructor)(
  'github', 'context', 'core', 'process', script,
);

async function run({ comments = [], attempt = '1', action = 'synchronize',
  current = {}, failPost = false } = {}) {
  const posted = [];
  const messages = [];
  const context = {
    repo: { owner: 'example', repo: 'expenses' },
    payload: { action, pull_request: { number: 3, head: { sha: 'current' } } },
  };
  const github = {
    paginate: async () => comments,
    rest: {
      pulls: { get: async () => ({ data: {
        state: 'open', draft: false, head: { sha: 'current' }, ...current,
      } }) },
      issues: {
        listComments: () => {},
        createComment: async request => {
          if (failPost) throw new Error('API unavailable');
          posted.push(request);
        },
      },
    },
  };
  await execute(github, context, { info: message => messages.push(message) },
    { env: { REVIEW_RUN_ATTEMPT: attempt } });
  return { posted, messages };
}

const existing = { user: { login: 'github-actions[bot]' },
  body: '@codex review\n\n<!-- codex-review:current -->' };

test('review requests cover PRs into develop and main', () => {
  assert.match(workflow, /branches: \[develop, main\]/);
  assert.match(workflow, /types: \[opened, reopened, synchronize, ready_for_review\]/);
});
// Evaluate the actual workflow group expression for the competing run contexts.
function groupFor(sha, attempt = 1, number = 3) {
  const template = workflow.match(/^  group: (.+)$/m)[1];
  const github = { run_attempt: attempt,
    event: { pull_request: { number, head: { sha } } } };
  return template.replace(/\$\{\{(.*?)\}\}/g, (_, expression) =>
    new Function('github', 'format', `return (${expression});`)(
      github, (template, value) => template.replace('{0}', value),
    ));
}

test('new automatic pushes share a cancellation group within one PR', () => {
  assert.equal(groupFor('old'), groupFor('new'));
  assert.notEqual(groupFor('new', 1, 3), groupFor('new', 1, 4));
  assert.match(workflow, /cancel-in-progress: true/);
  assert.match(workflow, /REVIEW_RUN_ATTEMPT: \$\{\{ github\.run_attempt \}\}/);
});

test('a stale manual retry cannot cancel or replace a new automatic run', () => {
  assert.notEqual(groupFor('old', 2), groupFor('new', 1));
});
test('manual retries for different heads cannot cancel each other', () => {
  assert.notEqual(groupFor('old', 2), groupFor('new', 2));
});
test('manual retries for the same head remain serialized', () => {
  assert.equal(groupFor('current', 2), groupFor('current', 3));
});
test('a new head receives a review request', async () => {
  const { posted } = await run({ comments: [{ ...existing,
    body: '<!-- codex-review:previous -->' }] });
  assert.equal(posted.length, 1);
  assert.equal(posted[0].body, existing.body);
  assert.equal(posted[0].issue_number, 3);
});
test('ordinary duplicate events do not post twice', async () => {
  assert.equal((await run({ comments: [existing] })).posted.length, 0);
});
test('Re-run jobs retries even when an unaccepted request already exists', async () => {
  assert.equal((await run({ comments: [existing], attempt: '2' })).posted.length, 1);
});
test('reopening a PR allows an explicit retry', async () => {
  assert.equal((await run({ comments: [existing], action: 'reopened' })).posted.length, 1);
});
test('an unrelated author cannot suppress the request with a marker', async () => {
  assert.equal((await run({ comments: [{ ...existing,
    user: { login: 'someone-else' } }] })).posted.length, 1);
});
test('a stale run or manual re-run never posts for a newer head', async () => {
  for (const attempt of ['1', '2']) {
    assert.equal((await run({ attempt, current: { head: { sha: 'newer' } } })).posted.length, 0);
  }
});
test('closed and draft PRs are skipped even on re-run', async () => {
  for (const current of [{ state: 'closed' }, { draft: true }]) {
    assert.equal((await run({ attempt: '2', current })).posted.length, 0);
  }
});
test('a comment API failure fails the job so it can be retried', async () => {
  await assert.rejects(run({ failPost: true }), /API unavailable/);
});
