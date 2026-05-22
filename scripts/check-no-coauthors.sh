#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-}"
MESSAGE_FILE="${2:-}"

forbidden_patterns=(
  'Co-authored-by:'
  'Co Authored By:'
  'co-authored-by:'
  'co authored by:'
  'LLM'
  'llm'
  'ChatGPT'
  'chatgpt'
  'Claude'
  'claude'
  'Copilot'
  'copilot'
)

check_text() {
  local label="$1"
  local text="$2"

  for pattern in "${forbidden_patterns[@]}"; do
    if grep -Fqi "$pattern" <<<"$text"; then
      cat >&2 <<EOF
Commit rejected by $label.
Forbidden coauthor or AI marker found: $pattern
Remove the co-author footer or AI attribution before committing.
EOF
      exit 1
    fi
  done
}

case "$MODE" in
  commit-msg)
    if [[ -z "$MESSAGE_FILE" || ! -f "$MESSAGE_FILE" ]]; then
      echo "Missing commit message file for commit-msg hook." >&2
      exit 1
    fi
    check_text "commit-msg hook" "$(cat "$MESSAGE_FILE")"
    ;;
  pre-commit)
    if [[ -f .git/COMMIT_EDITMSG ]]; then
      check_text "pre-commit hook" "$(cat .git/COMMIT_EDITMSG)"
    fi
    ;;
  *)
    echo "Usage: $0 <pre-commit|commit-msg> [message-file]" >&2
    exit 1
    ;;
esac

