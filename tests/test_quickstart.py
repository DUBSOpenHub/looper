#!/usr/bin/env python3
"""Installer and release-build tests. Standard library only; no network access."""

import hashlib
import io
import os
import pathlib
import re
import shutil
import subprocess
import tarfile
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parent.parent
SKILL = ROOT / "skills" / "looper"
FILES = ["SKILL.md", "scripts/pass-ledger.sh", "scripts/test_pass_ledger.py", "templates/state.md"]
VERSION = re.search(
    r'^LOOPER_VERSION="\$\{LOOPER_VERSION:-(v[0-9.]+)\}"$',
    (ROOT / "quickstart.sh").read_text(encoding="utf-8"),
    re.M,
).group(1)
TARBALL = f"looper-{VERSION}.tar.gz"


def sha256(path):
    return hashlib.sha256(pathlib.Path(path).read_bytes()).hexdigest()


class InstallerTest(unittest.TestCase):
    def setUp(self):
        self.tmp = pathlib.Path(tempfile.mkdtemp(prefix="looper-installer-"))
        self.addCleanup(shutil.rmtree, self.tmp, True)
        self.home = self.tmp / "home"
        self.home.mkdir()
        self.dist = self.tmp / "dist"
        self.dist.mkdir()
        # A copy away from the checkout forces the release-download path.
        self.installer = self.tmp / "piped" / "quickstart.sh"
        self.installer.parent.mkdir()
        shutil.copy2(ROOT / "quickstart.sh", self.installer)
        self.installed = self.home / ".copilot" / "skills" / "looper"

    def publish(self, extra=None):
        """Write a release tarball of the working-tree skill plus SHA256SUMS."""
        with tarfile.open(self.dist / TARBALL, "w:gz") as tar:
            for name in FILES:
                tar.add(SKILL / name, arcname=f"looper/{name}")
            for member, data in extra or []:
                tar.addfile(member, io.BytesIO(data) if data is not None else None)
        self.write_sums()

    def write_sums(self):
        (self.dist / "SHA256SUMS").write_text(f"{sha256(self.dist / TARBALL)}  {TARBALL}\n", encoding="utf-8")

    def install(self, **env):
        full = {k: v for k, v in os.environ.items() if not k.startswith("LOOPER_")}
        full.update(HOME=str(self.home), LOOPER_RELEASE_URL=self.dist.as_uri())
        full.update(env)
        return subprocess.run(
            ["bash", str(self.installer)], env=full, capture_output=True, text=True, timeout=60
        )

    def assert_refused(self, result, message):
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn(message, result.stderr)
        self.assertFalse(self.installed.exists(), "a refused install must not write the skill")

    def test_installs_only_the_verified_skill_files(self):
        self.publish()
        result = self.install()
        self.assertEqual(result.returncode, 0, result.stderr)
        for name in FILES:
            self.assertEqual((self.installed / name).read_bytes(), (SKILL / name).read_bytes(), name)
        self.assertTrue(os.access(self.installed / "scripts/pass-ledger.sh", os.X_OK))

    def test_tampered_tarball_is_refused(self):
        self.publish()
        with open(self.dist / TARBALL, "ab") as handle:
            handle.write(b"tampered")
        self.assert_refused(self.install(), "Checksum mismatch")

    def test_missing_checksum_entry_is_refused(self):
        self.publish()
        (self.dist / "SHA256SUMS").write_text(f"{'0' * 64}  other.tar.gz\n", encoding="utf-8")
        self.assert_refused(self.install(), "no single valid entry")

    def test_sha256_pin_must_match(self):
        self.publish()
        self.assert_refused(self.install(LOOPER_SHA256="f" * 64), "does not match LOOPER_SHA256")
        good = self.install(LOOPER_SHA256=sha256(self.dist / TARBALL).upper())
        self.assertEqual(good.returncode, 0, good.stderr)

    def test_path_traversal_entry_is_refused(self):
        member = tarfile.TarInfo("looper/../escaped")
        member.size = 4
        self.publish([(member, b"evil")])
        self.assert_refused(self.install(), "Unexpected path")
        self.assertFalse((self.tmp / "escaped").exists())

    def test_symlink_entry_is_refused(self):
        member = tarfile.TarInfo("looper/link")
        member.type = tarfile.SYMTYPE
        member.linkname = "/etc/passwd"
        self.publish([(member, None)])
        self.assert_refused(self.install(), "contains links")

    def test_branch_names_and_malformed_versions_are_refused(self):
        self.publish()
        for version in ["main", "v1.1", "v1.1.0;rm", "latest"]:
            with self.subTest(version=version):
                self.assert_refused(self.install(LOOPER_VERSION=version), "must be a release tag")

    def test_release_build_round_trip(self):
        repo = self.tmp / "repo"
        shutil.copytree(SKILL, repo / "skills" / "looper", ignore=shutil.ignore_patterns(
            "__pycache__", ".ledger-selftest-*"))
        for name in ["quickstart.sh", "CHANGELOG.md"]:
            shutil.copy2(ROOT / name, repo / name)
        git = ["git", "-C", str(repo), "-c", "user.name=test", "-c", "user.email=test@example.com"]
        subprocess.run(["git", "init", "-q", str(repo)], check=True)
        subprocess.run(git + ["add", "-A"], check=True)
        subprocess.run(git + ["commit", "-qm", "release"], check=True)
        build = ["bash", str(ROOT / "tools" / "build-release.sh")]

        wrong = subprocess.run(build + ["v0.0.1", str(self.tmp / "wrong")], cwd=repo,
                               capture_output=True, text=True, timeout=60)
        self.assertNotEqual(wrong.returncode, 0)
        self.assertIn("quickstart.sh defaults to", wrong.stderr)

        built = subprocess.run(build + [VERSION, str(self.dist)], cwd=repo,
                               capture_output=True, text=True, timeout=60)
        self.assertEqual(built.returncode, 0, built.stderr)
        self.assertEqual(sorted(p.name for p in self.dist.iterdir()), sorted([TARBALL, "SHA256SUMS", "quickstart.sh"]))
        self.assertEqual((self.dist / "quickstart.sh").read_bytes(), (ROOT / "quickstart.sh").read_bytes())
        with tarfile.open(self.dist / TARBALL) as tar:
            names = {m.name.rstrip("/") for m in tar.getmembers() if m.isfile()}
        self.assertEqual(names, {f"looper/{name}" for name in FILES})

        again = subprocess.run(build + [VERSION, str(self.dist)], cwd=repo,
                               capture_output=True, text=True, timeout=60)
        self.assertNotEqual(again.returncode, 0, "existing assets must not be overwritten")

        result = self.install()
        self.assertEqual(result.returncode, 0, result.stderr)
        for name in FILES:
            self.assertEqual((self.installed / name).read_bytes(), (SKILL / name).read_bytes(), name)


if __name__ == "__main__":
    unittest.main()
