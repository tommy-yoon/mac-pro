#!/usr/bin/env bash
set -euo pipefail

# Absolute paths of files to back up.
# Review for passwords, tokens and other sensitive content before committing.
FILES=(
  # Shell configuration — includes wiki and wiki-auto functions.
  "/Users/tommy/.zshrc"

  # Wiki automation and backups.
  "/Users/tommy/.local/bin/wiki-auto-run"
  "/Users/tommy/.local/bin/wiki-backup"

  # Privileged import/publish helpers.
  "/Library/PrivilegedHelperTools/llm-wiki/import"
  "/Library/PrivilegedHelperTools/llm-wiki/publish"

  # Hourly scheduler.
  "/Users/tommy/Library/LaunchAgents/local.llm-wiki.auto.plist"

  # Workspace instructions.
  "/Users/codex/llm-wiki/AGENTS.md"
  "/Users/codex/llm-wiki/AI-knowledge-base/SCHEMA.md"

  # Google Drive instructions — preserve both copies.
  "/Users/tommy/My Drive/obsidian/tommy-obsedian-default/AGENTS.md"
  "/Users/tommy/My Drive/obsidian/tommy-obsedian-default/AI-knowledge-base/SCHEMA.md"

  # Optional — confirm existence and review contents before uncommenting.
  # "/Users/tommy/.zprofile"
  # "/Users/tommy/.zshenv"
  # "/Users/tommy/.gitconfig"
  # "/Users/tommy/.ssh/config"

  # Codex configuration — confirm actual location; remove secrets first.
  # "/Users/codex/.codex/config.toml"
  # "/Users/tommy/.codex/config.toml"
  # "/Users/codex/llm-wiki/.codex/config.toml"

  # SearXNG — use a sanitised copy if this contains a secret_key.
  # "/Users/tommy/searxng/settings.yml"

  # Add exact paths after locating:
  # - Wiki-specific sudoers configuration.
  # - Other custom LaunchAgent plists.
  # - Open WebUI startup/configuration files (sanitised).
  # - Custom Ollama Modelfiles.
  # - ComfyUI workflow files.
  # - Exported Brewfile and dependency lists.
  # - RESTORE.md recovery instructions.
)

# Run as tommy, not sudo.
if [[ "$EUID" -eq 0 ]]; then
  echo "Error: Run as tommy, not with sudo." >&2
  exit 1
fi

REMOTE="origin"
COMMIT_MSG="Backup $(date '+%Y-%m-%d %H:%M:%S %Z')"
BACKUP_DIR="$(pwd -P)"

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "Error: Run inside a Git repository." >&2
  exit 1
fi

if ! BRANCH="$(git symbolic-ref --quiet --short HEAD)"; then
  echo "Error: Detached HEAD. Check out a branch first." >&2
  exit 1
fi

if ! git remote get-url "$REMOTE" >/dev/null 2>&1; then
  echo "Error: Remote '$REMOTE' is not configured." >&2
  exit 1
fi

# Avoid committing unrelated changes already staged.
if ! git diff --cached --quiet; then
  echo "Error: Unrelated changes are already staged. Commit or unstage them first." >&2
  exit 1
fi

PRIVILEGED=()
DESTINATIONS=()

# Validate all sources and destinations before copying.
for src in "${FILES[@]}"; do
  case "$src" in
    /*) ;;
    *)
      echo "Error: Source must be absolute: '$src'" >&2
      exit 1
      ;;
  esac

  case "$src/" in
    */../*|*/./*|*//*)
      echo "Error: Unsafe source path: '$src'" >&2
      exit 1
      ;;
  esac

  dest="$BACKUP_DIR/${src#/}"

  if [[ "$dest" == "$src" ]]; then
    echo "Error: Destination would overwrite the source: '$src'" >&2
    exit 1
  fi

  candidate="$dest"
  while [[ "$candidate" != "$BACKUP_DIR" ]]; do
    if [[ -L "$candidate" ]]; then
      echo "Error: Destination contains a symlink: '$candidate'" >&2
      exit 1
    fi
    candidate="$(dirname "$candidate")"
  done

  if [[ -e "$dest" && ! -f "$dest" ]]; then
    echo "Error: Destination is not a regular file: '$dest'" >&2
    exit 1
  fi

  if [[ -f "$src" && -r "$src" ]]; then
    PRIVILEGED+=(0)
  else
    /usr/bin/sudo -v

    if ! /usr/bin/sudo /bin/test -f "$src" ||
       ! /usr/bin/sudo /bin/test -r "$src"; then
      echo "Error: Source missing or unreadable: '$src'" >&2
      exit 1
    fi

    PRIVILEGED+=(1)
  fi

  DESTINATIONS+=("$dest")
done

# Copy through a temporary file to avoid partially replacing a destination.
tmp=""
trap 'if [[ -n "$tmp" ]]; then /bin/rm -f "$tmp"; fi' EXIT

for i in "${!FILES[@]}"; do
  src="${FILES[$i]}"
  dest="${DESTINATIONS[$i]}"
  parent="$(dirname "$dest")"

  mkdir -p "$parent"
  tmp="$(mktemp "$parent/.copy.XXXXXX")"

  if [[ "${PRIVILEGED[$i]}" -eq 1 ]]; then
    /usr/bin/sudo /bin/cat "$src" > "$tmp"
  else
    /bin/cat "$src" > "$tmp"
  fi

  # Preserve whether the source is executable.
  if [[ "${PRIVILEGED[$i]}" -eq 1 ]]; then
    if /usr/bin/sudo /bin/test -x "$src"; then
      chmod 700 "$tmp"
    else
      chmod 600 "$tmp"
    fi
  elif [[ -x "$src" ]]; then
    chmod 700 "$tmp"
  else
    chmod 600 "$tmp"
  fi

  /bin/mv -f "$tmp" "$dest"
  tmp=""

  printf 'Copied: %s\n' "$src"
done

# Stage only the listed copies, not unrelated repository changes.
git add -A

if git diff --cached --quiet; then
  echo "No changes to commit."
else
  git commit -m "$COMMIT_MSG"
fi

git push "$REMOTE" "HEAD:refs/heads/$BRANCH"

echo "Files pushed to $REMOTE/$BRANCH."