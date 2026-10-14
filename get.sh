#!/usr/bin/env bash
# One-line installer: fetch zans-skills from GitHub and install it into the
# repository you are standing in, with no plugin and no local clone to keep.
#
# From inside a Claude Code session (local or cloud), type at the prompt:
#
#   ! curl -fsSL https://raw.githubusercontent.com/ZanderOfficial/zans-skills/main/get.sh | bash
#
# The leading "!" runs it as a shell command in the session's repository.
# Arguments go after "bash -s --":
#
#   ... | bash -s -- --only bughunt,planissues   just those skills (and what they stack)
#   ... | bash -s -- --global                    into ~/.claude for every repo on this machine
#   ... | bash -s -- --qwen                      into .qwen instead of .claude
#
# By default the target is the root of the current git repository (or the
# current directory outside one). Commit .claude/skills/ and .claude/agents/
# so the skills also load in cloud sessions and for everyone on the repo.
# ZANS_SKILLS_REF picks a branch or tag other than main.
set -euo pipefail

repo="ZanderOfficial/zans-skills"
ref="${ZANS_SKILLS_REF:-main}"

pass=()
global=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --global) global=1; shift ;;
    --only)
      [[ $# -ge 2 ]] || { echo "usage: get.sh [--global] [--qwen] [--only a,b]" >&2; exit 2; }
      pass+=("$1" "$2"); shift 2 ;;
    --qwen) pass+=("$1"); shift ;;
    *) echo "unknown option: $1 (usage: get.sh [--global] [--qwen] [--only a,b])" >&2; exit 2 ;;
  esac
done

if [[ $global -eq 0 ]]; then
  target="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  pass+=("$target")
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "fetching $repo@$ref ..."
if command -v git >/dev/null 2>&1; then
  git clone --quiet --depth 1 --branch "$ref" "https://github.com/$repo.git" "$tmp/src"
else
  mkdir "$tmp/src"
  curl -fsSL "https://codeload.github.com/$repo/tar.gz/$ref" | tar -xz -C "$tmp/src" --strip-components 1
fi

bash "$tmp/src/install.sh" "${pass[@]}"

if [[ $global -eq 0 ]]; then
  echo
  echo "done. Commit .claude/skills/ and .claude/agents/ in $target to share them"
  echo "(cloud sessions only see skills that are committed to the repository)."
  echo "Restart the Claude Code session if the new /commands don't show up yet."
fi
