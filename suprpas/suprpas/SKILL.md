---
name: suprpas
description: Kept so the old command still works — the Super-Pass is now part of /zanpass, the council. /suprpas <braindump> runs /zanpass plan (Long) and then builds the plan in waves; /suprpas <plan> or milestone:<name> runs /zanpass build; /suprpas resume <plan> runs /zanpass resume.
argument-hint: "[braindump | <plan .md> | milestone:<name> | resume <plan .md>]"
disable-model-invocation: true
---

# /suprpas — now part of /zanpass

The Super-Pass (plan a large piece of work with the user, then build, review
and merge it in waves of worker subagents) moved into `/zanpass`, so that
every kind of work goes through one command, one triage and one council of
expert judges. This file stays so that `/suprpas` and links to it keep
working. It holds no procedure of its own, so the two can't drift apart.

Find `zanpass/SKILL.md`: `../../zanpass/zanpass/SKILL.md` from this file in
the zans-skills repository, or `../zanpass/SKILL.md` next to this file once
installed (also `<repo>/.claude/skills/zanpass/` or
`~/.claude/skills/zanpass/`). Read it and follow it as if the user had typed
the matching command, with `$ARGUMENTS` translated like this:

| `/suprpas …` | runs as |
|---|---|
| a braindump, or empty | `/zanpass plan <braindump>`, with intake's length answered **Long**, and at step 5 "Build it now" offered as the recommended choice |
| a path to a plan file | `/zanpass build <plan path>` if its Issue map is published; otherwise `/zanpass plan <plan path>` |
| `milestone:<name>` | `/zanpass build milestone:<name>` |
| `resume <plan path>` | `/zanpass resume <plan path>` (a plan with an old `## Super-Pass ledger` section is read as its Build ledger) |

Say in one line that `/suprpas` is now `/zanpass` and which command you are
running. If `zanpass/SKILL.md` can't be found, say so and stop.
