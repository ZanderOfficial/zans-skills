# The council: five expert judges, ten iterations a wave

`/zanpass` (SKILL.md, step 3) reads this file when it seats a council. A
council is five expert subagents who judge another subagent's work, each from
one angle, again and again, until the work has been through at least ten
rounds of criticism and revision. It exists because a single reviewer, run
once, catches what is obviously wrong and misses what is merely weak: the
naming that will confuse the next reader, the screen that works but feels
unfinished, the plan that is buildable but not the simplest one. Forcing ten
rounds turns "good enough to pass review" into "nothing material left to
improve", and putting five specialists on it means no angle depends on one
generalist remembering it.

The cost is real: one wave is about ten worker turns plus fifty judge turns,
all judges on opus. The triage card (SKILL.md, step 2) states it before the
user says go.

## Who sits

The **chair** is the coordinator: the main session in an interactive run, or
the level-1 worker in a Routine with `council: on` (routine.md, section 3a).
The chair never judges and never writes the work. It seats the judges,
consolidates their findings, settles disagreements between them, keeps the
council record, and decides when the council releases the work.

The **worker** is the subagent that does the work with the option's primary
skill (`/planissues`, `/issuecoder`, `/designflow`, `/bughunt` or
`/prreviewer`). It is the only one who writes.

The five **judges** are fresh subagents that did none of the work, all on
opus (the model ladder in SKILL.md: every reviewer is heavy). They are
read-only: they never commit, push, post on GitHub, or edit files. They read
the work without a checkout of their own, through
`git fetch origin <branch>`, `git diff origin/<base>...origin/<branch>` and
`git show origin/<branch>:<path>`, plus the screenshots and plan files the
worker names. Each judge loads its seat's stacked skills through the Skill
tool, or reads `~/.claude/skills/<name>/SKILL.md` if the tool doesn't list
one. Use the `council-judge` agent type if it is installed; otherwise
`general-purpose` with the judge brief below.

## The rosters

Every option seats five judges. The **House rules** seat is the same in every
roster: it enforces the readable-code and writing rules from SKILL.md, which
are the user's own AGENTS.md rules, and it is the seat that stops ten rounds
of revision from turning into churn.

### Plan

| Seat | Judges | Loads | Blocks when |
|---|---|---|---|
| Product strategist | whether the plan solves the problem the braindump described, for the people it names, at a size that ships | `grilling` | the plan builds something the user did not ask for, or skips what they did |
| Systems architect | the shape of the system: boundaries, data flow, what is built once and reused, what is hard to change later | `two-axis-review` | a decision is hard to reverse and the plan does not say why it is right |
| Data and security | schema, ownership and tenancy, auth and permissions, RLS, migrations, secrets | `supabase-postgres-best-practices` when the repo uses Supabase | any data path has no stated owner or access rule |
| Delivery planner | the breakdown: vertical slices, blocking edges, foundations first, each issue sized for one worker | `to-tickets` | an issue cannot be built and reviewed in one sitting, or its blockers are wrong |
| House rules | readability of the plan for a reader with no context; every claim sourced; rejected options recorded | — | a section cannot be understood without the conversation |

### Code (an issue)

| Seat | Judges | Loads | Blocks when |
|---|---|---|---|
| Correctness and security | bugs, breaking changes, auth and tenant checks, ignored errors, races | `thermo-nuclear-review` | any finding the skill rates high or critical |
| Code quality | duplication, wrong abstraction, dead code, needless complexity | `thermo-nuclear-code-quality-review` | the change makes the code harder to change next time |
| Spec fidelity | does the diff do what the issue and its plan section say, all of it and only it | `two-axis-review` | an acceptance criterion is unmet, or the diff widens the issue |
| Test engineer | tests prove the behaviour, fail without the change, and cover the edge cases the issue names | `test-driven-development`, `verification-before-completion` | a behaviour has no test, or a test passes without the change |
| House rules | the readable-code rules; commit and PR text in the house voice | — | a name, comment or commit message would mislead the next reader |

### Design

| Seat | Judges | Loads | Blocks when |
|---|---|---|---|
| Design director | fidelity to the approved direction, hierarchy, type, spacing, colour, the "made with care" bar | `impeccable` (critique), `frontend-design` | the screen drifts from the approved direction |
| Interaction and copy | flows, states (empty, loading, error), affordances, microcopy | `web-design-guidelines`, `baseline-ui` | a state is missing or a control does not say what it does |
| Accessibility | contrast, focus, keyboard, labels, reduced motion | `fixing-accessibility` | any WCAG AA failure |
| Motion and performance | animation purpose and timing, layout shift, frame budget | `emil-design-eng`, `review-animations`, `fixing-motion-performance` | motion blocks input or drops frames |
| House rules | component structure and readability, matching the repo's UI conventions | `vercel-react-best-practices`, `vercel-composition-patterns` (web) or `expo-design-system` (native) | the component is hard to reuse or reads unlike its neighbours |

Design judges look at the worker's mobile and desktop screenshots for the
current iteration, not just the diff.

### Bughunt

| Seat | Judges | Loads | Blocks when |
|---|---|---|---|
| Reproduction skeptic | is each bug real: the failing test fails for the stated reason, on the default branch | `diagnosing-bugs` | a "bug" is not proven |
| Root-cause analyst | the fix addresses the cause, not the symptom | `systematic-debugging` | the fix would let the same bug recur elsewhere |
| Fix minimalism | each fix is the smallest one that works, under the skill's size limit | `thermo-nuclear-code-quality-review` | a fix refactors beyond the bug |
| Security | whether any bug or fix touches auth, tenancy, payments or data loss, and is rated accordingly | `thermo-nuclear-review` | a security bug is filed as minor, or a fix opens a new hole |
| House rules | the Bug / Root cause / Fix / Test table and filed issues read clearly to someone new | — | an issue cannot be acted on without the session |

### Review (a PR)

| Seat | Judges | Loads | Blocks when |
|---|---|---|---|
| Correctness and security | as in Code | `thermo-nuclear-review` | as in Code |
| Code quality | as in Code | `thermo-nuclear-code-quality-review` | as in Code |
| Spec fidelity | the PR against its linked issue, or its own description when there is none | `two-axis-review` | the PR does not do what it says |
| Merge readiness | CI on the head, conflicts, every review thread answered, the base merged in rather than rebased | `receiving-code-review`, `fix-merge-conflicts` | anything that would fail the prreviewer merge gate |
| House rules | as in Code | — | as in Code |

### Swapping a seat

When triage finds the work touches a specialism no seat covers, the chair
swaps **one** seat (never House rules) for a specialist, and the triage card
says which:

- Supabase, RLS or migrations → *Data and security*, loading `supabase` and
  `supabase-postgres-best-practices`;
- an Expo or native app → *Native platform*, loading `expo-native-ui` and
  `expo-ui`;
- a game → *Game loop*: fixed timestep, input, state and save systems, and a
  headless test of game state;
- payments or billing → *Payments*: idempotency, webhooks, amounts in minor
  units, refunds.

## One iteration

Iterations are numbered `<wave>.<k>`, so `2.7` is the seventh iteration of
the second wave.

1. **The worker works.** In iteration `w.1` of the first wave it produces the
   first version through its primary skill. In every later iteration it gets
   the chair's consolidated list from the previous iteration and answers
   every item: `done` (with the commit), or `declined: <reason>`. It pushes,
   runs `verify`, takes new screenshots for design work, and returns its
   report (SKILL.md, "Reports").
2. **The council sits.** All five judges judge the same commit at the same
   time. Judges are read-only, so the five may run together; this is the one
   exception to the "3 subagents at once" rule, and no code-writing subagent
   runs while the council sits. Each judge returns the judge report below and
   nothing else.
3. **The chair consolidates.** It merges the five reports into one numbered
   list, most severe first; removes duplicates; marks which seat raised what;
   and settles any two seats that contradict each other, writing one line on
   why. A finding the chair overrules stays in the record with the reason.
   A declined item goes back to the seat that raised it, which rules on the
   reason in the next iteration.
4. **The chair records.** It updates the council record (below) and sends
   the list to the worker as the next iteration's brief.

Judges stay seated for the whole wave, continued with SendMessage, so each
can check that what it asked for was done. They are re-seated fresh at the
start of every later wave, with the council record as their only history, so
that no wave is judged only by eyes that have grown used to the work.

The worker is continued with SendMessage within a wave and restarted fresh
at each new wave, from the branch and the council record, so its context
doesn't fill.

## Ten iterations, and what the council may not do before them

**The council cannot release the work before the last iteration of a wave**
(10 by default; the user can change it at the triage card). When every seat
passes early, the rest of the wave is **refinement**: each judge names the
single most valuable improvement it still sees, or says
`nothing material: <why>`. The chair accepts a refinement only when it makes
the work clearer, safer or simpler. A refinement that only adds code, adds
options nobody asked for, or rewrites working code to the judge's taste is
rejected, and the House rules seat says so. "Leave it as it is" is a valid
outcome of an iteration, and the iteration still counts.

After the last iteration of a wave, the council **releases** the work when:

- no seat's verdict is `block`;
- at least four of the five seats vote `pass`;
- `verify` is green on the head commit, and for design work the screenshots
  are from that commit.

What happens next depends on the length the user chose at intake:

- **Short:** released → go straight to the final passes (SKILL.md, step 4).
  Not released → start another wave on its own. After the third wave without
  release, stop and ask the user, showing the open blocks.
- **Long:** at the end of **every** wave, released or not, show the user the
  wave summary and ask (SKILL.md, step 3). They approve the work, send it
  back for another wave with notes (which become iteration 1 of the next
  wave's brief), change direction, or stop.

## The judge brief

Every judge brief stands alone and contains:

- the seat's name, what it judges, what it loads and when it blocks, copied
  from the roster;
- the work: repository, base and branch, head commit, the issue or plan
  section that is the spec, screenshot paths for design work;
- the council record so far (for a re-seated judge) or its own earlier
  findings (when continued within a wave);
- the House rules from SKILL.md, verbatim;
- "You are read-only: never commit, push, edit files, or post on GitHub.
  Judge only what this work changed; do not report problems in code it did
  not touch, except where the change makes them worse.";
- "Do not soften a finding because this is a late iteration, and do not
  invent one because the council requires ten. If nothing material is left,
  say so.";
- the judge report format.

## The judge report

```
SEAT: <seat>   ITERATION: <wave>.<k>   COMMIT: <sha>
VERDICT: pass | revise | block
SCORE: <1–10, how close this is to work you would sign your name to>
CARRIED: <your earlier findings: fixed <n>; still open: <ids>; declined and you accept: <ids>; declined and you don't: <ids, one line why>>
FINDINGS: (at most 6, most severe first)
 - [block|major|minor|nit] <file:line, or plan section, or screen> — <what is wrong> → <what to change>
BEST NEXT IMPROVEMENT: <one line, or "nothing material: <why>">
```

## The council record

The record is the council's memory. Chat is not, because the chair's thread
may be compacted and a resumed session sees none of it. Keep it short:

- **Code, Design, Bughunt, Review:** one comment on the PR titled
  `Council record`, edited in place each iteration rather than posted anew,
  so the PR's thread stays readable.
- **Plan:** a `## Council record` section in the plan file, committed to the
  plan branch at the end of each iteration.

```
## Council record
option: <plan | code | design | bughunt | review>   length: short | long   iterations per wave: 10
seats: <five seat names; any swap and why>
| iter | commit | votes (pass/revise/block) | scores | items raised / done / declined | chair's notes |
waves: <w1: released | not released (open blocks) | sent back by the user: "<their note>">
current: <iteration>   next: <exactly what happens next>
```

Every entry is written for a reader who saw none of the session, as the
House rules require: say what changed and why, not just that it did.
