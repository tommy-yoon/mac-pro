#!/usr/bin/env bash
set -euo pipefail

# --- Configuration ---
REPO_DIR="/Users/tommy/gitrepo/mac-pro"
BRANCH="main"
COMMIT_MSG="Update files ($(date '+%Y-%m-%d %H:%M'))"

# List "source_file:dest_relative_path_inside_repo"
FILES=(
  "/Users/tommy/.zshrc"
)
# ---------------------

if [ ! -d "$REPO_DIR/.git" ]; then
  echo "Error: '$REPO_DIR' is not a Git repository." >&2
  exit 1
fi

for mapping in "${FILES[@]}"; do
  src="${mapping%%:*}"
  dest_rel="${mapping#*:}"
  dest="$REPO_DIR/$dest_rel"

  if [ ! -f "$src" ]; then
    echo "Error: Source file not found: '$src'" >&2
    exit 1
  fi

  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "Copied: $src -> $dest_rel"
done

cd "$REPO_DIR"

# Stage only the mapped destination files
for mapping in "${FILES[@]}"; do
  dest_rel="${mapping#*:}"
  git add "$dest_rel"
done

# Commit only when there are staged changes
if git diff --cached --quiet; then
  echo "No changes detected. Nothing to commit or push."
  exit 0
fi

git commit -m "$COMMIT_MSG"
git push origin "$BRANCH"
echo "Pushed changes to origin/$BRANCH."
