#!/usr/bin/env bash
set -euo pipefail

SKILL_REPO="DUBSOpenHub/looper"
SKILL_NAME="looper"
SKILL_DIR="$HOME/.copilot/skills/$SKILL_NAME"
RAW_BASE="https://raw.githubusercontent.com/$SKILL_REPO/main/skills/$SKILL_NAME"
FILES=(
  "SKILL.md"
  "scripts/pass-ledger.sh"
  "scripts/test_pass_ledger.py"
  "templates/state.md"
)

echo ""
echo "🔁 Looper"
echo "─────────────────────────────────────────"

stage=$(mktemp -d "${TMPDIR:-/tmp}/looper-install.XXXXXX")
trap 'rm -rf "$stage"' EXIT

script_dir=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
fi

if [[ -n "$script_dir" && -f "$script_dir/skills/$SKILL_NAME/SKILL.md" ]]; then
  echo "📥 Installing from local checkout..."
  for f in "${FILES[@]}"; do
    mkdir -p "$stage/$(dirname "$f")"
    cp "$script_dir/skills/$SKILL_NAME/$f" "$stage/$f"
  done
else
  echo "📥 Downloading Looper..."
  for f in "${FILES[@]}"; do
    mkdir -p "$stage/$(dirname "$f")"
    if ! curl -fsSL "$RAW_BASE/$f" -o "$stage/$f"; then
      echo "❌ Failed to download $f. Check your internet connection."
      exit 1
    fi
  done
fi

if ! grep -q '^name: looper$' "$stage/SKILL.md"; then
  echo "❌ Downloaded SKILL.md is not the looper skill; nothing was installed."
  exit 1
fi

# Replace only the skill files; never touch project state, which lives in each project's .ralph-loop/.
mkdir -p "$SKILL_DIR/scripts" "$SKILL_DIR/templates"
for f in "${FILES[@]}"; do
  cp "$stage/$f" "$SKILL_DIR/$f"
done
chmod +x "$SKILL_DIR/scripts/pass-ledger.sh"

echo "✅ Skill installed to $SKILL_DIR"
echo ""
echo "─────────────────────────────────────────"
echo "🔁 Open the GitHub Copilot CLI in your project and say: looper"
echo "─────────────────────────────────────────"
echo ""
