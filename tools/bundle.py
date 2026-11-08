"""Copy the addons a program uses into it, for its release.

Usage: python3 tools/bundle.py <program folder> [addons repo folder]

Reads <program>/addons.lua (a list like {"neon-ui@1", "clock@1"}), adds what those addons require and core,
checks that this repo's versions fit ("neon-ui@1" takes any 1.x, "neon-ui@1.3" 1.3 or newer), and copies each
addon folder without its tests to <program>/addons/<name>/. Also writes setup.lua from the installer's bootstrap
when the program has program.lua. Exits with 1 and says why if something doesn't fit.
"""
import os
import re
import shutil
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from check_addons import read_addons, read_table, to_python  # noqa: E402

REQUIRE = re.compile(r"^([a-z][a-z0-9-]*)@(\d+)(?:\.(\d+))?$")


def fits(version, major, minor):
    parts = [int(x) for x in version.split(".")]
    return parts[0] == major and (minor is None or parts[1] >= minor)


def read_lua(path):
    result = read_table(open(path, encoding="utf-8").read(), os.path.basename(path))
    value, problem = result if isinstance(result, tuple) else (result, None)
    if value is None:
        raise SystemExit(f"{path}: {problem}")
    return to_python(value)


def resolve(wanted, addons):
    """Every addon needed, with the requirement that brought it in"""
    needed, queue = {}, list(wanted) + ["core@1"]
    while queue:
        requirement = queue.pop(0)
        match = REQUIRE.match(requirement)
        if not match:
            raise SystemExit(f'{requirement!r}: use "<name>@<major>" or "<name>@<major>.<minor>"')
        name, major, minor = match.group(1), int(match.group(2)), match.group(3)
        if name not in addons:
            raise SystemExit(f"{name} is not an addon in this repo")
        version = addons[name]["version"]
        if not fits(version, major, int(minor) if minor else None):
            raise SystemExit(f"{requirement} is wanted, but {name} is {version}")
        if name not in needed:
            needed[name] = version
            queue += addons[name].get("requires") or []
    return needed


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    program = os.path.abspath(sys.argv[1])
    repo = os.path.abspath(sys.argv[2]) if len(sys.argv) > 2 else os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    wanted = read_lua(os.path.join(program, "addons.lua"))
    addons = read_addons(repo)
    needed = resolve(wanted if isinstance(wanted, list) else [], addons)

    target = os.path.join(program, "addons")
    shutil.rmtree(target, ignore_errors=True)
    for name in sorted(needed):
        shutil.copytree(os.path.join(repo, "addons", name), os.path.join(target, name),
                        ignore=shutil.ignore_patterns("tests", "__pycache__"))
        print(f"{name} {needed[name]}")

    info_path = os.path.join(program, "program.lua")
    if os.path.isfile(info_path):
        info = read_lua(info_path)
        bootstrap = open(os.path.join(repo, "addons", "installer", "bootstrap.lua"), encoding="utf-8").read()
        setup = bootstrap.replace("{{repository}}", info["repository"]).replace("{{branch}}", info.get("branch", "main"))
        open(os.path.join(program, "setup.lua"), "w", encoding="utf-8").write(setup)
        print("setup.lua written")


if __name__ == "__main__":
    main()
