# zans-skills

Everything for Zan's skills is in this one repository. The folder
is organised by skill: each top-level group holds one of the six skills,
plus the vetted community and design skills that **only it** stacks. Skills
that several of the six stack live once, in `shared/`, so there is never a
second copy to drift out of date.

The full guide (what each skill does, how stacking and subagents work, and
Claude Design) is [`CODINGSKILLS.md`](CODINGSKILLS.md) at the repository
root.

## Layout

```
./
├── .claude-plugin/plugin.json   plugin manifest; lists each group below as a skills directory
├── install.sh                   copies the skills to ~/.claude/skills or a repo's .claude/skills (--qwen: .qwen/)
├── bughunt/
│   ├── bughunt/                 /bughunt: prove bugs with failing tests, fix small ones, file the rest
│   └── diagnosing-bugs/         (Matt Pocock) build a reproduction loop before fixing
├── issuecoder/
│   ├── issuecoder/              /issuecoder: ship open issues as small, verified PRs
│   ├── writing-plans/           (superpowers) spec -> bite-sized plan
│   ├── executing-plans/         (superpowers) run a plan task by task, with a ledger
│   ├── subagent-driven-development/   (superpowers) a subagent + reviewer per plan task
│   ├── requesting-code-review/  (superpowers) self-review before the PR
│   ├── using-git-worktrees/     (superpowers) isolated workspace per task
│   └── finishing-a-development-branch/  (superpowers) merge / PR / discard at the end
├── prreviewer/
│   ├── prreviewer/              /prreviewer: review PRs to mergeable, merge on human approval
│   ├── thermos/                 (Cursor) runs both thermo-nuclear reviews in parallel
│   ├── thermo-nuclear-code-quality-review/  (Cursor) harsh maintainability review
│   ├── fix-merge-conflicts/     (Cursor) conflict resolution, then build and test
│   └── receiving-code-review/   (superpowers) weigh review feedback on its merits
├── prreviewall/
│   └── prreviewall/             /prreviewall: the /prreviewer process on every open PR
│                                (reads prreviewer/prreviewer/SKILL.md at run time)
├── designflow/
│   ├── designflow/              /designflow: design, build, polish and screenshot UI
│   ├── impeccable/              (Paul Bakaus) the lead design skill: shape, critique, audit, polish ...
│   ├── frontend-design/         (Anthropic) a bold, deliberate aesthetic
│   ├── ui-ux-pro-max/           (NextLevelBuilder) design-system generator; typed only
│   ├── baseline-ui/ improve-ui/ create-design-md/
│   ├── fixing-accessibility/ fixing-metadata/ fixing-motion-performance/   (ibelick)
│   ├── vercel-react-best-practices/ vercel-composition-patterns/ web-design-guidelines/  (Vercel)
│   ├── emil-design-eng/ animate/ review-animations/ pick-ui-library/       (Emil Kowalski)
│   ├── shadcn/                  (shadcn) components, CLI pinned to 4.21.0
│   ├── expo-design-system/ expo-native-ui/ expo-ui/ expo-animation/        (Expo)
│   └── webapp-testing/          (Anthropic) Playwright screenshots on localhost
├── planissues/
│   ├── planissues/              /planissues: braindump -> research -> plan -> iterate -> issues
│   │                            (plan-template.md and issue-format.md sit beside its SKILL.md)
│   ├── grilling/                (Matt Pocock) question rounds over a design tree
│   ├── research/                (Matt Pocock) primary-source research in a background agent
│   └── to-tickets/              (Matt Pocock) vertical slices with blocking edges
├── zanpass/
│   └── zanpass/              /zanpass: one scheduled Routine pass; routes work to the
│                                skills above through subagents (see ROUTINES.md)
├── suprpas/
│   └── suprpas/                 /suprpas: a supervised Super-Pass; plans a large piece of work
│                                with you, then builds, reviews and merges it in waves of subagents
├── shared/                      stacked by more than one of the six
│   ├── thermo-nuclear-review/   (Cursor) bughunt, issuecoder, prreviewer
│   ├── systematic-debugging/    (superpowers) bughunt, issuecoder, prreviewer
│   ├── test-driven-development/ (superpowers) bughunt, issuecoder, designflow
│   ├── verification-before-completion/  (superpowers) all but planissues
│   ├── two-axis-review/         (Matt Pocock) issuecoder, prreviewer, designflow
│   └── supabase/ supabase-postgres-best-practices/   (Supabase) issuecoder, designflow
├── agents/                      named subagents: thermo-nuclear-* (prreviewer), impeccable-* (designflow)
└── licenses/                    every upstream LICENSE / NOTICE, collected in one place
```

### Why each skill sits in a folder named after itself

For example, the `/bughunt` skill lives at `bughunt/bughunt/`. Claude Code
discovers skills exactly one level down: a skills directory contains
`<name>/SKILL.md` folders. Each group folder is registered as its own skills
directory in `plugin.json`, so the skill itself has to be one level inside
it, next to the skills it stacks. The installer flattens all of this into
`<dir>/.claude/skills/<name>/`.

## Installing

Claude Code only gives plugin skills namespaced names, like
`/zans-skills:bughunt`. `install.sh` gives them bare names (`/bughunt`).
Cloud sessions load neither your machine's `~/.claude` nor locally installed
plugins, so for cloud use, install into the repository and commit the result.

| Goal | Command |
|---|---|
| Everything, on your machine, in every repo | `./install.sh` |
| Everything, in one repo, for everyone including cloud sessions | `./install.sh /path/to/repo`, then commit `.claude/skills/` and `.claude/agents/` |
| Only some of the six, with what they stack | `./install.sh --only designflow,issuecoder [/path/to/repo]`. `shared/` always comes along, and `prreviewall` pulls in `prreviewer`. |
| As a plugin, on your machine | `/plugin marketplace add ZanderOfficial/zans-skills`, then `/plugin install zans-skills@zan` |
| Qwen Code, on your machine or in one repo | `./install.sh --qwen [--only a,b] [/path/to/repo]`. Same skills, installed to `~/.qwen/` or the repo's `.qwen/` (commit `.qwen/skills/` and `.qwen/agents/` to share it). |

### Qwen Code

Qwen Code reads the same `SKILL.md` format as Claude Code, but only from
`.qwen/skills/` and `~/.qwen/skills/`; it does not look in `.claude/`, and the
plugin route above is Claude Code only. `install.sh --qwen` installs into the
`.qwen` folder instead. The skill files are copied unchanged. The agents lose
their `tools:` line, because it names Claude Code's tools (`Read`, `Bash`, …)
rather than Qwen's (`read_file`, `run_shell_command`, …), so each agent
inherits the session's tools instead.

The skills were written for Claude Code. Under Qwen, the parts that lean on
Claude-only features, such as `/goal`, Claude Design canvases and named
subagent types, work only as far as Qwen has an equivalent. Treat Qwen runs
of `/suprpas`, `/zanpass` and `/designflow` in particular as best-effort.

Re-run the installer after changing anything here.

## The six skills

| Skill | Built from | What it does |
|---|---|---|
| `/bughunt [scope]` | Bug Hunter routines | It hunts regressions in recent merges, the running app, open `bug` issues and high-risk code. Every bug has to be proven with a failing test. It fixes the small ones (up to 3) in one PR and files the rest as issues (up to 5), after checking for duplicates. |
| `/issuecoder [#n… \| label:x \| milestone:y]` | Issue Coder routines | It fixes a red default branch first. Then it picks untaken issues (`ready` label first, then the lowest milestone, then the smallest), claims each one, builds it with tests on its own branch, verifies it, and opens one PR per issue (up to 2 per run). |
| `/prreviewer [#n… \| all]` | PR Fixer routine | It reviews each PR for correctness, security, data and test gaps. It merges the base branch in (never rebasing), resolves conflicts, fixes red CI, and handles review threads. It then posts a `Ready to merge: yes/no` verdict. It **merges into the default branch only after a human approves** that exact head commit, as described below. |
| `/prreviewall [--include-drafts] [--skip #n…]` | PR Fixer routine | The `/prreviewer` process for **every** open PR, with no per-run cap. It inventories all open PRs, then gives each one its own worker subagent, up to 2 at a time. Each subagent runs prreviewer's review-and-fix-up steps for its PR. The coordinator then asks once, as a checklist, which ready PRs to merge. It merges them one at a time, re-checking the gate before each, because every merge moves the default branch. It reads `prreviewer/prreviewer/SKILL.md` at run time, so the two skills can't drift apart; `install.sh --only prreviewall` installs both. |
| `/designflow [brief \| #n… \| label:x]` | (new; the design counterpart to `/issuecoder`) | Designs and builds one piece of UI: what you describe, or else the top open `design`-labelled issue. A direction subagent proposes 2–3 directions using Impeccable, frontend-design and UI/UX Pro Max. You approve one, shown on a Claude Design canvas where available. A builder in its own worktree then builds it with shadcn, the Vercel React rules, the Supabase skills and Emil Kowalski's motion skills (or the Expo skills for native), and polishes it with Impeccable. It captures mobile and desktop screenshots with webapp-testing. Three fresh critics (design, accessibility, motion) review it, with at most 2 fix rounds, then it opens a PR with before/after screenshots. |
| `/planissues [braindump \| plan.md \| issues plan.md]` | (new; the planning step before `/issuecoder`) | Takes a braindump through discussion (with a realism check first), research, organisation and a written plan in the knowledge base, then as many iteration rounds as you want, then issues. It uses `grilling` for question rounds, up to three parallel researchers (code, record, outside world, the last using `research`), and a fresh skeptic that saw none of the discussion. It proposes splitting an idea into several plans when it holds several. Nothing reaches GitHub until you pass a readiness gate (a verifier re-checks every claim in the plan) **and** approve the issue breakdown. It then publishes a milestone, an epic and issues in the house format, writing each issue number back into the plan as it goes. |

**`/zanpass`** is the seventh skill, and is not meant to be typed. It is
what the scheduled Routines run (under `/goal`): one pass that triages a
repository and routes work to the six skills above through worker subagents,
choosing a model per job and keeping its own thread under 50% of its context.
[`ROUTINES.md`](ROUTINES.md) explains it and holds each repository's
Routine prompt. `install.sh --only zanpass` also installs the five skills
it routes to.

**`/suprpas`** is the eighth skill: a **Super-Pass**, the supervised, large
counterpart of `/zanpass`. It is for work too big for one run of any single
skill, such as a whole feature, a large section of a product, or the
foundations of a new app or game. The main session plans the work with you
from a braindump by running `/planissues` in its interactive mode. Once you
have approved the plan and its breakdown, it hands you a `/goal` line and then
coordinates worker subagents in dependency-ordered **waves**: foundations
first, one at a time on the heaviest model, then up to three issues at once.
Each issue is built by an `/issuecoder` or `/designflow` worker, reviewed by
a fresh opus reviewer (both thermo-nuclear reviews and `two-axis-review`), and
brought to mergeable by a `/prreviewer` worker. It merges a wave only after
you answer the merge question for it in the chat, and it ends with a bug sweep
and a whole-feature review of the merged result. It uses the same model ladder
as `/zanpass`, keeps its state in a ledger inside the plan so it can resume
after a context checkpoint (`/suprpas resume <plan>`), and never runs
unattended. `install.sh --only suprpas` also installs the five skills it
routes to.

All six have `disable-model-invocation: true`, so they run only when you type
the command. Claude never starts one on its own.

Each skill also has a **"Using with /goal"** section. It explains how to
chain runs toward an outcome with Claude Code's `/goal`: the `GOAL STATUS`
block each run ends with, when a run stops a goal, good conditions, and turn
caps. It also says that no goal can satisfy the merge gate. See
`CODINGSKILLS.md`.

### The /prreviewer merge gate

The Routine it replaces was never allowed to merge. This skill can merge, but
only when all of these are true, checked with a fresh fetch just before the
merge:

1. **A human approved the current head commit.** That approval can come from
   either of two places:
   - you answered "Merge" for that PR in the chat, after seeing the verdict;
   - there is a GitHub `APPROVED` review on that commit from someone with
     write access who is not a bot and not the PR's author.

   A comment that merely *says* "approved" or "merge this" does not count.
2. CI is green on that commit.
3. There are no conflicts and no outstanding changes-requested review.
4. The PR is not a draft.

The merge passes the head SHA, so it fails if anyone pushed after the approval.
The skill never uses an admin merge or bypasses branch protection. When it runs
unattended from a Routine, only GitHub approvals count, because nobody is there
to answer in the chat.

## Vendored coding skills

These sit in `bughunt/`, `issuecoder/`, `prreviewer/`, `planissues/` and `shared/`.

### What's here and where it came from

| Skill | Source (repository @ commit) | License |
|---|---|---|
| `thermos`, `thermo-nuclear-review`, `thermo-nuclear-code-quality-review` + `agents/thermo-nuclear-*-subagent.md` | [cursor/plugins](https://github.com/cursor/plugins) `thermos/` @ `ecc249f` | MIT © 2026 Cursor |
| `fix-merge-conflicts` | [cursor/plugins](https://github.com/cursor/plugins) `cursor-team-kit/skills/` @ `ecc249f` | MIT © Cursor |
| `systematic-debugging`, `test-driven-development`, `verification-before-completion`, `receiving-code-review`, `writing-plans`, `executing-plans` | [obra/superpowers](https://github.com/obra/superpowers) `skills/` @ `8ca22db` | MIT © Jesse Vincent |
| `subagent-driven-development`, `requesting-code-review`, `using-git-worktrees`, `finishing-a-development-branch` | same as above | MIT © Jesse Vincent |
| `diagnosing-bugs`, `two-axis-review` (upstream name `code-review`) | [mattpocock/skills](https://github.com/mattpocock/skills) `skills/engineering/` @ `c55ee46` | MIT © Matt Pocock |
| `grilling` (`skills/productivity/`), `research`, `to-tickets` (`skills/engineering/`), in `planissues/` | [mattpocock/skills](https://github.com/mattpocock/skills) @ `c55ee46` | MIT © Matt Pocock |

The second superpowers row was not picked on its own merits. Those four skills
are **dependencies** that `executing-plans` cannot run without:

- its `scripts/task-start` and `scripts/task-done` call
  `../../subagent-driven-development/scripts/*`;
- its final review uses `../requesting-code-review/code-reviewer.md`;
- it hands off to `using-git-worktrees` at the start and
  `finishing-a-development-branch` at the end.

Every vendored skill directory carries its own `LICENSE`. The same files are
also gathered in `licenses/`.

### Changes made to the upstream text

MIT allows modification. We made these changes, and nothing else:

1. **thermos (all three skills):** removed `disable-model-invocation: true`.
   Upstream, the thermos subagents are told to "load the thermo-nuclear-review
   skill". A skill with that flag can only be started by a person typing it,
   so the subagents could never load it, and `/prreviewer` could never stack
   it. With the flag removed, Claude may also pick thermos up by itself when
   you ask for a "thermo" review.
2. **superpowers:** replaced `superpowers:<skill>` references with the bare
   `<skill>` name. Upstream they are namespaced to the superpowers plugin. Here
   they are installed either under bare names or under
   `zans-skills:`.
3. **two-axis-review:** renamed from `code-review`, which would collide with
   Claude Code's built-in `/code-review`. Also replaced its dependency on
   `/setup-matt-pocock-skills` and `docs/agents/issue-tracker.md` with "use
   `gh` or the GitHub MCP tools, or that file if the repository has one".
4. **mattpocock skills:** dropped the `agents/openai.yaml` display metadata,
   which only OpenAI's tooling uses.
5. **to-tickets:** removed `disable-model-invocation: true`, for the same
   reason as thermos: with it, `/planissues` could never stack it. Also
   replaced its two references to `/setup-matt-pocock-skills` with "use `gh`
   or the GitHub MCP tools, and the labels the repository already has".
   `/planissues` uses it for slicing and blocking edges only; its "no file
   paths in tickets" rule and its `ready-for-agent` label are overridden by
   `/planissues`' own issue format. `grilling` and `research` are unchanged.

### Things to know before using them

- **The superpowers skills are model-invocable and assertive.** Their
  descriptions say things like "use when encountering any bug". Claude will
  reach for them on its own, which is the point, but it adds process to small
  tasks.
- **We did not vendor superpowers' SessionStart hook.** It injects the whole
  `using-superpowers` skill into every session and changes behaviour
  everywhere.
- **`subagent-driven-development` uses a git-ignored workspace.** It keeps its
  files in `<repo>/.superpowers/sdd/`. At the end it deletes that folder, not
  your code.
- **`finishing-a-development-branch` can delete a branch.** It runs
  `git branch -D` only when you explicitly pick "discard". It refuses
  `--force` unless you ask.
- **No skill here pipes a network download into a shell.** None of them uses
  `curl | bash`.

### Updating

To pick up a newer upstream version, re-clone the source repository and copy
the skill directory over the one here. Re-apply the changes listed above, then
update the commit in the table.

## Vendored design skills

These sit in `designflow/` and `shared/`.

### What's here and where it came from

| Skill | What it's for | Source (repo @ commit) | License |
|---|---|---|---|
| `frontend-design` | Choosing a bold, deliberate aesthetic direction and avoiding generic "AI slop" UI. Prompt only. | [anthropics/skills](https://github.com/anthropics/skills) @ `3337550` | Apache-2.0 (Anthropic) |
| `webapp-testing` | Playwright scripts that drive a local app: screenshots, console logs, and a helper that starts the server. | same | Apache-2.0 (Anthropic) |
| `impeccable` + `agents/impeccable-*.md` | The main design workflow: `shape`, `critique`, `audit`, `polish`, `typeset`, `colorize`, `animate`, `harden`, `adapt` and more, reading project context from `PRODUCT.md` / `DESIGN.md`. | [pbakaus/impeccable](https://github.com/pbakaus/impeccable) `plugin/` @ `9d715cc` | Apache-2.0 (Paul Bakaus); see `NOTICE.md` |
| `ui-ux-pro-max` | An offline database of 79 styles, 192 palettes, 74 font pairings and 119 UX rules that generates a design system for a product type. | [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) @ `823b0a1` | MIT © 2024 Next Level Builder |
| `baseline-ui`, `improve-ui`, `fixing-accessibility`, `fixing-motion-performance`, `fixing-metadata`, `create-design-md` | Small, focused passes: remove "slop", fix accessibility, fix motion performance, fix metadata, and write a `DESIGN.md` from an existing codebase. | [ibelick/ui-skills](https://github.com/ibelick/ui-skills) @ `f9515cb` | MIT © 2026 Julien Thibeaut |
| `vercel-react-best-practices`, `vercel-composition-patterns` | React and Next.js performance rules (72 of them) and component composition patterns. | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) @ `063bee9` | MIT, declared in each SKILL.md's `license:` field. **The upstream repository has no LICENSE file.** |
| `web-design-guidelines` + `command.md` | A UI, UX and accessibility audit against Vercel's Web Interface Guidelines, reporting `file:line` findings. | the skill from agent-skills @ `063bee9`; the rules from [vercel-labs/web-interface-guidelines](https://github.com/vercel-labs/web-interface-guidelines) @ `e3d624b` | MIT © 2025 Vercel Labs |
| `emil-design-eng`, `animate`, `review-animations`, `pick-ui-library` | Motion and feel (easing, springs, restraint, press and drag), plus choosing UI libraries. By the author of Sonner. | [emilkowalski/skill](https://github.com/emilkowalski/skill) @ `d16ebe6` | MIT © 2026 Emil Kowalski |
| `shadcn` | Adding, composing, fixing and styling shadcn/ui components, registries and presets. | [shadcn-ui/ui](https://github.com/shadcn-ui/ui) `skills/shadcn` @ `98a1fe6` | MIT (shadcn) |
| `expo-design-system`, `expo-native-ui`, `expo-ui`, `expo-animation` | Native-feeling React Native / Expo UI: design tokens, "native-slop tells", Apple HIG, `@expo/ui`, and Reanimated. | [expo/skills](https://github.com/expo/skills) @ `efa52f0` | MIT © 650 Industries (Expo) |

The Supabase skills (`supabase`, `supabase-postgres-best-practices`, MIT ©
2026 Supabase, [supabase/agent-skills](https://github.com/supabase/agent-skills)
@ `551274e`) are backend skills, not design skills. They live in `shared/`,
because both `/issuecoder` and `/designflow` stack them.

### Changes made to the upstream text

1. **`web-design-guidelines`: no remote rules.** Upstream, the skill WebFetches
   `command.md` from GitHub's `main` branch on every run. That means anyone who
   can push to that branch can change what the skill tells Claude to do. The
   rules are now vendored as `command.md` next to the skill, and the skill reads
   that local file instead.
2. **`shadcn`: CLI pinned.** Every `shadcn@latest` (in `allowed-tools` and in
   the docs) is replaced with `shadcn@4.21.0`, the version at the pinned commit.
   This stops the skill running whatever npm publishes next. Upstream's `evals/`
   folder was dropped.
3. **`ui-ux-pro-max`: user-invoked only.** Added
   `disable-model-invocation: true`. It generates a whole design direction of
   its own, which fights Impeccable and `frontend-design`, so it runs only when
   you type `/ui-ux-pro-max` or `/designflow` asks for it.
4. **Removed `agents/openai.yml` display metadata,** which only OpenAI's
   tooling uses.

### Things to know before using them

- **Impeccable's hooks were not vendored.** Upstream's plugin installs
  SessionStart, PostToolUse and Stop hooks. On every session and every file
  edit they run its `scripts/impeccable` launcher, which downloads a binary
  "engine" from GitHub releases on first use.
- **The skill itself still runs the launcher.** It runs
  `scripts/impeccable context` once per session to load project context, so
  **the first `/impeccable` run in a session downloads the engine binary**
  (about the same as `npx`-ing a tool). The launcher checks a sha256 file
  downloaded from the same release, and refuses to run if the check fails.
- **It works without the download.** If you deny the command, or the
  network blocks it, the skill falls back to reading `PRODUCT.md` and
  `DESIGN.md` directly. You lose the engine features (live in-browser
  iteration and the design detector), but the rest of the workflow works.
- **If you want the hooks,** `/impeccable hooks on` explains how to set them
  up.
- **Three skills compete for "make it look designed".** Those are
  `frontend-design`, Impeccable and `ui-ux-pro-max`. `/designflow` uses
  Impeccable as the lead, `frontend-design` as its baseline, and
  `ui-ux-pro-max` only when a product has no design system yet.
- **`webapp-testing` needs Python and Playwright.** In Claude Code cloud
  containers, Chromium is preinstalled; don't run `playwright install`.
- **Size.** The `designflow/` group is about 7 MB. Most of that is Impeccable's
  font index and live-browser scripts, and UI/UX Pro Max's font and icon
  data.

### Considered and not vendored

- **Figma `mcp-server-guide` skills:** no LICENSE file, and they need the
  Figma MCP server.
- **Anthropic `web-artifacts-builder`:** it builds claude.ai artifacts, not
  Next.js apps.
- **Anthropic `canvas-design`, `algorithmic-art` and `theme-factory`:** made
  for static art and themed documents, not product UI.
- **ibelick `ui-skills-root`:** it depends on the `ui-skills` CLI.
- **`userinterface-wiki`:** overlaps with `web-design-guidelines`.

## License

Zan's own work in this repository (the workflow skills, the named subagents,
`install.sh`, and the documentation) is licensed under the
[Mozilla Public License 2.0](LICENSE). MPL-2.0 is a file-level copyleft
license: you may use these skills in any project, open or closed, but if you
distribute a modified version of one of these files, that file must stay
under MPL-2.0.

The vendored skills are **not** covered by that license. Each keeps its
upstream license, which sits in its own folder and is also collected in
`licenses/` (see the tables above).
