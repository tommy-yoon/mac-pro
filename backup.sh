#!/usr/bin/env bash
set -euo pipefail

# Source files to copy into the current directory.
FILES=(
  "/Users/tommy/.zshrc"
  # "/Users/tommy/.gitconfig"
)

REMOTE="origin"
COMMIT_MSG="Backup $(date '+%Y-%m-%d %H:%M:%S %Z')"

# Ensure we are inside a Git working tree.
if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "Error: Run this script inside a Git repository." >&2
  exit 1
fi

# Use the currently checked-out branch.
if ! BRANCH="$(git symbolic-ref --quiet --short HEAD)"; then
  echo "Error: Detached HEAD. Check out a branch first." >&2
  exit 1
fi

# Check the remote before copying or committing.
if ! git remote get-url "$REMOTE" >/dev/null 2>&1; then
  echo "Error: Git remote '$REMOTE' is not configured." >&2
  exit 1
fi

# Validate every source before copying any files.
for src in "${FILES[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "Error: Source file not found: '$src'" >&2
    exit 1
  fi
done

# Copy files into the directory where the script was invoked.
for src in "${FILES[@]}"; do
  cp -- "$src" .
  printf 'Copied: %s -> ./%s\n' "$src" "$(basename "$src")"
done

# Stage all repository changes, including additions and deletions.
git add -A

# Only create a commit when staged changes exist.
if git diff --cached --quiet; then
  echo "No changes to commit."
else
  git commit -m "$COMMIT_MSG"
fi

# Push even if no new commit was needed, in case local commits are unpushed.
git push "$REMOTE" "HEAD:refs/heads/$BRANCH"

echo "Backup pushed to $REMOTE/$BRANCH."
