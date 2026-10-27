# Building a plan in waves (what /suprpas used to do)

`/zanpass` (SKILL.md, step 5) reads this file when a **Plan** run ends with
the user choosing "build it now", or when it is started as
`/zanpass build <plan path | milestone:<name>>` (which is what `/suprpas`
now runs). It takes a plan whose issues are published and builds every one of
them, in dependency-ordered waves of worker subagents, with every issue
judged by its own council. This used to be the `/suprpas` skill. It moved here
so that planning, building, reviewing and merging go through one command and
one set of gates.

Everything in SKILL.md still applies: the house rules, the model ladder, the
subagent rules, the rules of engagement and the merge rules. This file adds
only what building many issues needs.

## What a Plan run adds for the build

When the plan is going to be built this way, the Plan option's worker runs
`/planissues` with four additions, which the Plan council's *Delivery planner*
seat holds it to:

1. **Foundations.** In `/planissues` step 5, every phase names the pieces
   everything else in it stands on (a schema and its RLS policies, an app
   shell and routing, a design system, a game's core loop, input, scene and
   save systems). Foundations become the first issues of that phase.
2. **Issues sized for one worker.** Each issue fits one `/issuecoder` or
   `/designflow` run: a vertical slice, one PR, reviewable in one sitting.
   An issue that needs UI work is labelled `design` if the repository has
   that label.
3. **A Wave column** in the breakdown table (see B1). The user approves the
   waves together with the breakdown, in one question.
4. **A `## Build ledger` section** in the plan (see "The ledger"), empty
   until building starts.

**One plan per build.** If `/planissues` splits the idea into sibling plans,
the user picks which one to build; the others stay drafts.

## B1. The wave map

A **wave** here is a set of issues whose blockers are all merged, or are in
an earlier wave that merges first. (A council *wave* is ten iterations on one
piece of work; the two kinds nest: each issue in a build wave gets its own
council waves.) Build the map from the Issue map's "Blocked by" edges:

- **W0, foundations:** they run **one at a time, on opus**, and each merges
  before the next starts, because every later wave stands on them. Two
  foundations that share no files may run in parallel if the user agrees at
  the breakdown gate.
- **W1…Wn:** each holds the issues whose blockers are all in earlier waves.
  Issues touching the same files go in different waves, or run one after the
  other, so their PRs don't conflict.
- **Route each issue:** labelled `design`, or mainly a screen, flow or
  component → the **Design** path. Everything else → the **Code** path. An
  issue with both halves gets Code for the data path first, then Design for
  the UI, as two PRs, unless it is small.
- **Length per issue:** foundations and anything the plan calls
  architecture are **long** (the user sees every council wave). Everything
  else is **short**, unless the user says otherwise at the breakdown gate.

Show the wave map as a table: wave, issue, path, length, model, blocked by.
It is part of the breakdown gate. Write it into the ledger.

## B2. Foundations of a new project

When the code repository is empty or nearly so, W0 starts with one
**scaffold** issue: layout, toolchain, check commands (`verify`), a first
passing test, and `DOCS/LOCAL-DEV.md`, so every later worker can run the
project on `localhost`. For a game, the scaffold also proves the loop runs: a
window or canvas, a fixed-timestep update, input, and one headless test of
game state. A design system, if there is none, is a W0 Design issue, and its
direction gate is the user's.

Changing CI configuration is on the "ask first" list even in a new
repository: the scaffold proposes a workflow file in its PR, and the user
approves that part explicitly at the merge question.

## B3. Running a build wave

1. **Claim before dispatch.** Do `/issuecoder`'s steps 1, 3 and 4 (recon,
   pick, claim) for the whole wave, posting each claim before dispatching, so
   no Routine or other session takes the same issue. Claim design issues the
   way `/designflow` step 2 does.
2. **Each issue runs the SKILL.md path for its option** (steps 3 and 4:
   council, then the bug-hunter and reviewer passes), with the working branch
   set to the default branch, so each issue lands as its own PR. Design
   issues stop for the user's direction choice first.
3. **Concurrency.** At most 3 issues are in flight at once. A council sitting
   holds five judges, so while one issue's council sits, at most one other
   worker may be building; the third waits. Never run two councils at the
   same moment.
4. **Human questions.** When a report has NEEDS A HUMAN, ask the user, write
   the answer on the issue, and continue that worker with SendMessage.

A worker that fails or runs out of context is recorded `failed` in the ledger
and retried once, one tier up. Don't redo its job in your own thread.

## B4. Close the wave and merge

When every issue in the wave has a PR that the council released and the
final passes cleared, or a written blocker, update the ledger and show **one
table for the wave**: PR, issue, what it does in a line, checks, council
votes, head SHA. Then ask once, as an AskUserQuestion checklist, which to
merge into the default branch. This is the explicit permission SKILL.md's
merge rules require; apply the prreviewer merge gate to each PR exactly
(SKILL.md, step 5). The next wave starts only after the merges it depends on.

## B5. Between waves

- Re-check the default branch. If a merge turned it red, the next job is one
  `/issuecoder` worker told to do its step 2 (fix the default branch) only.
- If the work showed the plan was wrong (a blocker nobody saw, an API that
  doesn't behave as documented), stop dispatching, write it into the plan's
  Open threads, and ask the user. Replanning mid-build is normal; building on
  a plan you know is wrong is not.
- Don't schedule `send_later` check-ins and don't leave PR subscriptions
  behind: the build polls GitHub at each wave boundary.

## V. Integration

When the last wave has merged:

1. **Bug sweep of the merged result:** one `bughunt` worker, arguments
   `since <the build's start date>`, with its usual budget. Its `Bug sweep`
   PR runs the **Bughunt** path (council, then reviewer pass) like any other.
2. **Whole-feature review,** one fresh opus reviewer, per exit criterion of
   the plan: `met`, `not met: <what is missing>`, or `unverifiable`, plus
   what no per-PR council can see: duplicated concepts across PRs,
   inconsistent naming, dead code left by earlier waves, missing end-to-end
   tests.
3. **Visual pass,** when there is UI: one `/designflow` critic worker (no
   builder) screenshots every screen the build touched at mobile and desktop
   and runs its critics across them together, for consistency between screens
   built in different waves.
4. Findings become new issues **only with the user's approval**.
5. Update the plan: ledger complete, exit criteria marked, an Iteration log
   entry. Ask whether to mark the plan `status: active`.

## The ledger

The plan's `## Build ledger` section is the build's memory. Commit it to the
plan branch at every wave boundary and every gate answer:

```
## Build ledger
started: <date>   code repo: <owner/repo>   plan branch: <branch>
| wave | issue | path | length | model | result | PR @ sha | council | merged |
gates: <date> plan ready; <date> breakdown + waves approved; <date> W0 merges …
current: <wave and step>   next: <exactly what the next turn does>
```

## Using with /goal

When the issues are published, hand the user the lines to paste (only they
can set a goal):

```
/goal every issue in <plan file name>'s Issue map is merged, has a released PR waiting for your merge answer, or has a written blocker; and integration has reported; or stop after <N> turns
/zanpass build <plan path>
```

`N` is about 3 turns per wave, plus 1 per issue, plus 3 for integration
(councils make each issue slower than it was under `/suprpas`). The goal keeps
the build moving between gates; every gate still waits for the user, and no
goal satisfies the merge question.
