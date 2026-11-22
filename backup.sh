#!/usr/bin/env bash
set -euo pipefail

# Absolute paths of files to back up.
FILES=(
  "/Users/tommy/.zshrc"
  # "/Users/tommy/.gitconfig"
)

REMOTE="origin"
COMMIT_MSG="Backup $(date '+%Y-%m-%d %H:%M:%S %Z')"

# Back up underneath the directory where this script is invoked.
BACKUP_DIR="$(pwd -P)"

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

# Validate all source paths before copying anything.
for src in "${FILES[@]}"; do
  case "$src" in
    /*) ;;
    *)
      echo "Error: Source must be an absolute path: '$src'" >&2
      exit 1
      ;;
  esac

  # Reject path traversal so destinations stay under BACKUP_DIR.
  case "$src/" in
    */../*|*/./*)
      echo "Error: Source path must not contain '.' or '..': '$src'" >&2
      exit 1
      ;;
  esac

  if [[ ! -f "$src" ]]; then
    echo "Error: Source file not found: '$src'" >&2
    exit 1
  fi
done

# Preserve each source path underneath the current directory.
for src in "${FILES[@]}"; do
  relative_path="${src#/}"
  dest="$BACKUP_DIR/$relative_path"

  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"

  printf 'Copied: %s -> %s\n' "$src" "$dest"
done

# Stage all repository changes, including additions and deletions.
git add -A

# Commit only when staged changes exist.
if git diff --cached --quiet; then
  echo "No changes to commit."
else
  git commit -m "$COMMIT_MSG"
fi

# Also push any previously unpushed commits.
git push "$REMOTE" "HEAD:refs/heads/$BRANCH"

echo "Backup pushed to $REMOTE/$BRANCH."