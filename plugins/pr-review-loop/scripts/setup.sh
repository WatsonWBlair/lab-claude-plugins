#!/bin/bash
# pr-review-loop slash command setup script
# Parses args, initializes state files (our loop state + ralph framework state),
# extends .gitignore, prints PROMPT.md so Claude reads it for the first iteration.
#
# Re-feeding on subsequent cycles is handled by ralph-loop's stop hook reading
# .claude/ralph-loop.local.md (which carries PROMPT.md content as its body).
#
# Portability: this script ships inside a Claude Code plugin. It locates its own
# bundled files via ${CLAUDE_PLUGIN_ROOT} (set by the plugin runtime). PROMPT.md
# carries an @@PLUGIN_ROOT@@ placeholder in its reference-file paths; this script
# expands it to the absolute install path when emitting PROMPT.md so the paths
# resolve for the looping Claude instance on every cycle.

set -euo pipefail

# --- Resolve plugin root ---
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
if [[ -z "$PLUGIN_ROOT" ]]; then
  echo "❌ CLAUDE_PLUGIN_ROOT is not set — run this via the /pr-review-loop command, not directly." >&2
  exit 1
fi

# --- Defaults ---
MAX_ITERATIONS=5
BAR="0-blockers"
RESTART=0
PR_NUMBER=""

# --- Argument parse ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --max-iterations)
      if [[ -z "${2:-}" || ! "${2}" =~ ^[0-9]+$ ]]; then
        echo "❌ --max-iterations requires a non-negative integer (got: ${2:-<missing>})" >&2
        exit 1
      fi
      MAX_ITERATIONS="$2"; shift 2 ;;
    --bar)
      if [[ -z "${2:-}" ]]; then
        echo "❌ --bar requires a value (v1: only '0-blockers')" >&2
        exit 1
      fi
      if [[ "$2" != "0-blockers" ]]; then
        echo "❌ v1 supports only --bar 0-blockers; got: $2" >&2
        exit 1
      fi
      BAR="$2"; shift 2 ;;
    --restart)
      RESTART=1; shift ;;
    -h|--help)
      cat <<HELP_EOF
/pr-review-loop — drive a PR to merge via review-remediate cycles

USAGE:
  /pr-review-loop <PR#> [--max-iterations N] [--bar VALUE] [--restart]

ARGS:
  <PR#>                  Positional. GitHub PR number to drive.

OPTIONS:
  --max-iterations <N>   Safety bound on cycles (default: 5)
  --bar <VALUE>          Merge bar (v1: '0-blockers' only; default)
  --restart              Overwrite existing state file (loop already in flight)
  -h, --help             Show this help

See: ${PLUGIN_ROOT}/skills/pr-review-loop/SKILL.md
HELP_EOF
      exit 0 ;;
    --*)
      echo "❌ Unknown flag: $1 (try --help)" >&2; exit 1 ;;
    *)
      if [[ -n "$PR_NUMBER" ]]; then
        echo "❌ multiple positional args; expected just <PR#>" >&2; exit 1
      fi
      if [[ ! "$1" =~ ^[0-9]+$ ]]; then
        echo "❌ <PR#> must be a positive integer (got: $1)" >&2; exit 1
      fi
      PR_NUMBER="$1"; shift ;;
  esac
done

if [[ -z "$PR_NUMBER" ]]; then
  echo "❌ <PR#> is required. Try: /pr-review-loop --help" >&2
  exit 1
fi

# --- Refuse to clobber an active loop ---
STATE_DIR=".claude"
STATE_FILE="$STATE_DIR/.pr-review-loop.state.json"

if [[ -f "$STATE_FILE" && "$RESTART" -ne 1 ]]; then
  existing_pr=$(grep -o '"pr_number"[[:space:]]*:[[:space:]]*[0-9]*' "$STATE_FILE" | head -1 | grep -o '[0-9]*$' || echo "?")
  existing_pass=$(grep -o '"pass"[[:space:]]*:[[:space:]]*[0-9]*' "$STATE_FILE" | head -1 | grep -o '[0-9]*$' || echo "?")
  cat >&2 <<ERR
❌ Loop already in flight: PR #$existing_pr, pass $existing_pass.
   Either:
     • /cancel-ralph    (then re-run this command), or
     • /pr-review-loop $PR_NUMBER --restart   (overwrite state)
ERR
  exit 1
fi

# --- Derive repo + branch via gh ---
if ! REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null); then
  echo "❌ gh repo view failed — not a GitHub repo, or gh not authenticated" >&2
  exit 1
fi
if ! BRANCH=$(gh pr view "$PR_NUMBER" --json headRefName -q '.headRefName' 2>/dev/null); then
  echo "❌ gh pr view $PR_NUMBER failed — PR not found or no access" >&2
  exit 1
fi

# --- Write our loop state ---
mkdir -p "$STATE_DIR"
STARTED_AT=$(date -Iseconds 2>/dev/null || date -u +'%Y-%m-%dT%H:%M:%SZ')

cat > "$STATE_FILE" <<JSON
{
  "pr_number": $PR_NUMBER,
  "repo": "$REPO",
  "branch": "$BRANCH",
  "started_at": "$STARTED_AT",
  "pass": 1,
  "max_iterations": $MAX_ITERATIONS,
  "bar": "$BAR",
  "blocker_history": [],
  "last_blocker_text": "",
  "status": "running",
  "completion_reason": null,
  "consent_to_post_pr_comments": null
}
JSON

# --- Locate PROMPT.md and prepare placeholder expansion ---
PROMPT_PATH="$PLUGIN_ROOT/skills/pr-review-loop/PROMPT.md"
if [[ ! -f "$PROMPT_PATH" ]]; then
  echo "❌ PROMPT.md missing at $PROMPT_PATH — plugin install incomplete" >&2
  exit 1
fi
# Expand @@PLUGIN_ROOT@@ to the absolute install path so the looping Claude
# instance can Read the bundled reference files on every cycle.
emit_prompt() { sed "s|@@PLUGIN_ROOT@@|$PLUGIN_ROOT|g" "$PROMPT_PATH"; }

# --- Hand off to ralph framework ---
# Write .claude/ralph-loop.local.md so ralph-loop's stop hook re-feeds PROMPT.md
# each cycle. Body of this file is what gets re-fed (with paths already expanded).
cat > "$STATE_DIR/ralph-loop.local.md" <<RALPH_EOF
---
active: true
iteration: 1
session_id: ${CLAUDE_CODE_SESSION_ID:-}
max_iterations: $MAX_ITERATIONS
completion_promise: "LOOP_DONE"
started_at: "$STARTED_AT"
---

$(emit_prompt)
RALPH_EOF

# --- Extend .gitignore (idempotent) ---
GITIGNORE=".gitignore"
PATTERN=".claude/.pr-review-loop.state.json"
if [[ -f "$GITIGNORE" ]] && grep -qxF "$PATTERN" "$GITIGNORE" 2>/dev/null; then
  : # already present
else
  {
    echo ""
    echo "# pr-review-loop skill state (regenerated each /pr-review-loop invocation)"
    echo "$PATTERN"
  } >> "$GITIGNORE"
fi

# --- Status banner ---
cat <<DONE
🔄 pr-review-loop initialised
  PR:     #$PR_NUMBER on $REPO
  Branch: $BRANCH
  State:  $STATE_FILE (pass 1 of $MAX_ITERATIONS)
  Bar:    $BAR
  Ralph:  $STATE_DIR/ralph-loop.local.md (completion promise: LOOP_DONE)

The ralph stop hook will re-feed PROMPT.md each cycle until <promise>LOOP_DONE</promise> is emitted.
Cancel mid-loop: /cancel-ralph

DONE

# --- Emit PROMPT.md (paths expanded) so Claude reads it for iteration 1 ---
emit_prompt
