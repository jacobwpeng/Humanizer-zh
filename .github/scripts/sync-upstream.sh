#!/usr/bin/env bash
# Regenerate the current branch from upstream. The upstream tree is
# authoritative; only .github/ belongs to this fork.
#   upstream has root SKILL.md -> placed under skills/<frontmatter name>/
#   otherwise                  -> mirrored as-is
set -euo pipefail

UPSTREAM_URL=${UPSTREAM_URL:-https://github.com/op7418/Humanizer-zh.git}
UPSTREAM_BRANCH=${UPSTREAM_BRANCH:-main}

branch=$(git symbolic-ref --short HEAD)
git diff --quiet HEAD || { echo "working tree is dirty" >&2; exit 1; }

git fetch --quiet "$UPSTREAM_URL" "$UPSTREAM_BRANCH"
upstream=$(git rev-parse FETCH_HEAD)
head=$(git rev-parse HEAD)

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

export GIT_INDEX_FILE=$tmp/index
git read-tree --empty
if git cat-file -e "$upstream:SKILL.md" 2>/dev/null; then
  name=$(git show "$upstream:SKILL.md" | awk '
    NR == 1 { if ($0 != "---") exit; next }
    $0 == "---" { exit }
    /^name:/ { sub(/^name:[ \t]*/, ""); gsub(/["\047\r]/, ""); print; exit }')
  if [[ ! $name =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    echo "invalid skill name in upstream SKILL.md: '$name'" >&2
    exit 1
  fi
  git read-tree --prefix="skills/$name/" "$upstream"
else
  git read-tree "$upstream"
  git rm --cached -r -q -f --ignore-unmatch .github
fi
git read-tree --prefix=.github/ "$head:.github"
tree=$(git write-tree)
unset GIT_INDEX_FILE

parents=(-p "$head")
git merge-base --is-ancestor "$upstream" "$head" || parents+=(-p "$upstream")
if [[ $tree == "$(git rev-parse "$head^{tree}")" && ${#parents[@]} -eq 2 ]]; then
  echo "up to date with upstream ${upstream:0:8}"
  exit 0
fi

mkdir "$tmp/tree"
git archive "$tree" | tar -x -C "$tmp/tree"
gh skill install "$tmp/tree" --from-local --all --dir "$tmp/installed" </dev/null

commit=$(git commit-tree "$tree" "${parents[@]}" \
  -m "sync: upstream ${upstream:0:8}" \
  -m "Upstream: $UPSTREAM_URL@$upstream")
git update-ref "refs/heads/$branch" "$commit" "$head"
git reset -q --hard
echo "synced upstream ${upstream:0:8} -> ${commit:0:8}"
