#!/usr/bin/env bash
set -euo pipefail

##
# Project-aware snapshot generator
# Run from anywhere; it figures out the project root based on script location.
##

# Resolve project root (assuming script lives in tool/ under project root)
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}" &>/dev/null && pwd)"
cd "$ROOT_DIR"

PROJECT_NAME="$(basename "$ROOT_DIR")"
STAMP="$(date '+%Y%m%d-%H%M%S')"
OUT_DIR="${HOME}/tmp"
OUT="${OUT_DIR}/${PROJECT_NAME}-src-${STAMP}.txt"

mkdir -p "$OUT_DIR"

section() {
  local title="$1"
  printf '\n\n===============================================\n' >> "$OUT"
  printf '=== %s\n' "$title" >> "$OUT"
  printf '===============================================\n\n' >> "$OUT"
}

subsection() {
  local title="$1"
  printf '\n----- %s -----\n\n' "$title" >> "$OUT"
}

dump_file_if_exists() {
  local path="$1"
  if [ -f "$path" ]; then
    subsection "$path"
    cat "$path" >> "$OUT"
    printf '\n' >> "$OUT"
  fi
}

dump_dir_sources() {
  local dir="$1"
  [ -d "$dir" ] || return 0

  find "$dir" -type f \( -name '*.dart' -o -name '*.md' \) -print0 \
    | sort -z \
    | while IFS= read -r -d '' f; do
        printf '\n===== %s =====\n\n' "$f" >> "$OUT"
        cat "$f" >> "$OUT"
        printf '\n' >> "$OUT"
      done
}

echo "Creating snapshot at: $OUT"

########################################
# 1) Header
########################################
{
  echo "Project:   ${PROJECT_NAME}"
  echo "Root dir:  ${ROOT_DIR}"
  echo "Created:   ${STAMP}"
} > "$OUT"

########################################
# 2) Git metadata (if this is a git repo)
########################################
if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null; then
  section "Git metadata"
  {
    echo "Branch:  $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'N/A')"
    echo "Commit:  $(git rev-parse HEAD 2>/dev/null || echo 'N/A')"
    echo
    echo "Status (short):"
    git status --short || true
  } >> "$OUT"
fi

########################################
# 3) Project tree(s)
########################################
section "Project tree (JSON, gitignored)"

# Full tree – JSON format
if command -v tree &>/dev/null; then
  # This avoids android/ios/linux/web/windows/macos/etc completely.
  subsection "tree -iJ --gitignore lib test"
  tree -iJ --gitignore lib test >> "$OUT" || true
else
  echo "WARN: 'tree' command not found, skipping project tree" >> "$OUT"
fi
########################################
# 4) Key project files
########################################
section "Key project files"

dump_file_if_exists "pubspec.yaml"
#dump_file_if_exists "pubspec.lock"
dump_file_if_exists "analysis_options.yaml"
dump_file_if_exists "README.md"
dump_file_if_exists "CHANGELOG.md"
dump_file_if_exists "LICENSE"
dump_file_if_exists "BLUEPRINT.md"

########################################
# 5) lib/ sources
########################################
section "lib/ source files (*.dart, *.md)"
dump_dir_sources "lib"

########################################
# 6) test/ sources
########################################
section "test/ source files (*.dart, *.md)"
dump_dir_sources "test"

echo "Snapshot written to: $OUT"

