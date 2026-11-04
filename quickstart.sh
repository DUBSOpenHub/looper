#!/usr/bin/env bash
# Install the Looper skill into ~/.copilot/skills/looper/.
#
# Piped from a release (the default), this downloads one pinned version,
# checks it against the release's SHA256SUMS, and installs only the skill files.
#   LOOPER_VERSION=vX.Y.Z          release to install; branch names are refused
#   LOOPER_SHA256=<hex>            optional: also require this exact tarball checksum
#   LOOPER_VERIFY_ATTESTATION=1    optional: also verify GitHub build provenance (needs gh)
# Run from a clone (./quickstart.sh), it installs that checkout instead.
set -euo pipefail

SKILL_REPO="DUBSOpenHub/looper"
SKILL_NAME="looper"
LOOPER_VERSION="${LOOPER_VERSION:-v1.1.0}"
SKILL_DIR="$HOME/.copilot/skills/$SKILL_NAME"
FILES=(
  "SKILL.md"
  "scripts/pass-ledger.sh"
  "scripts/test_pass_ledger.py"
  "templates/state.md"
)

fail() {
  echo "❌ $*" >&2
  exit 1
}

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    fail "Neither sha256sum nor shasum is available, so the download cannot be verified; nothing was installed."
  fi
}

echo ""
echo "🔁 Looper"
echo "─────────────────────────────────────────"

stage=$(mktemp -d "${TMPDIR:-/tmp}/looper-install.XXXXXX")
trap 'rm -rf "$stage"' EXIT
mkdir "$stage/skill"

script_dir=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
fi

if [[ -n "$script_dir" && -f "$script_dir/skills/$SKILL_NAME/SKILL.md" ]]; then
  echo "📥 Installing from local checkout..."
  source_dir="$script_dir/skills/$SKILL_NAME"
else
  [[ "$LOOPER_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] \
    || fail "LOOPER_VERSION must be a release tag such as v1.1.0, not '$LOOPER_VERSION'."
  base="${LOOPER_RELEASE_URL:-https://github.com/$SKILL_REPO/releases/download/$LOOPER_VERSION}"
  tarball="looper-$LOOPER_VERSION.tar.gz"

  echo "📥 Downloading Looper $LOOPER_VERSION..."
  for asset in "$tarball" SHA256SUMS; do
    curl -fsSL --proto '=https,file' --proto-redir '=https' "$base/$asset" -o "$stage/$asset" \
      || fail "Failed to download $asset for $LOOPER_VERSION. Check the version and your connection."
  done

  echo "🔐 Verifying checksum..."
  expected=$(awk -v f="$tarball" '$2 == f || $2 == "*" f {print $1}' "$stage/SHA256SUMS")
  [[ "$expected" =~ ^[0-9a-f]{64}$ ]] || fail "SHA256SUMS has no single valid entry for $tarball; nothing was installed."
  actual=$(sha256_of "$stage/$tarball")
  [[ "$actual" == "$expected" ]] || fail "Checksum mismatch for $tarball; nothing was installed."
  if [[ -n "${LOOPER_SHA256:-}" ]]; then
    pin=$(printf '%s' "$LOOPER_SHA256" | tr 'A-F' 'a-f')
    [[ "$actual" == "$pin" ]] || fail "$tarball does not match LOOPER_SHA256; nothing was installed."
  fi
  if [[ "${LOOPER_VERIFY_ATTESTATION:-0}" == 1 ]]; then
    command -v gh >/dev/null 2>&1 || fail "LOOPER_VERIFY_ATTESTATION=1 needs the GitHub CLI (gh)."
    gh attestation verify "$stage/$tarball" --repo "$SKILL_REPO" \
      --signer-workflow "$SKILL_REPO/.github/workflows/release.yml" \
      --source-ref "refs/tags/$LOOPER_VERSION" >/dev/null \
      || fail "Build provenance could not be verified for $tarball; nothing was installed."
    echo "✅ Build provenance verified"
  fi

  # Accept only plain relative paths under looper/, then reject any link the archive created.
  listing=$(tar -tzf "$stage/$tarball") || fail "$tarball is not a readable archive."
  while IFS= read -r entry; do
    [[ "$entry" =~ ^looper/[A-Za-z0-9._/-]*$ ]] || fail "Unexpected path in $tarball: $entry"
    case "/$entry/" in
      */../*|*/./*) fail "Unexpected path in $tarball: $entry" ;;
    esac
  done <<< "$listing"
  mkdir "$stage/extract"
  tar -xzf "$stage/$tarball" -C "$stage/extract" || fail "Could not extract $tarball."
  [[ -z "$(find "$stage/extract" -type l)" ]] || fail "$tarball contains links; nothing was installed."
  source_dir="$stage/extract/looper"
fi

for f in "${FILES[@]}"; do
  [[ -f "$source_dir/$f" && ! -L "$source_dir/$f" ]] || fail "$f is missing from the download; nothing was installed."
  mkdir -p "$stage/skill/$(dirname "$f")"
  cp "$source_dir/$f" "$stage/skill/$f"
done

if ! grep -q '^name: looper$' "$stage/skill/SKILL.md"; then
  fail "SKILL.md is not the looper skill; nothing was installed."
fi

# Replace only the skill files; never touch project state, which lives in each project's .ralph-loop/.
mkdir -p "$SKILL_DIR/scripts" "$SKILL_DIR/templates"
for f in "${FILES[@]}"; do
  cp "$stage/skill/$f" "$SKILL_DIR/$f"
done
chmod +x "$SKILL_DIR/scripts/pass-ledger.sh"

echo "✅ Skill installed to $SKILL_DIR"
echo ""
echo "─────────────────────────────────────────"
echo "🔁 Open GitHub Copilot in your project and say: looper"
echo "─────────────────────────────────────────"
echo ""
