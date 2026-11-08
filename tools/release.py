"""Release every addon whose version has no release yet.

For an addon "clock" at version 1.2.0 the release is tagged clock-v1.2.0 and carries clock-1.2.0.tar
(the folder addons/clock/ without its tests). Runs in GitHub Actions after the checks and tests pass;
needs the gh CLI with a token that may write releases.

Usage:
  python3 tools/release.py           create the missing releases
  python3 tools/release.py --dry-run only list them
"""
import os
import re
import subprocess
import sys
import tarfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from check_addons import read_addons  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def has_release(tag):
    return subprocess.run(["gh", "release", "view", tag], capture_output=True).returncode == 0


def changelog_line(name, version):
    """The README changelog entry of this version, for the release notes"""
    readme = os.path.join(REPO, "addons", name, "README.md")
    for line in open(readme, encoding="utf-8"):
        if line.startswith(f"- {version} "):
            return line[2:].strip()
    return f"{version}"


def build_archive(name, version, out_dir):
    path = os.path.join(out_dir, f"{name}-{version}.tar")
    folder = os.path.join(REPO, "addons", name)

    def keep(info):
        parts = info.name.split("/")
        if "tests" in parts[2:3] or "__pycache__" in parts:
            return None
        return info

    with tarfile.open(path, "w") as archive:
        archive.add(folder, arcname=f"addons/{name}", filter=keep)
    return path


def main():
    dry_run = "--dry-run" in sys.argv
    out_dir = os.path.join(REPO, "build")
    os.makedirs(out_dir, exist_ok=True)
    sha = os.environ.get("GITHUB_SHA")
    made = 0

    for name, info in sorted(read_addons(REPO).items()):
        version = str(info.get("version", ""))
        if not re.match(r"^\d+\.\d+\.\d+$", version):
            continue
        tag = f"{name}-v{version}"
        if not dry_run and has_release(tag):
            continue
        if dry_run:
            print(f"would release {tag}")
            continue
        archive = build_archive(name, version, out_dir)
        command = ["gh", "release", "create", tag, archive, "--title", f"{name} {version}",
                   "--notes", f"{info.get('description', '')}\n\n{changelog_line(name, version)}", "--latest=false"]
        if sha:
            command += ["--target", sha]
        subprocess.run(command, check=True)
        print(f"released {tag}")
        made += 1

    if not dry_run:
        print(f"{made} new releases")


if __name__ == "__main__":
    main()
