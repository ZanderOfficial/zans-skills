# Coding skills

A **skill** is a packaged set of instructions that Claude Code loads when you
type its slash command (for example `/bughunt`), or when Claude decides the
skill fits the task at hand. Skills let a workflow that works well once be
repeated the same way in every repository and every session, instead of being
re-explained in each chat.

This page lists the skills Zan uses. There are four kinds:

1. **Our own:** `/bughunt`, `/issuecoder`, `/prreviewer` and `/prreviewall`,
   built from the scheduled Routines, plus `/designflow` for UI work and
   `/planissues` for turning an idea into a plan and then into issues.
2. **Community coding skills** we reviewed and vendored.
3. **Design skills** we reviewed and vendored, which pair with Claude Design.
4. **Built-in Claude Code skills** we should be using more than we do.

It also explains how they **stack**, and how to install them.

Everything below lives in **one folder, this repository**,
organised by the six skills:
- `bughunt/`, `issuecoder/`, `prreviewer/`, `prreviewall/`, `designflow/`
  and `planissues/` each hold that skill plus the stacked skills only it uses;
- `shared/` holds the stacked skills several of them use.

[`README.md`](README.md) has the full tree, plus
the sources, licenses and local changes of every vendored skill. The folder is
also a Claude Code plugin, published through this repository's
`.claude-plugin/marketplace.json`.

---

## 1. The six Zan skills

Per-repository Routines were each hard-wired to a single repository. The Issue
Coder, the Bug Hunter and the PR Fixer ran against one product each. These skills do the
same jobs in **whatever repository is open**, and they keep the discipline
that let the Routines survive unattended runs:

- every build and test log is piped through `tail`;
- each run has a budget;
- work is pushed after each finished item;
- each skill has a hard "never" list: no pushing to main, no force-pushes, no
  production databases, no secrets.

The retired per-repository Routines are replaced by one scheduled prompt that
routes each pass to these skills through subagents, choosing a model per job.
That prompt is a `/goal` line that runs the `/zanpass` skill: see
[`ROUTINES.md`](ROUTINES.md).

When you are in the chat, **`/zanpass` is the one command to start with**
(it replaces `/suprpas` and the earlier `/fledgepass`). It asks what you
want (Plan, Bughunt, Coder, Reviewer or Designing), triages it, and has the
matching skill's worker do it while a **council** of five expert judges
forces at least ten rounds of criticism and revision, before a bug-hunter
pass, a reviewer pass and the merge into your working branch. See
[`/zanpass`](#zanpass-plan--bughunt--coder--reviewer--designing-target) below.

When one starts, it reads the repository's own `CLAUDE.md` / `AGENTS.md` and
detects its package manager, test scripts and default branch. You start each
of the six yourself. Claude never runs them on its own.

### `/bughunt [path | feature | PR | since <date>]`

**Why it exists.** Bugs are found fastest right after they merge, and a "bug"
nobody can demonstrate wastes everyone's time.

**What it does:**

1. Branches `claude/bugsweep-<date>` and checks that the default branch is
   green. A red default branch is bug #1.
2. Hunts in a fixed order:
   - regressions in PRs merged in the last 48 hours: missing auth or tenant
     checks, ignored database errors, null states, races, timezones;
   - the running app, driven with Playwright when it starts without secrets;
   - open `bug` issues;
   - high-risk code such as auth, payments and deletion.
3. **Proves every bug with a test that fails.** Suspicions that can't be
   reproduced go in the report marked "unproven". They never become issues.
4. Fixes at most 3 small bugs (under about 50 lines each) in one
   `Bug sweep <date>` PR, with a Bug | Root cause | Fix | Test table.
5. Files at most 5 issues for the rest, after searching open and closed issues
   for duplicates.

**Stacks:** `thermo-nuclear-review`, `diagnosing-bugs`, `systematic-debugging`,
`test-driven-development` and `verification-before-completion`.

### `/issuecoder [#12 #15 | label:ready | milestone:M2]`

**Why it exists.** It works through the backlog in small, reviewable pieces:
one issue, one branch, one PR, each one tested.

**What it does:**

1. Fixes a red default branch first.
2. Picks untaken issues. An issue counts as taken when an open PR references
   it or someone claimed it in the last 6 hours. Picking order:
   - the `ready` label first,
   - then the lowest milestone,
   - then the smallest and clearest issue.
3. Claims the issue with a comment, and builds on `claude/<issue#>-<slug>`
   with tests that fail without the change.
4. Verifies with typecheck, lint and tests, then merges the default branch in.
5. Opens a PR starting `Closes #<n>` that explains why, what changed and how
   it was tested.
6. Stops at 2 issues per run.

When you are in the chat, it asks about a genuinely ambiguous issue. When it
runs unattended, it decides and records its reasoning on the issue.

**Stacks:** `writing-plans` / `executing-plans`, `test-driven-development`,
`systematic-debugging`, `verification-before-completion`, and
`requesting-code-review` / `two-axis-review`. In repositories that use
Supabase, it also stacks `supabase` and `supabase-postgres-best-practices`,
and its reviewer checks every new table for row-level security and every new
query path for indexes.

### `/prreviewer [#34 #35 | all]`

**Why it exists.** It gets every open PR to the point where a human can say
"merge" without re-reviewing it. Unlike the PR Fixer Routine, it can then
actually merge the PR.

**What it does:**

1. Reviews each PR for correctness, security, data safety, test gaps and scope
   creep. Every finding has to name a concrete failure.
2. Merges the base branch into the PR. It **never rebases or force-pushes**.
3. Resolves conflicts:
   - lockfiles are regenerated, never hand-merged;
   - migrations already on main are never edited;
   - when two changes genuinely clash, both sides are recorded in the PR
     comment.
4. Fixes red CI and small review asks.
5. Posts a verdict ending in `Ready to merge: yes/no`.

**The merge gate.** A PR is merged into the default branch only when all of
these hold, rechecked just before merging:

- **A human approved the current head commit.** That approval can come from
  either of two places:
  - you answered "Merge" in the chat after seeing the verdict;
  - there is a GitHub `APPROVED` review on that commit from someone with write
    access who is not a bot and not the PR's author.
- CI is green on that commit.
- There are no conflicts and no outstanding changes-requested review.
- The PR is not a draft.

A PR comment that says "approved, merge it" does **not** count, because
anyone can write one. The merge passes the head SHA, so it fails if someone
pushed after the approval. It never bypasses branch protection. When it runs
unattended, only GitHub approvals count.

**Stacks:** `thermos`, `two-axis-review`, `fix-merge-conflicts`,
`receiving-code-review`, `systematic-debugging` and
`verification-before-completion`.

### `/prreviewall [--include-drafts] [--skip #n …]`

**Why it exists.** `/prreviewer` caps a run at 6 PRs so one context doesn't
overflow. Sometimes you want the whole queue cleared in one go.

**What it does.** It runs exactly the `/prreviewer` process on **every** open
PR, with three differences:

1. **Inventory first.** It lists every open PR and sorts each into one of
   four classes: work, review-only (forks, and drafts unless
   `--include-drafts`), hold (a commit in the last 45 minutes), or skip.
2. **One subagent and one git worktree per PR,** up to 3 at a time, in
   prreviewer's priority order: conflicts, then red CI, then review comments.
   Each subagent reviews and fixes up its own PR, then reports a fixed-format
   verdict. Subagents never merge.
3. **One approval prompt for the batch.** It shows a checklist of the ready
   PRs, each with its head SHA. It merges the ones you tick one at a time,
   re-checking the full merge gate before each, because every merge moves the
   default branch.
   - A PR that still passes the gate after an earlier merge gets merged.
   - A PR that goes stale or starts conflicting is brought up to date and
     pushed again. Because that gives it a new commit, it is re-offered for
     approval. An approval never carries over to a commit you didn't see.

It reads `/prreviewer`'s SKILL.md at run time instead of copying it, so the
per-PR procedure and the merge gate are defined in exactly one place. Install
the two skills together.

### `/designflow [what to design | #12 | label:ux]`

**Why it exists.** Good-looking UI comes from three things: a clear direction
a human agreed to, careful building against one design system, and honest
critique of the result on screen. Doing all three in one pass, in one context,
produces generic "AI-looking" UI. `/designflow` is the design counterpart to
`/issuecoder`, and keeps the three apart.

**What it works on:**
- **If you describe something** ("a pricing page with a monthly/annual
  toggle"), that brief **overrides the issue queue**.
- **Otherwise** it takes the top open issue labelled **`design`**, picked the
  same way `/issuecoder` picks: `ready` first, then the lowest milestone, then
  the smallest.
- **One piece of design work per run.**

**How it works:**

1. **Finds the visual source of truth,** in this order: Claude Design (if the
   repo is synced with `/design-sync`), then `DESIGN.md` / `PRODUCT.md`, then
   the Tailwind, shadcn and theme files in the code.
2. **A direction subagent proposes 2–3 directions** using Impeccable
   (`shape`), `frontend-design` and, only for a product with no design system
   yet, UI/UX Pro Max.
   - **When you're in the chat, you pick one.** The directions are shown as a
     Claude Design canvas where available, so you can tweak them there.
   - **Unattended,** it stays close to the existing system and never invents
     a new identity.
3. **A builder subagent in its own worktree builds it for real:**
   - all states (empty, loading, error, success), keyboard and screen-reader
     support, responsive layout;
   - web: `shadcn` (pinned), `vercel-react-best-practices`, `vercel-composition-patterns`;
     native: the Expo skills;
   - data: `supabase`; motion: Emil Kowalski's skills;
   - polish: Impeccable's `polish`, `typeset`, `colorize` and `harden`.
4. **Screenshots with `webapp-testing`** on localhost, never a deploy, at
   mobile and desktop, in light and dark, for each state.
5. **Three fresh critics, in parallel:**
   - **design:** Impeccable `critique` / `audit`;
   - **accessibility and interface rules:** Vercel's guidelines plus
     ibelick's accessibility and metadata fixes;
   - **motion and performance:** Emil's `review-animations` plus ibelick's
     motion-performance fixes.

   The builder then gets at most 2 fix rounds.
6. **A PR with before/after screenshots.** It lists the chosen direction and
   the rejected ones, the tokens and components used, and any new
   dependencies or assets with their licenses.

It never calls Claude Design's sync tool itself. `/design-sync` is yours to
run. When the repo isn't synced, it recommends running it, and when it
finishes it offers to open the result in Claude Design.

### `/planissues [braindump | plan.md | issues plan.md]`

**Why it exists.** Every other skill here starts from an issue, and an issue
is only as good as the plan it came from. The plans that produced Zan's
best issues were made the same way each time: a braindump, a discussion about
whether it is realistic, research, a written plan, many rounds of editing
and more research, and only then issues. Sometimes the idea turned out to be
two or three ideas, and each got its own plan so that its last round could
go deep. `/planissues` makes that way of working repeatable.

**What it does:**

1. **Captures the braindump** nearly word for word in the plan, and writes
   back its understanding, separating what you said from what it assumes.
2. **Discusses it in question rounds** (`grilling`): numbered questions, each
   with a recommended answer. The first round is always about realism:
   feasibility, build and running cost, what could kill it, and whether it
   contradicts an active plan. It looks facts up itself and pushes back when
   the idea is unrealistic.
3. **Researches in parallel:** a code scout (what exists in the product's
   repository), a record scout (the active documents, and the issues, PRs and
   milestones), and an outside researcher (`research`: vendors, APIs, prices,
   licences, from primary sources only). Then a **fresh skeptic** that saw
   none of the discussion attacks the idea.
4. **Organises it, and proposes a split** when the idea holds parts that
   could ship alone, belong to different repositories, or move at different
   speeds. You decide the split.
5. **Writes the plan** into the knowledge base (`status: draft`), in the shape
   of Zan's existing plans: why it exists, what was found, whether it is
   realistic, decisions with the alternatives that lost, phases with exit
   criteria, what is not built, open threads, and an iteration log.
6. **Iterates as many rounds as you want.** Each round re-reads the file
   first, so your own edits win, sends a researcher for every new question,
   and logs what changed and why.
7. **Readiness gate.** A verifier re-checks every concrete claim in the plan
   against the code and sources as of today, and a fresh skeptic reviews it
   again. Every open question becomes a decision, a `decision` issue, or out
   of scope. You confirm the plan is ready.
8. **Issues.** It slices the plan (`to-tickets`) into milestones, an epic per
   phase, and issues sized for one `/issuecoder` run, with blocking edges. You
   approve the breakdown as a table. Then it publishes them in the house
   format (see `planissues/planissues/issue-format.md`), writing each issue
   number back into the plan as it goes, so a second run never creates one
   twice.

It never publishes an issue before both gates, never publishes unattended,
and never marks a plan `active` or another document superseded without you.
Plans go in the docs repository (or `docs/plans/`); issues go in the product's code repository.

**Stacks:** `grilling`, `research` and `to-tickets` (Matt Pocock).

### `/zanpass [plan | bughunt | coder | reviewer | designing] [target]`

**Why it exists.** Each skill above does one job well, but you had to know
which to start, and each judged its own work once, with one reviewer. One
reviewer, run once, catches what is obviously wrong and misses what is merely
weak: a name that will confuse the next reader, a screen that works but feels
unfinished, a plan that is buildable but not the simplest. `/zanpass` puts
every kind of work through the same path, and puts a council of specialists
on it for ten rounds, so "passes review" becomes "nothing material left to
improve". It replaces two older coordinators, the supervised Super-Pass
(`/suprpas`) and the earlier `/fledgepass`, and everything is in one file.

**What it does:**

1. **Asks what you want.** Plan, Bughunt, Coder, Reviewer or Designing; then the target, chosen from candidates a cheap
   subagent found; then *short* (it runs to the end) or *long* (you see every
   wave of 10 iterations); then how it lands (merge into your working branch
   and push, open the PR and stop, or ask at the end).
2. **Triages.** A haiku subagent reads the target, its blockers and claims,
   CI, and what it touches. You get a **triage card**: the worker and its
   model, the five judges, the branch, the guardrails the work would touch,
   and the cost of a wave. Nothing is written to GitHub until you say go.
3. **Seats the council.** A worker runs the option's skill (`/planissues`,
   `/issuecoder`, `/designflow`, `/bughunt` or `/prreviewer`). Five opus
   judges, who did none of the work, judge each version at once, read-only;
   the main session chairs, merges their findings into one list, settles
   disagreements, and sends the list back to the worker. **The council cannot
   release the work before the tenth iteration of a wave**, and releases it
   only with no blocks and at least four of five votes to pass. Early passes
   turn the remaining iterations into refinement, where "leave it" is a valid
   answer and churn is rejected. Long work stops for you after every wave.
4. **Runs the passes.** A fresh `/bughunt` pass on what the council
   released, then a fresh `/prreviewer` pass. Any change they push goes back
   to the council for one sitting.
5. **Lands it,** as you chose, and pings you with next steps. It merges into
   your working branch only if you chose that, and **never into the default
   branch without your explicit yes** for that PR at that commit, through the
   `/prreviewer` merge gate.

The councils, per option:

| Option | The five seats |
|---|---|
| Plan | product strategist, systems architect, data and security, delivery planner, house rules |
| Coder | correctness and security, code quality, spec fidelity, test engineer, house rules |
| Designing | design director, interaction and copy, accessibility, motion and performance, house rules |
| Bughunt | reproduction skeptic, root-cause analyst, fix minimalism, security, house rules |
| Reviewer | correctness and security, code quality, spec fidelity, merge readiness, house rules |

The **house rules** seat is the user's `AGENTS.md` rules (readable code,
writing that educates, the ask-before-proceeding guardrails), which every
worker and judge also gets verbatim. When the work touches Supabase, a native
app, a game loop or payments, one seat is swapped for that specialist.

**Also in the same skill:** a Plan can end with "Build it now", which builds the
published plan in dependency-ordered waves (foundations first, one at a time
on opus), each issue through its own council, with one merge question per
wave, then a bug sweep, a whole-feature review and a visual pass over the
merged result. And a Routine that passes a `REPO CONTEXT` block gets the
unattended scheduled pass ([`ROUTINES.md`](ROUTINES.md)),
where the council is off unless the block says `council: on`.

**Cost.** A wave is about ten worker turns and fifty opus judge turns. The
triage card says so before you start.

**Stacks:** everything its routed skills stack; each council seat loads the
ones listed in `zanpass/zanpass/SKILL.md`.

---

## 2. Community coding skills

These were chosen on 2026-09-26 from skills developers publicly report using.
All are MIT-licensed and copied at a pinned commit with their license.
`README.md` records the sources, the exact
changes we made to each, and the safety notes.

### Review

| Skill | Author | What it does |
|---|---|---|
| `/thermos` | Cursor | Runs the two reviews below as parallel subagents, then merges and de-duplicates their findings. |
| `/thermo-nuclear-review` | Cursor | A security and correctness audit of a branch's diff. It covers bugs, breakage elsewhere in the codebase, developer-experience regressions (env vars, ports, secrets) and feature-flag leaks. It reports high-priority issues only when it is certain, and reads PR bot comments only after finishing its own audit. |
| `/thermo-nuclear-code-quality-review` | Cursor | A deliberately harsh maintainability review. It looks for restructurings that delete complexity, files growing past 1,000 lines, spaghetti conditionals, weak types and leaky boundaries. |
| `/two-axis-review` | Matt Pocock (upstream name `code-review`) | Reviews the diff since a given point along two separate axes. **Standards:** the repository's documented rules plus a baseline of Fowler code smells. **Spec:** whether the code does what the originating issue asked. Keeping the axes apart stops a clean-looking diff from hiding that it built the wrong thing. |
| `receiving-code-review` | Jesse Vincent (superpowers) | How to take review feedback: check each ask technically before implementing it, and push back with evidence instead of agreeing to everything. |

### Debugging and testing

| Skill | Author | What it does |
|---|---|---|
| `systematic-debugging` | superpowers | Root cause before any fix. Reproduce the bug, form one hypothesis, test it with the smallest possible check, and only then fix. It ships with guides on tracing a root cause and on defence in depth, plus `find-polluter.sh` for finding the test that pollutes shared state. |
| `diagnosing-bugs` | Matt Pocock | For hard bugs and performance regressions. First build a tight, automatic loop that reproduces the bug. With a signal that shows it failing, the fix becomes mechanical. |
| `test-driven-development` | superpowers | Red, green, refactor, strictly: no production code until a test has failed for the right reason. |
| `verification-before-completion` | superpowers | Claude may not say "done", "fixed" or "passing" without running the check in that message and showing the output. |

### Planning and execution

| Skill | Author | What it does |
|---|---|---|
| `writing-plans` | superpowers | Turns a spec into a plan of bite-sized tasks, each with exact files, test-first steps and commands. Plans are saved to `docs/superpowers/plans/`. |
| `executing-plans` | superpowers | Carries out a plan task by task in this session. A ledger file lets a run that loses context resume, and each task is gated by TDD. It ends with one whole-branch review. |
| `subagent-driven-development`, `requesting-code-review`, `using-git-worktrees`, `finishing-a-development-branch` | superpowers | Vendored because `executing-plans` calls them: their scripts, the reviewer prompt, and the start and finish steps. They also work on their own. For example, `subagent-driven-development` runs a plan with a fresh subagent and reviewer per task. |
| `grilling` | Matt Pocock | Interviews you about a plan or idea as a tree of decisions, asked in numbered rounds, each question with a recommended answer. It looks facts up itself and leaves the decisions to you. |
| `research` | Matt Pocock | Sends a background agent to answer a question from primary sources, and writes the findings, with their sources, to a Markdown file. |
| `to-tickets` | Matt Pocock | Breaks a plan into thin vertical slices, each with the tickets that block it, and quizzes you on the breakdown before publishing. We removed its "type it yourself" flag so `/planissues` can stack it. |

### Merge conflicts

| Skill | Author | What it does |
|---|---|---|
| `fix-merge-conflicts` | Cursor | Resolves conflicts with minimal edits, keeping both sides when safe. It regenerates lockfiles, builds and tests, and summarizes the decisions. It never pushes. |

### Backend

| Skill | Author | What it does |
|---|---|---|
| `supabase`, `supabase-postgres-best-practices` | Supabase | Supabase platform work (auth, RLS, storage, edge functions, realtime), plus Postgres schema, migration, query and index rules. `/issuecoder` and `/designflow` stack them in Supabase repositories. |

**Considered and not vendored:**

- **Trail of Bits** (`variant-analysis`, `fp-check`, `differential-review`):
  excellent, but licensed CC-BY-SA-4.0, which is share-alike.
- **Anthropic `claude-security`:** proprietary. The built-in
  `/security-review` covers the same ground.
- **Karpathy guidelines:** the repository has no license file.
- **Matt Pocock `git-guardrails-claude-code`:** its hook would block the
  pushes `/issuecoder` has to make.
- **superpowers' SessionStart hook:** it injects instructions into every
  session.
- **superpowers `brainstorming`:** the obvious fit for `/planissues`, but its
  hard gate ends by writing a spec to `docs/superpowers/specs/` and moving on
  to implementation, and its description ("you MUST use this before any
  creative work") would make Claude reach for it inside `/designflow` and
  `/issuecoder` too. `/planissues` uses `grilling` for the discussion and
  keeps brainstorming's best ideas (decompose first, 2–3 approaches with a
  recommendation, say back what you understood) in its own steps.
- **Matt Pocock `to-spec`, `wayfinder` and `domain-modeling`:** they publish
  specs and decision maps to the issue tracker and write ADRs and a glossary.
  Plans and decisions are kept in the knowledge base, so these would
  create a second record.

---

## 3. Design skills

These were chosen on 2026-09-26 from the design skills developers credit with
polished, interactive UI. `README.md` records the
sources, licenses, local changes and safety notes.

| Skill | Author | What it's for |
|---|---|---|
| `impeccable` | Paul Bakaus | **The lead design skill**, with about 24 sub-commands: `shape`, `critique`, `audit`, `polish`, `typeset`, `colorize`, `animate`, `harden`, `adapt` and more. It keeps product context in `PRODUCT.md` / `DESIGN.md`. |
| `frontend-design` | Anthropic | A bold, deliberate aesthetic, and no generic "AI slop". Impeccable's baseline. |
| `ui-ux-pro-max` | NextLevelBuilder | An offline database of styles, palettes, fonts and UX rules that generates a design system. It runs **only when you type it**, or when `/designflow` needs a system for a brand-new product. |
| `baseline-ui`, `improve-ui`, `fixing-accessibility`, `fixing-motion-performance`, `fixing-metadata`, `create-design-md` | ibelick | Small, focused fix-up passes. `create-design-md` writes a `DESIGN.md` from an existing codebase. |
| `vercel-react-best-practices`, `vercel-composition-patterns`, `web-design-guidelines` | Vercel | React and Next.js performance and composition rules, plus a UI, UX and accessibility audit. The audit's rules are vendored locally, so they are never fetched live. |
| `emil-design-eng`, `animate`, `review-animations`, `pick-ui-library` | Emil Kowalski | Motion and feel: easing, springs and restraint. Also helps choose UI libraries. |
| `shadcn` | shadcn | Adding and composing shadcn/ui components correctly, with the CLI pinned to 4.21.0. |
| `expo-design-system`, `expo-native-ui`, `expo-ui`, `expo-animation` | Expo | Native-feeling React Native UI, for when a mobile app starts. |
| `webapp-testing` | Anthropic | Playwright screenshots and checks against localhost. |

### Design skills and Claude Design

**Claude Design** (claude.ai) is Anthropic's canvas for designs and
prototypes. It is generated as code, and it can build with a real design
system. Use the two together this way:

1. **Claude Design owns the look.** Run **`/design-sync`** from an app
   repository. That brings its real tokens and components into a Claude
   Design design-system project, so every design on the canvas uses them.
   Anthropic's own advice is to include real examples, not just specs.
2. **Explore on the canvas, build in code.** Try directions on the canvas.
   Hand a design to Claude Code with **`/design`** or the handoff bundle, or
   run `/designflow`, which shows its proposed directions as a Claude Design
   canvas.
3. **The skills make the code right and polished.** shadcn and Vercel for
   correctness, Impeccable and Emil's skills for finish, and the critics for
   accessibility and motion.
4. **Sync back.** After the PR merges, run `/design-sync` again, so the
   canvas matches what shipped.
5. **Keep one `DESIGN.md`** consistent with the Claude Design system. When
   three skills each invent a palette, the UI looks inconsistent and
   generic.

---

## 4. Built-in skills to use more often

These ship with Claude Code, so there is nothing to install.

| Command | Use it when |
|---|---|
| `/code-review [PR# \| branch] [low…max] [--comment \| --fix]` | Before pushing anything non-trivial. `--comment` posts the findings as inline PR comments; `--fix` applies them. It is the fastest second pair of eyes, and complements `/thermos`. |
| `/security-review` | Any change to auth, permissions, tenant isolation, payments, file uploads or anything else that parses user input. Anything handling user or business data should get this routinely. |
| `/simplify` | After a feature works and before the PR goes out. It removes duplication and needless complexity. It is quality only and does not look for bugs. |
| `/run` | To see a change working in the real app (start it, drive it, screenshot it) instead of trusting the tests alone. |
| `/loop [interval] <command>` | To repeat a skill, for example `/loop 2h /prreviewer` during a long session, without setting up a Routine. |
| `/init` | In a repository with no `CLAUDE.md`. Every skill above reads `CLAUDE.md` first, so a good one makes all of them better. |
| `session-start-hook` | Setting up a repository for Claude Code on the web, so cloud sessions can install dependencies and run tests and linters. `/bughunt` and `/issuecoder` depend on that. |
| `/fewer-permission-prompts` | When permission prompts keep interrupting. It proposes an allowlist of the read-only commands you actually use. |
| `skill-creator` | To build or improve a skill and measure whether it triggers. Use it next time one of these skills needs tuning. |

---

## Stacking skills

**Yes, skills stack.** A skill can tell Claude to invoke other skills at
specific points, and Claude calls each one through its Skill tool. Our skills each
have a "Subagents and stacked skills" section saying which skill to use when. For
example, `/prreviewer` runs `thermos` for the review and `fix-merge-conflicts`
for conflicts. The outer skill's rules always win: no stacked skill can
authorize a merge, a force-push or a rebase.

Two limits:

- **Stacked skills are optional.** If a stacked skill isn't installed, the
  outer skill falls back to its own inline instructions.
- **Only model-invocable skills can be stacked.** A skill with
  `disable-model-invocation: true` can only be started by a person typing it.
  That is why:
  - our own skills are never started by another skill;
  - we removed that flag from the vendored thermos skills, so `/prreviewer`
    and the thermos subagents can load them.

You can also stack by hand. Run `/issuecoder #42`, then `/prreviewer` on the
PR it opened, then approve the merge in chat.


### Stacked skills run inside subagents

All the Zan skills split their work between a **coordinator** (the main
chat) and **subagents**. Subagents can invoke skills themselves, and can
start their own subagents, up to 3 levels deep by default. Each skill's
"subagent plan" table says who does what:

| Skill | Coordinator keeps | Subagents |
|---|---|---|
| `/bughunt` | the baseline, de-duplication, the PR and the issues | one **hunter per lane**, in parallel (recent merges with `thermo-nuclear-review`, driving the app, open bugs, the static sweep); one **fixer per candidate** in its own worktree (`diagnosing-bugs`, `test-driven-development`, `verification-before-completion`), which must report `PROVEN` before anything counts; one **fresh reviewer per fix** |
| `/issuecoder` | picking, claiming, the PR | one **implementer per issue** in its own worktree (`writing-plans`, `test-driven-development`, `systematic-debugging`, `verification-before-completion`, and `subagent-driven-development` for large issues); then a **fresh reviewer** (`two-axis-review` against the issue, and `thermo-nuclear-review`) that can send it back for up to 2 rounds |
| `/prreviewer` | synthesizing findings (the thermos job), the verdict, the **merge gate** | **three parallel reviewers** (the two thermo-nuclear reviews and `two-axis-review`); one **fixer** in a worktree on the PR branch (`fix-merge-conflicts`, `systematic-debugging`, `receiving-code-review`, `verification-before-completion`) |
| `/prreviewall` | the inventory, the batch approval, the merge order | one **PR worker** per PR, at most 2 at a time. Each worker runs `/prreviewer`'s plan with its own reviewers and fixer. |
| `/designflow` | the target, your direction choice, the PR | a **direction** subagent (Impeccable `shape`, `frontend-design`, UI/UX Pro Max for new products); a **builder** in its own worktree (shadcn, Vercel, Supabase, Emil motion, Impeccable polish, webapp-testing screenshots); **three fresh critics** (design, accessibility, motion), with at most 2 fix rounds |
| `/planissues` | the whole conversation with you, the plan file, the split, both gates, publishing | up to three **researchers** in parallel (code scout, record scout, outside researcher with `research`); a **fresh skeptic** for the realism check; at the readiness gate a **verifier** and another skeptic per plan; one **issue drafter** per epic, then a **fresh issue reviewer** |

The ground rules are the same in all of them:
- **Code and its review are split.** Whoever writes the code applies the
  discipline skills. A subagent that didn't write it does the judging.
- **Each code-writing subagent gets its own worktree.** Two subagents never
  share a checkout.
- **Concurrency and depth are capped.** At most 3 subagents run at once per
  coordinator, nested no more than 2 levels deep.
- **Anything a human decides stays with the coordinator.** That covers
  questions to you, claims, PRs and every merge. A subagent's report can
  never approve a merge.
- **Nothing depends on subagents being available.** If they aren't, each
  skill runs the same stacked skills inline.

Subagents cost more tokens than inline work. In return, every task starts
with fresh context, independent PRs and issues run in parallel, and long runs
don't overflow.

---

## Running the skills with `/goal`

**`/goal <condition>`** is a Claude Code command that keeps a session working
until a condition is met ([docs](https://code.claude.com/docs/en/goal.md)).
After every turn, a small, fast evaluator model reads the conversation and
decides whether the condition is met. If it isn't, another turn starts
automatically. `/goal` on its own shows the status, and `/goal clear` stops
it. It works locally, in cloud sessions, headless, and in Routines. **Only
you can set a goal**; a skill can't.

Each of the six skills is a **bounded run**: a few issues, a few fixes, one
design target. A goal turns that into a series of runs aimed at an outcome:

```
/goal every open issue in milestone M2 has an open PR or a comment naming the decision it needs, or stop after 12 turns
/issuecoder milestone:M2
```

| Skill | Good goal | Turn cap |
|---|---|---|
| `/bughunt` | "main is green and every PR merged in the last 7 days has been swept" | 8 |
| `/issuecoder` | "every issue in M2 has an open PR or a comment naming the decision it needs" | about 1.5 per issue |
| `/prreviewer` | "every open PR is `Ready to merge: yes` or has a stated blocker" | about 1 per PR, plus 2 |
| `/prreviewall` | the same as `/prreviewer` | 6 |
| `/designflow` | "the settings page has no blocking critic findings, with mobile and desktop screenshots in the PR" | 6 per target |
| `/zanpass` | after the triage card: "the council released the target, both passes are clean, and it has landed as chosen". For a whole-plan build: "every issue in the plan's Issue map is merged, released and waiting for your merge answer, or blocked in writing, and integration has reported" | about 4 per council wave, plus 3; for a whole-plan build, about 3 per wave plus 1 per issue, plus 3 |
| `/planissues` | only the mechanical ends, after you approve the breakdown: "every item in the plan's Issue map has an issue number". Discussion and iteration are not goals. | about 1 per 15 issues, plus 2 |

**The boundaries** each skill enforces under a goal (the details are in each
SKILL.md, under "Using with /goal"):

- **A goal is an objective, never a permission.** No goal wording loosens the
  rules of engagement, the per-run budgets, or any approval step. In
  particular, **no goal can satisfy the merge gate**:
  - "merge all PRs" pauses at the approval question when you're in the chat;
  - unattended, it ends with `needs the human`.
- **Every run ends with a `GOAL STATUS` block:** progress as a count,
  what changed, what's left, what's blocked, and a verdict. The evaluator can
  only judge what's written in the conversation.
- **Loops end honestly.** A run reports `needs the human` or `cannot be met`,
  which ends the goal, in these cases:
  - the next step needs a person;
  - two runs in a row made no progress or hit the same failure;
  - meeting the goal would break a rule.
- **Skill-specific limits:**
  - `/bughunt` stops after two runs prove nothing new.
  - `/designflow` hands a target to you after 3 polish runs, because past
    that it's taste.
  - `/planissues` treats its readiness gate and breakdown approval like the
    merge gate: no goal passes them, so "plan and file the issues for X"
    pauses at the gate.
  - Blocked issues and PRs count as handled once the blocker is written down.
- **Goals that can't be measured are restated.** "Fix all bugs", "close M2"
  or "make it look amazing" becomes the closest measurable condition, which
  the skill states in its first status block. For example, "close M2"
  becomes "all of M2 has PRs ready to merge", because closing needs a merge.
- **Always add `or stop after N turns`.** A goal also clears itself if the
  context overflows. Each skill's per-run budget exists to prevent exactly
  that.

## Installing

Plugin skills only get namespaced names such as `/zans-skills:bughunt`.
**Cloud sessions (Claude Code on the web) don't load your local plugins or
your `~/.claude` folder.** Pick a route:

| Goal | How |
|---|---|
| Bare names (`/bughunt`) on your machine, in every repository | `./install.sh` copies every skill, flattened, to `~/.claude/skills`, and the thermos and Impeccable agents to `~/.claude/agents`. |
| Bare names in one repository, for everyone, **including cloud sessions** | `./install.sh /path/to/repo`, then commit that repository's `.claude/skills/` and `.claude/agents/`. |
| Only some of the six | `./install.sh --only designflow,issuecoder [/path/to/repo]` installs those skills, the skills they stack, and `shared/`. |
| As a plugin on your machine | In Claude Code, run `/plugin marketplace add ZanderOfficial/zans-skills`, then `/plugin install zans-skills@zan`. |

After you change a skill in this repository, re-run `install.sh` so the
installed copies pick up the change.

Skill names are lowercase kebab-case, like every other Claude Code
identifier, so the command is `/issuecoder`, not `/Issuecoder`.
