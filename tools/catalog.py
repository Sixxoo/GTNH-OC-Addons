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


def read_groups(repo):
    """groups.lua: [{name, description, addons}]"""
    from check_addons import read_table, to_python
    path = os.path.join(repo, "groups.lua")
    result = read_table(open(path, encoding="utf-8").read(), "groups.lua")
    value = result[0] if isinstance(result, tuple) else result
    if value is None:
        raise SystemExit(f"groups.lua can't be read: {result[1] if isinstance(result, tuple) else ''}")
    return to_python(value)


def catalog(repo):
    addons = read_addons(repo)
    groups = read_groups(repo)
    placed = {name for group in groups for name in group.get("addons", [])}
    missing = sorted(set(addons) - placed)
    if missing:
        groups = groups + [{"name": "Other", "addons": missing}]

    parts = []
    for group in groups:
        names = [name for name in group.get("addons", []) if name in addons]
        if not names:
            continue
        title = f"### {group['name']}"
        if group.get("description"):
            title += f"\n\n{group['description']}."
        rows = ["| Addon | Version | What it does | Needs |", "|---|---|---|---|"]
        for name in names:
            info = addons[name]
            needs = []
            for need in info.get("requires") or []:
                other = need.split("@", 1)[0]
                version = addons.get(other, {}).get("version")
                needs.append(f"{other} {version}" if version else other)
            needs = ", ".join(needs) or "-"
            rows.append(f"| [{name}](addons/{name}) | {info.get('version', '?')} | {info.get('description', '')} | {needs} |")
        parts.append(title + "\n\n" + "\n".join(rows))
    return "\n\n".join(parts)


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
