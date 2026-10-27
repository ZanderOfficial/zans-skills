#!/usr/bin/env bash
# Install the Zan skills so they run by their bare names (/bughunt, /designflow,
# /impeccable, ...) instead of the plugin-namespaced form (/zans-skills:bughunt).
#
#   ./install.sh                          everything -> ~/.claude/skills (every repo on this machine)
#   ./install.sh /path/to/repo            everything -> /path/to/repo/.claude/skills
#                                         (commit it: works in that repo for everyone,
#                                         including Claude Code cloud sessions)
#   ./install.sh --only bughunt,planissues [/path/to/repo]
#                                         just those skills, plus the stacked skills
#                                         they need (always including shared/)
#   ./install.sh --qwen [--only a,b] [/path/to/repo]
#                                         the same, but for Qwen Code: into ~/.qwen or
#                                         /path/to/repo/.qwen instead of .claude
#
# The source is grouped by skill (bughunt/, issuecoder/, ... , shared/); the
# install is flat, because Claude Code finds skills at <dir>/<name>/SKILL.md.
# Existing copies of these skills and agents are replaced; nothing else is touched.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
all_groups="bughunt issuecoder prreviewer prreviewall designflow planissues zanpass"
groups="$all_groups"

config_dir=".claude"
while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --only)
      [[ $# -ge 2 ]] || { echo "usage: $0 [--qwen] [--only a,b] [repo-path]" >&2; exit 2; }
      groups="${2//,/ }"
      shift 2 ;;
    --qwen)
      config_dir=".qwen"
      shift ;;
    *)
      echo "unknown option: $1 (usage: $0 [--qwen] [--only a,b] [repo-path])" >&2; exit 2 ;;
  esac
done
for g in $groups; do
  [[ " $all_groups " == *" $g "* ]] || { echo "unknown skill group: $g (choose from: $all_groups)" >&2; exit 2; }
done
# /prreviewall reads prreviewer's SKILL.md at run time, so it needs that group.
[[ " $groups " == *" prreviewall "* && " $groups " != *" prreviewer "* ]] && groups="$groups prreviewer"
# /zanpass reads the SKILL.md of every skill it routes to, /designflow included.
[[ " $groups " == *" zanpass "* ]] && for g in bughunt issuecoder prreviewer prreviewall planissues designflow; do
  [[ " $groups " == *" $g "* ]] || groups="$groups $g"
done
groups="$groups shared"

if [[ $# -ge 1 ]]; then
  base="$1/$config_dir"
else
  base="${HOME}/$config_dir"
fi
mkdir -p "$base/skills" "$base/agents"

for g in $groups; do
  for skill in "$here/$g"/*/; do
    name="$(basename "$skill")"
    rm -rf "${base:?}/skills/$name"
    cp -R "$skill" "$base/skills/$name"
    echo "installed /$name  ($g)"
  done
done

# Named subagents used by the thermos reviews (prreviewer) and by Impeccable (designflow).
for agent in "$here"/agents/*.md; do
  case "$(basename "$agent")" in
    thermo-nuclear-*) [[ " $groups " == *" prreviewer "* ]] || continue ;;
    impeccable-*)     [[ " $groups " == *" designflow "* ]] || continue ;;
  esac
  if [[ "$config_dir" == ".qwen" ]]; then
    # The tools: allowlist uses Claude Code tool names (Read, Bash, ...), which
    # Qwen Code does not recognise; without it the agent inherits the session's tools.
    awk 'NR == 1 || !done { if (/^---$/ && NR > 1) done = 1; if (!done && /^tools:/) next } { print }' \
      "$agent" > "$base/agents/$(basename "$agent")"
  else
    cp "$agent" "$base/agents/"
  fi
  echo "installed agent $(basename "$agent" .md)"
done
