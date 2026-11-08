"""Check every addon in addons/ against FORMAT.md.

Usage: python3 tools/check_addons.py [repo folder]
Exits with 1 and lists the problems if any addon breaks the format.
Needs lupa (pip install lupa) to read addon.lua and compile the Lua files with Lua 5.3, like OpenComputers.
"""
import os
import re
import sys

from lupa import lua53

NAME = re.compile(r"^[a-z][a-z0-9]*(-[a-z0-9]+)*$")
VERSION = re.compile(r"^(\d+)\.(\d+)\.(\d+)$")
REQUIRE = re.compile(r"^([a-z][a-z0-9-]*)@(\d+)(?:\.(\d+))?$")
FIELDS = {"name", "version", "description", "requires", "components", "settings"}
README_SECTIONS = ["## Usage", "## Settings", "## Components", "## Changelog"]

lua = lua53.LuaRuntime(unpack_returned_tuples=True)
read_table = lua.eval("""
function(text, name)
  local chunk, problem = load(text, "=" .. name, "t", {})
  if chunk == nil then return nil, problem end
  local ok, value = pcall(chunk)
  if not ok then return nil, tostring(value) end
  if type(value) ~= "table" then return nil, "does not return a table" end
  return value
end
""")
compile_lua = lua.eval("function(text, name) local _, problem = load(text, '=' .. name, 't') return problem end")


def to_python(value):
    """Lua table to dict or list"""
    if lua.eval("type")(value) != "table":
        return value
    items = {key: to_python(item) for key, item in value.items()}
    if items and all(isinstance(key, int) for key in items) and sorted(items) == list(range(1, len(items) + 1)):
        return [items[key] for key in sorted(items)]
    return items if items else []


def read_addon(folder):
    """addon.lua of one addon folder as a dict, or (None, problem)"""
    name = os.path.basename(folder.rstrip("/"))
    result = read_table(open(os.path.join(folder, "addon.lua"), encoding="utf-8").read(), f"addons/{name}/addon.lua")
    value, error = result if isinstance(result, tuple) else (result, None)
    if value is None:
        return None, error
    info = to_python(value)
    return (info if isinstance(info, dict) else {}), None


def read_addons(repo):
    """name -> addon.lua dict, for every addon folder (not starting with _) that has a readable addon.lua"""
    root = os.path.join(repo, "addons")
    infos = {}
    for name in sorted(os.listdir(root)):
        folder = os.path.join(root, name)
        if os.path.isdir(folder) and not name.startswith("_") and os.path.isfile(os.path.join(folder, "addon.lua")):
            info, _ = read_addon(folder)
            if info is not None:
                infos[name] = info
    return infos


def check(repo):
    problems = []
    root = os.path.join(repo, "addons")
    infos = {}

    for name in sorted(os.listdir(root)):
        folder = os.path.join(root, name)
        if not os.path.isdir(folder) or name.startswith("_"):
            continue

        def problem(text):
            problems.append(f"{name}: {text}")

        if not NAME.match(name):
            problem("folder name must be lowercase with dashes")
        for required in ("addon.lua", "init.lua", "README.md"):
            if not os.path.isfile(os.path.join(folder, required)):
                problem(f"missing {required}")

        # Every Lua file compiles
        for base, _, files in os.walk(folder):
            for file in files:
                if file.endswith(".lua"):
                    path = os.path.join(base, file)
                    error = compile_lua(open(path, encoding="utf-8").read(), os.path.relpath(path, repo))
                    if error:
                        problem(f"does not compile: {error}")

        path = os.path.join(folder, "addon.lua")
        if not os.path.isfile(path):
            continue
        info, error = read_addon(folder)
        if info is None:
            problem(f"addon.lua: {error}")
            continue
        infos[name] = info

        for key in info:
            if key not in FIELDS:
                problem(f"addon.lua: unknown field {key}")
        if info.get("name") != name:
            problem(f"addon.lua: name is {info.get('name')!r}, the folder is {name!r}")
        if not VERSION.match(str(info.get("version", ""))):
            problem("addon.lua: version must be MAJOR.MINOR.PATCH")
        description = info.get("description")
        if not isinstance(description, str) or not description.strip() or "\n" in description:
            problem("addon.lua: description must be one line")
        for field in ("requires", "components"):
            if not isinstance(info.get(field, []), list) or not all(isinstance(item, str) for item in info.get(field, [])):
                problem(f"addon.lua: {field} must be a list of strings")
        settings = info.get("settings", [])
        if isinstance(settings, dict):
            for key, setting in settings.items():
                if not isinstance(setting, dict) or "default" not in setting or not setting.get("description"):
                    problem(f"addon.lua: setting {key} needs a default and a description")
        elif settings != []:
            problem("addon.lua: settings must be a table of settings")

        readme_path = os.path.join(folder, "README.md")
        if os.path.isfile(readme_path):
            readme = open(readme_path, encoding="utf-8").read()
            missing = [section for section in README_SECTIONS if section not in readme]
            if missing:
                problem("README.md: missing " + ", ".join(missing))
            version = info.get("version")
            if version and f"- {version} " not in readme:
                problem(f"README.md: no changelog line for {version}")

    # requires point at existing addons and versions, without loops
    graph = {}
    for name, info in infos.items():
        graph[name] = []
        for requirement in info.get("requires", []) if isinstance(info.get("requires"), list) else []:
            match = REQUIRE.match(requirement)
            if not match:
                problems.append(f"{name}: requires {requirement!r}: use \"<name>@<major>\" or \"<name>@<major>.<minor>\"")
                continue
            other, major, minor = match.group(1), int(match.group(2)), match.group(3)
            if other not in infos:
                problems.append(f"{name}: requires {other}, which does not exist")
                continue
            version = VERSION.match(str(infos[other].get("version", "")))
            if version and (int(version.group(1)) != major or (minor is not None and int(version.group(2)) < int(minor))):
                problems.append(f"{name}: requires {requirement}, but {other} is {infos[other]['version']}")
            graph[name].append(other)

    def visit(name, path):
        if name in path:
            problems.append("loop between addons: " + " -> ".join(path[path.index(name):] + [name]))
            return
        for other in graph.get(name, []):
            visit(other, path + [name])

    for name in graph:
        visit(name, [])

    return sorted(set(problems)), infos


if __name__ == "__main__":
    repo = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    problems, infos = check(repo)
    for line in problems:
        print("problem:", line)
    print(f"{len(infos)} addons checked, {len(problems)} problems")
    sys.exit(1 if problems else 0)
