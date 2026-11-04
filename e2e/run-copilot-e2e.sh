#!/usr/bin/env bash
# End-to-end run of Looper through the GitHub Copilot CLI on a small throwaway project.
# The agent gets only the request; the outcome is then checked independently:
# the ledger verdict, the project's own tests, and hidden acceptance checks the
# agent never sees. Uses your GitHub Copilot subscription and takes several minutes.
#
# Usage: e2e/run-copilot-e2e.sh [WORK_DIR]
#   Install this checkout first (./quickstart.sh) so GitHub Copilot loads the skill under test.
set -euo pipefail

die() {
    printf 'e2e: %s\n' "$*" >&2
    exit 1
}

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
skill="$HOME/.copilot/skills/looper"
command -v copilot >/dev/null 2>&1 || die 'the GitHub Copilot CLI (copilot) is not on PATH'
for f in SKILL.md scripts/pass-ledger.sh scripts/test_pass_ledger.py templates/state.md; do
    cmp -s "$root/skills/looper/$f" "$skill/$f" || die "$skill/$f differs from this checkout; run ./quickstart.sh first"
done

work=${1:-$(mktemp -d "${TMPDIR:-/tmp}/looper-e2e.XXXXXX")}
mkdir -p "$work"
work=$(cd "$work" && pwd -P)   # Looper refuses state paths that contain symlinks.
project=$work/project
[[ ! -e "$project" ]] || die "$project already exists"
mkdir "$project"
cd "$project"
git init -q
printf '# slug\n\nA tiny URL-slug utility.\n' > README.md
git add README.md
git -c user.name=e2e -c user.email=e2e@example.com commit -qm 'Initial commit'

request='Create slug.py with slugify(text, max_length=None) and a test_slug.py that runs with "python3 -m unittest". Rules: lowercase; turn accented letters into plain ASCII (é becomes e) and drop other non-ASCII; turn every run of characters other than a-z and 0-9 into one hyphen; never start or end with a hyphen. When max_length is given, cut the result to at most max_length characters without leaving a trailing hyphen, and raise ValueError if max_length is less than 1. Running "python3 slug.py TEXT" prints the slug of TEXT. Use only the standard library.'
prompt="looper $request There is no one available to answer questions; make reasonable assumptions and record them."

printf 'e2e: project %s\n' "$project"
start=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
code=0
copilot -p "$prompt" \
    --add-dir "$skill" \
    --allow-all-tools \
    --no-ask-user \
    --no-custom-instructions \
    --autopilot --max-autopilot-continues 40 \
    --share "$work/transcript.md" > "$work/copilot.log" 2>&1 || code=$?
finish=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
printf 'e2e: GitHub Copilot CLI exited %s\n' "$code"

ledger() { bash "$skill/scripts/pass-ledger.sh" "$@"; }
status=0
verdict=$(ledger "$project/.ralph-loop" verdict 2>&1) || status=1
printf 'verdict: %s\n' "$verdict"
printf 'ledger: %s\n' "$(ledger "$project/.ralph-loop" status 2>&1 || :)"
ledger "$project" loops || status=1
printf 'recorded runs: %s\n' "$(find "$project/.ralph-loop/passes" -path '*/runs/*/exit' 2>/dev/null | wc -l | tr -d ' ')"

if (cd "$project" && python3 -B -m unittest -q) > "$work/project-tests.log" 2>&1; then
    echo 'project tests: passed'
else
    echo 'project tests: FAILED'
    status=1
fi

# Hidden acceptance checks, written only after the agent has finished.
if python3 -B - "$project" > "$work/hidden-checks.log" 2>&1 <<'PY'
import subprocess, sys
sys.path.insert(0, sys.argv[1])
from slug import slugify
cases = [
    (("Hello World",), {}, "hello-world"),
    (("  Héllo, Wörld!! ",), {}, "hello-world"),
    (("",), {}, ""),
    (("---",), {}, ""),
    (("日本 rocks",), {}, "rocks"),
    (("a b c",), {"max_length": 3}, "a-b"),
    (("abc def",), {"max_length": 4}, "abc"),
    (("abc",), {"max_length": 10}, "abc"),
]
for args, kwargs, want in cases:
    got = slugify(*args, **kwargs)
    assert got == want, f"slugify{args}{kwargs} = {got!r}, want {want!r}"
for bad in (0, -1):
    try:
        slugify("abc", max_length=bad)
    except ValueError:
        pass
    else:
        raise AssertionError(f"max_length={bad} did not raise ValueError")
out = subprocess.run([sys.executable, "slug.py", "Crème Brûlée!"], cwd=sys.argv[1],
                     capture_output=True, text=True, check=True).stdout.strip()
assert out == "creme-brulee", f"CLI printed {out!r}"
print(f"{len(cases) + 3} hidden checks passed")
PY
then
    printf 'hidden checks: %s\n' "$(tail -1 "$work/hidden-checks.log")"
else
    echo 'hidden checks: FAILED'
    cat "$work/hidden-checks.log"
    status=1
fi

printf 'started %s, finished %s; transcript %s\n' "$start" "$finish" "$work/transcript.md"
if [[ "$status" -eq 0 ]]; then echo 'e2e: PASSED'; else echo 'e2e: FAILED'; fi
exit "$status"
