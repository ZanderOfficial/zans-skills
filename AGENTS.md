# zans-skills — agent instructions

This repository is a **library of Claude Code skills and agents**: the
workflow skills (`/bughunt`, `/issuecoder`, `/prreviewer`, `/prreviewall`,
`/designflow`, `/planissues`, `/zanpass`, `/suprpas`), the vetted community and
design skills they stack, and the named subagents. See `README.md` for the
layout and `CODINGSKILLS.md` for how the skills work together.

## Conventions for working in this repository

- Skills sit one level inside a group folder (`bughunt/bughunt/SKILL.md`);
  group folders are registered in `.claude-plugin/plugin.json`. Shared skills
  live once in `shared/`; never copy one into a second group.
- Vendored skills keep their upstream license (`LICENSE` in the skill folder,
  collected in `licenses/`). Record any change made to upstream text in
  `README.md` under "Changes made to the upstream text".
- After changing anything, re-run `install.sh` for the installed copies to
  update.

## Source of truth for projects that use these skills

**A document marked `status: active` in its frontmatter is the source of truth
for its subject.** Where an archived or superseded document disagrees, the
active document wins; do not "fix" an active plan with a claim from an archived
one. Superseded documents (prefixed `[SUPERSEDED]` or under `archive/`) are
history: read them for reasoning, never for current fact. Check an active
document's own reconciliation section before changing it.

## Developing products: locally, not on metered CI

If a platform meters build minutes (Vercel, for example), develop and test on
`localhost` or a Claude Code cloud container, never by deploying to test. Keep
env vars and steps in each code repository's `DOCS/LOCAL-DEV.md`.

## Writing voice for anything published to GitHub

**Milestones, issues, commits, PRs and comments are written to educate.**
Assume the reader lacks the full context: a new contributor, a future
maintainer, or you in six months.

- **Say why before what.** The reason for the work goes stale slowest.
- **Define the terms and name the files.** Spell out jargon on first use and
  point at real paths and documents.
- **State what breaks if it is skipped**, and what "done" looks like.
- **Show the reasoning, including what was rejected**, or the decision gets
  re-litigated.
- **Write prose, not fragments.** Full sentences, no bare ticket references.

## Guardrails — ask before proceeding

Never do the following without explicit human confirmation, even if the task
implies it or a tool makes it easy:

### Version control
- Force-pushing to any branch, especially `main`/`master`/`develop`
- Rewriting shared history (rebase, amend, filter-branch) on a pushed branch
- Deleting branches or tags
- Committing directly to protected branches instead of opening a PR
- Merging your own PR

### Destructive / irreversible operations
- `rm -rf`, bulk file deletion, or deleting anything you didn't create this session
- Dropping or truncating database tables, or dropping a database
- Running migrations against a non-local database (staging/prod)
- Deleting cloud resources (buckets, VMs, DNS records, load balancers, etc.)
- Overwriting existing files with generated content instead of diffing/patching

### Security & secrets
- Committing API keys, tokens, passwords, or `.env` files
- Adding third-party dependencies without checking their maintenance/security posture
- Disabling auth checks, CORS restrictions, or security middleware "to make it work"
- Changing permissions/IAM roles/access policies

### Environment & infra
- Modifying CI/CD pipelines, deploy scripts, or infra-as-code
- Changing environment variables in staging/production
- Deploying to production
- Upgrading major versions of core dependencies (framework, language, DB driver)
- Changing lockfiles in ways that shift many transitive deps

### Quality gates
- Skipping, deleting, or weakening tests to make a build pass
- Disabling linters/type-checkers instead of fixing the underlying issue
- Merging with failing CI
- Suppressing errors with broad catch-alls instead of handling them

### Scope
- Refactors that touch more than a handful of unrelated files
- Changing public APIs / signatures other code depends on
- Renaming or moving files/directories that other tooling may reference

## General behavior
- Prefer the smallest diff that solves the problem.
- If a task requires one of the above, stop, explain what and why, and wait for
  a yes. Don't do a "dry run" that quietly performs the action.
- If instructions are ambiguous and the ambiguity touches the list above, ask.
- Run the existing test suite (or the relevant subset) before declaring a
  change done.
- State assumptions explicitly.
