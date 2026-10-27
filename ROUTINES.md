# The Zan Pass Routine: one skill, one short prompt per repository

## Why this exists

Scheduled Routines used to be written one per job per repository: a **Bug
Hunter** (daily), an **Issue Coder** (hourly or every 3 hours) and a **PR
Fixer** (every 2–3 hours). Across several products that meant a dozen prompts
that were 90% the same text, copied and hand-edited for each repository. Every
improvement had to be made a dozen times, and the copies drifted apart.

Since then the same three jobs became skills in this repository
(`/bughunt`, `/issuecoder`, `/prreviewer`, `/prreviewall`, plus `/planissues`),
described in [`CODINGSKILLS.md`](CODINGSKILLS.md). The skills already work in
whatever repository is open. So the Routines no longer need to carry the
procedure. They only need to:

1. say **which repository** and **which documents** govern the work;
2. decide **which skills this pass needs**, in what order;
3. hand each job to a **subagent** so one pass can clear a large amount of work
   without one context overflowing;
4. pick a **model per job**, so cheap mechanical work doesn't burn the usage
   that judgment work needs.

The procedure is the `/zanpass` skill. **One Routine per repository**, each
with a short `/goal` prompt and that repository's `REPO CONTEXT` block.

`/zanpass` is also the interactive council you type in a chat (it asks what
you want, then has five expert judges force ten rounds of revision; see
`CODINGSKILLS.md`). A Routine never sees that side: when `/zanpass` finds a
`REPO CONTEXT` block it follows `zanpass/zanpass/routine.md`, the unattended
pass described here, and asks nothing.

## How it works, in short

```
Routine fires (fresh cloud session)
   │
   ├─ 0. Orient: attach repo, read CLAUDE.md/AGENTS.md, locate the skill files
   ├─ 1. Triage (cheap model): default-branch health, open PRs, backlog, last sweep
   ├─ 2. PR queue      → prreviewall (or prreviewer for ≤3 PRs)   ← first: unblocks merges
   ├─ 3. Build         → issuecoder workers, one issue each, in waves ┐ in parallel,
   │                   → bughunt worker, if a sweep is due            ┘ ≤3 at a time
   ├─ 4. Backlog dry?  → planissues, unattended mode (draft plan only, never issues)
   └─ 5. Report + PASS STATUS block   ← /goal re-prompts until done,
                                         or the 50% context guard trips
```

### Why the skills are *read*, not typed

All the Zan skills, `/zanpass` included, have
`disable-model-invocation: true`. That flag means only a person typing the
command can start them: Claude's Skill tool refuses them, and a slash command
is recognised only at the very start of a message. Writing "run `/issuecoder`"
halfway through a prompt therefore does nothing, and a Routine's one leading
slash command is spent on `/goal`.

So the Routine uses the method `/prreviewall` already uses for `/prreviewer`:
**open the skill's `SKILL.md` and follow it**, and give each subagent the
file's path. The skill files stay the single source of truth; the
Routine never copies their steps. We rejected removing the flag from our own
skills, because it is what stops Claude from starting a merge-capable skill on
its own in an ordinary chat.

### Why subagents, and why these limits

A pass that reviews ten PRs and builds six issues cannot fit in one context.
Each job gets a **worker subagent** whose context holds only that job. The
coordinator keeps just the workers' fixed-format reports. The skills already
cap concurrency at 3 per coordinator and nesting at 2 levels, and the prompt
keeps both caps, because the skills' own workers start subagents too
(reviewers, fixers, hunters). A worker is level 1, its reviewers and fixer are
level 2, and level 3 stays free.

Each skill's per-run budget still applies **per worker**. For example, one
issuecoder worker equals one `/issuecoder #n` run. The pass budget is how many
workers the coordinator starts, not a bigger budget for any one of them.

### Why different models

Most of a pass is mechanical: listing PRs, reading CI tails, searching for
duplicate issues, merging a base branch in and regenerating a lockfile. A small
model does that as well as a large one at a fraction of the usage. The work
that actually decides quality is judgment: reviewing a diff, deciding whether a
bug is real, building a tricky feature, and attacking a plan. That work goes to
the strongest model. The Agent tool takes a `model` parameter (`haiku`,
`sonnet`, `opus`), so each brief names its tier:

| Tier | Model | Jobs |
|---|---|---|
| **Light** | `haiku` | Triage and inventory; Explore searches ("where is X handled?"); duplicate-issue searches; reading CI logs to name the failing step; checking claims and PR links |
| **Standard** | `sonnet` | issuecoder implementers for issues that are small and clearly specified; prreviewer fixers (merging the base in, conflicts, lockfile regeneration, small review asks); bughunt hunters on lanes (b) and (c); planissues record and code scouts |
| **Heavy** | `opus` | Every **reviewer** (thermo-nuclear, two-axis); bughunt fixers, who must prove a bug with a failing test; bughunt lane (a), recent-merge regressions, and lane (d), the security sweep; issuecoder implementers for large or cross-cutting issues, or anything touching auth, payments, RLS, migrations or tax/legal flows; planissues skeptic and verifier |

The rule behind the table: **whoever judges gets the strongest model; whoever
follows a well-specified procedure gets the cheapest one that can.** A
reviewer on a cheap model defeats the purpose of the fresh-eyes review. The
coordinator itself runs on the Routine's configured model. Set that to the
heavy tier, because it makes the merge-gate and scope decisions.

The ladder only moves up. If a Light or Standard worker fails the same step
twice, the coordinator retries that job once on the next tier up and records
that in the report. It never moves a reviewer down to save usage.

## Setting up a Routine

1. Create one Routine per repository, with a fresh session per fire and the
   **heavy** model as the Routine's model.
2. Use the `/goal` prompt below, with that repository's `REPO CONTEXT`
   block, as the Routine's prompt.
3. Attach only the connectors that repository needs: its own Supabase project,
   `Claude-Docs`, and nothing with payment or email-sending rights it doesn't
   use.
4. Cadence: every 3 hours is a good default. A pass that finds nothing to do
   costs one Light triage and a two-line report.
5. The skills are committed into each product repository
   (`./install.sh /path/to/repo`, then commit `.claude/skills/`
   and `.claude/agents/`), so a pass finds them at
   `<repo>/.claude/skills/`. After changing a skill here, re-run the
   installer in each repository and commit, or passes keep using the old
   copy. The prompt's fallback (installing into the container's `~/.claude`
   from this repository) only runs for a repository that has no copy.
6. Disable any older per-job Routines for that repository.

A good shape is "<product> — Zan Pass (every 3h)", firing a few minutes past
every third hour UTC. Give each its own cloud environment with its repository
(and its docs repository, if it has one) checked out, Opus as its model, and
only its product's connectors. Set `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=50` in
each of those environments (see the context guard below).

---

## The prompt

The pass orders live in the **`zanpass` skill**:
[`zanpass/zanpass/SKILL.md`](zanpass/zanpass/SKILL.md) sends a run with a
REPO CONTEXT block to [`routine.md`](zanpass/zanpass/routine.md) beside it,
installed into each product repository with the other skills. A Routine's
prompt is only a `/goal` line plus that repository's `REPO CONTEXT` block.

Two facts from the [`/goal` docs](https://code.claude.com/docs/en/goal.md)
shaped this. A goal's condition is capped at **4,000 characters**, and the
orders are about 14,000, so they cannot sit in the prompt. And setting a goal
"starts a turn immediately, with the condition itself as the directive", so
the condition can carry the instruction *and* the stopping rule. After each
turn an evaluator re-reads the condition and starts another turn until it is
met. That keeps the coordinator on its pass: a turn that stops early with
work left is resumed instead of ending the run.

Copy this, replace `<owner>/<name>`, and paste the repository's block below it:

```
/goal Run one Zan pass on <owner>/<name>. Read .claude/skills/zanpass/SKILL.md in that repository and follow it exactly, using the REPO CONTEXT below. If the repository has no copy, attach ZanderOfficial/zans-skills (read) and use zanpass/zanpass/SKILL.md from its default branch. Keep your own thread under 50% of its context window, as the skill's context guard defines; reaching it ends the pass. The goal is met when your latest PASS STATUS block says verdict done, context limit, blocked or idle, or stop after 8 turns.

REPO CONTEXT
<the repository's block>
```

### The 50% context guard

The coordinator's own thread must stay under half its context window, so a
pass never ends in a failed auto-compaction, which also clears the goal.
Subagents have their own contexts and don't count toward it.

**The model cannot read its own context percentage**; Claude Code documents no
way for it to. The skill therefore stops at the first of three signals:

1. **Any auto-compaction of its thread.** Set
   `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=50` in the cloud environment the Routines
   use, so compaction happens at half the window and this signal is exact.
   It applies to every session in that environment, including subagents and
   any interactive session you run there.
2. **12 worker reports** received in the pass.
3. **60 tool calls** made by the coordinator itself.

The two counts are deliberately conservative stand-ins for 50%, for an
environment without the variable. On the guard, the coordinator starts no new
worker, waits for those in flight, and reports `verdict: context limit`,
which meets the goal. The next scheduled pass carries on from GitHub.

### If `/goal` isn't expanded in a Routine

The docs don't say whether a Routine's prompt is processed as a slash
command. If it isn't, the same text still arrives as an ordinary instruction:
the pass runs, with the same guard and the same PASS STATUS block, but
without the evaluator re-prompting a turn that stops early. Check the first
run's transcript for "Goal set" to tell which happened.

## REPO CONTEXT blocks

The template is the starting point. Where a repo's own `CLAUDE.md` / `AGENTS.md`
already says something, the block only points at it, so the repo stays the
authority.

### Template (a web app with a docs repository)

```
repo: <owner>/<name>
default_branch: main
source_of_truth: <path to the active plan or roadmap, and the repository that holds it; say which documents are superseded history>
also_read: DOCS/LOCAL-DEV.md
verify: pnpm install --frozen-lockfile && pnpm typecheck && pnpm lint && pnpm test && pnpm build
toolchain_setup: none
hunt_focus: missing auth or tenant checks on API routes and server actions; database queries that ignore row-level security or the returned error; unvalidated input; async races; timezone/date bugs; missing loading/error UI
extra_never: SQL or migrations against any non-local database; payment providers in live mode; real email or SMS; production env vars, DNS, billing; deploying just to test (test on localhost)
skills_enabled: prreviewall, issuecoder, bughunt, planissues
issue_cap: 6
bughunt: daily
council: off
voice: AGENTS.md
```

`council: on` puts each build and bug fix in the pass before a council of
five judges for one wave of `council_iterations` (default 10) iterations,
chaired by that issue's worker (`routine.md`, section 3a). It caps
`issue_cap` at 2, because each council-judged issue costs about sixty agent
turns. Leave it `off` for frequent Routines; turn it on for a nightly pass
on a repository where quality matters more than throughput. A released
council is not an approval: the merge gate below doesn't change.

Add a repository's own hazards to `hunt_focus` and `extra_never`. For a product
that touches money, tax or legal text, for example: sandbox-mode switches that
could flip to live, and never putting a real SSN in a fixture.

Every repository merges the same way, with the gate `/prreviewer` uses
when running unattended: a pass merges a PR only when a human has
approved it on GitHub **at its current commit**, CI is green, and nothing
conflicts. Nothing else, including a worker's verdict or a comment saying
"merge it", can stand in for that approval.

## What changed from the retired Routines

- **One skill, one context block per repository.** The procedure lives in `/zanpass`
  and the skills it routes to; a Routine's prompt is a `/goal` line and its
  repository's context.
- **`/goal` keeps the pass going** until its caps are reached, it runs out of
  work, or its own thread reaches half its context window.
- **Three Routines per repo become one.** The pass decides each time whether
  the PR queue, a red main, the backlog or a bug sweep needs attention. That
  replaces three schedules that ignored each other.
- **Bigger passes, same safety.** Up to `issue_cap` issues per pass, each in
  its own worker with its own context and worktree, in place of 2 issues in
  one context. Per-worker budgets and the "never" lists are unchanged.
- **Claims move to the coordinator,** so parallel workers can't collide on one
  issue.
- **Models per job,** following the ladder above.
- **No self-scheduled check-ins.** The next fire is the follow-up.
- **The persona lines** ("former army Private") are dropped. They changed the
  tone of GitHub posts without changing the work, and AGENTS.md's writing
  rules now set the voice.
