"""Write the addon catalog in README.md from every addon.lua.

Usage:
  python3 tools/catalog.py          update README.md
  python3 tools/catalog.py --check  exit 1 if README.md is out of date (runs on every push)
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from check_addons import read_addons  # noqa: E402

START = "<!-- catalog:start -->"
END = "<!-- catalog:end -->"


def catalog(repo):
    rows = ["| Addon | Version | What it does | Needs |", "|---|---|---|---|"]
    for name, info in sorted(read_addons(repo).items()):
        needs = ", ".join(info.get("requires") or []) or "-"
        rows.append(f"| [{name}](addons/{name}) | {info.get('version', '?')} | {info.get('description', '')} | {needs} |")
    return "\n".join(rows)


def updated_readme(repo):
    path = os.path.join(repo, "README.md")
    text = open(path, encoding="utf-8").read()
    if START not in text or END not in text:
        raise SystemExit(f"README.md needs the markers {START} and {END}")
    before, rest = text.split(START, 1)
    _, after = rest.split(END, 1)
    return path, text, f"{before}{START}\n{catalog(repo)}\n{END}{after}"


if __name__ == "__main__":
    repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    path, old, new = updated_readme(repo)
    if "--check" in sys.argv:
        if old != new:
            print("README.md catalog is out of date: run python3 tools/catalog.py")
            sys.exit(1)
        print("README.md catalog is up to date")
    else:
        open(path, "w", encoding="utf-8").write(new)
        print("README.md catalog written")
