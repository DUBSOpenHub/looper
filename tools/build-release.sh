#!/usr/bin/env bash
# Build the release assets for one version: the skill tarball, the installer, and SHA256SUMS.
# Usage: tools/build-release.sh vX.Y.Z OUTPUT_DIR [GIT_REF]
set -euo pipefail

die() {
    printf 'build-release: %s\n' "$*" >&2
    exit 1
}

[[ $# -ge 2 && $# -le 3 ]] || die 'usage: tools/build-release.sh vX.Y.Z OUTPUT_DIR [GIT_REF]'
version=$1
out=$2
ref=${3:-HEAD}
[[ "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "version must look like v1.2.3, got: $version"

root=$(git rev-parse --show-toplevel) || die 'run inside the looper repository'
case "$out" in
    /*) ;;
    *) out=$PWD/$out ;;
esac
cd "$root"
commit=$(git rev-parse --verify --quiet "$ref^{commit}") || die "unknown git ref: $ref"

# The installer's default version and the changelog must name the version being released.
# shellcheck disable=SC2016  # the pattern matches a literal ${LOOPER_VERSION:-…}
pinned=$(git show "$commit:quickstart.sh" | sed -n 's/^LOOPER_VERSION="\${LOOPER_VERSION:-\(v[0-9.]*\)}"$/\1/p')
[[ "$pinned" == "$version" ]] || die "quickstart.sh defaults to ${pinned:-nothing}, not $version"
git show "$commit:CHANGELOG.md" | grep -q "^## \[${version#v}\] - " \
    || die "CHANGELOG.md has no '## [${version#v}] - DATE' heading"

if command -v sha256sum >/dev/null 2>&1; then
    sum() { sha256sum "$@"; }
elif command -v shasum >/dev/null 2>&1; then
    sum() { shasum -a 256 "$@"; }
else
    die 'need sha256sum or shasum'
fi

mkdir -p "$out"
tarball="looper-$version.tar.gz"
for asset in "$tarball" quickstart.sh SHA256SUMS; do
    [[ ! -e "$out/$asset" ]] || die "$out/$asset already exists"
done

git archive --format=tar.gz --prefix=looper/ -o "$out/$tarball" "$commit:skills/looper"
git show "$commit:quickstart.sh" > "$out/quickstart.sh"
(cd "$out" && sum "$tarball" quickstart.sh > SHA256SUMS)

printf 'Built %s from %s\n' "$version" "$commit"
cat "$out/SHA256SUMS"
