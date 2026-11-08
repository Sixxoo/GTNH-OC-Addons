"""Run the Lua tests in a fake OpenOS, and save screen snapshots as pictures.

Usage:
  python3 testkit/run.py                      every addons/*/tests/*_test.lua and testkit/tests/*_test.lua
  python3 testkit/run.py <file or folder>...  only these
  python3 testkit/run.py --root <program>     tests of a program that uses addons from this repo

Each test file runs in a fresh Lua 5.3 (like OpenComputers), with require finding addons as
require("addons.<name>"), the fake OpenOS as require("testkit.oc") and helpers as require("testkit.test").
Snapshots go to testkit/out/ as PNG files. Exits with 1 if a test fails.
Needs: pip install lupa pillow
"""
import argparse
import glob
import os
import re
import sys

from lupa import lua53

KIT = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(KIT)
OUT = os.path.join(KIT, "out")


def find_tests(root, paths):
    if not paths:
        paths = [os.path.join(root, "addons"), os.path.join(root, "tests"), os.path.join(KIT, "tests")]
    files = []
    for path in paths:
        if os.path.isdir(path):
            files += glob.glob(os.path.join(path, "**", "*_test.lua"), recursive=True)
        elif os.path.isfile(path):
            files.append(path)
    return sorted(set(os.path.abspath(file) for file in files))


def run_file(path, root):
    # Relative paths in a program (config.lua, logs.log) are relative to its folder, like in OC after cd
    os.chdir(root)
    lua = lua53.LuaRuntime(unpack_returned_tuples=True)
    search = ";".join([
        f"{root}/?.lua", f"{root}/?/init.lua",
        f"{REPO}/?.lua", f"{REPO}/?/init.lua",
    ])
    lua.execute(f'package.path = "{search};" .. package.path')
    runner = lua.eval("""
    function(source, name)
      local chunk, problem = load(source, "=" .. name)
      if chunk == nil then return nil, problem end
      local ok, result = xpcall(chunk, debug.traceback)
      if not ok then return nil, result end
      return result
    end
    """)
    result = runner(open(path, encoding="utf-8").read(), os.path.relpath(path, root))
    value, problem = result if isinstance(result, tuple) else (result, None)
    if value is None:
        return 0, [("(file)", str(problem))], {}
    failed = [(item["name"], item["message"]) for item in value["failed"].values()]
    snapshots = {name: [lines[i] for i in range(1, len(lines) + 1)] for name, lines in value["snapshots"].items()}
    return int(value["passed"]), failed, snapshots


CODE = re.compile(r"(&&?)(0x[0-9A-Fa-f]+|[A-Za-z]+);")


def render(lines, path):
    """Draw coded lines like an OC screen: one cell = 10x20 pixels, box lines drawn as lines"""
    from PIL import Image, ImageDraw, ImageFont

    font_path = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
    font = ImageFont.truetype(font_path, 16) if os.path.exists(font_path) else ImageFont.load_default()
    cw, ch = 10, 20
    width = max(len(CODE.sub("", line)) for line in lines) if lines else 1
    image = Image.new("RGB", (width * cw, len(lines) * ch), (0, 0, 0))
    draw = ImageDraw.Draw(image)

    def rgb(value):
        return ((value >> 16) & 255, (value >> 8) & 255, value & 255)

    for y, line in enumerate(lines):
        fg, bg, x, i = 0xFFFFFF, 0, 0, 0
        while i < len(line):
            match = CODE.match(line, i)
            if match:
                value = int(match.group(2), 16)
                if match.group(1) == "&&":
                    bg = value
                else:
                    fg = value
                i = match.end()
                continue
            char = line[i]
            i += 1
            left, top = x * cw, y * ch
            draw.rectangle([left, top, left + cw - 1, top + ch - 1], fill=rgb(bg))
            if char in "─━│┃┌┐└┘├┤":
                cx, cy, t = left + cw // 2, top + ch // 2, 3 if char in "━┃" else 1
                if char in "─━":
                    draw.rectangle([left, cy - t // 2, left + cw - 1, cy + t // 2], fill=rgb(fg))
                if char in "│┃":
                    draw.rectangle([cx - t // 2, top, cx + t // 2, top + ch - 1], fill=rgb(fg))
                right_arm = char in "┌└├"
                left_arm = char in "┐┘┤"
                down_arm = char in "┌┐├┤"
                up_arm = char in "└┘├┤"
                if right_arm:
                    draw.rectangle([cx, cy, left + cw - 1, cy], fill=rgb(fg))
                if left_arm:
                    draw.rectangle([left, cy, cx, cy], fill=rgb(fg))
                if down_arm:
                    draw.rectangle([cx, cy, cx, top + ch - 1], fill=rgb(fg))
                if up_arm:
                    draw.rectangle([cx, top, cx, cy], fill=rgb(fg))
            elif char != " ":
                draw.text((left, top + 1), char, font=font, fill=rgb(fg))
            x += 1
    image.save(path)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("paths", nargs="*")
    parser.add_argument("--root", default=REPO, help="folder of the program or addon repo to test")
    args = parser.parse_args()
    root = os.path.abspath(args.root)

    files = find_tests(root, args.paths)
    total_passed, total_failed = 0, 0
    os.makedirs(OUT, exist_ok=True)

    for path in files:
        passed, failed, snapshots = run_file(path, root)
        total_passed += passed
        total_failed += len(failed)
        name = os.path.relpath(path, root)
        mark = "ok  " if not failed else "FAIL"
        print(f"{mark} {name}: {passed} passed, {len(failed)} failed")
        for test, message in failed:
            print(f"     - {test}: {message}")
        for snapshot, lines in snapshots.items():
            picture = os.path.join(OUT, re.sub(r"[^A-Za-z0-9_.-]+", "-", f"{name[:-4]}-{snapshot}") + ".png")
            render(lines, picture)
            print(f"     snapshot: {os.path.relpath(picture, REPO)}")

    print(f"{len(files)} files, {total_passed} passed, {total_failed} failed")
    sys.exit(1 if total_failed or not files else 0)


if __name__ == "__main__":
    main()
