#!/usr/bin/env bash
# check-qml.sh - static checks for the Quickshell tree.
#
# Every check here exists because that failure actually happened in this repo and
# nothing caught it until it was read by hand or noticed on screen:
#
#   syntax    a QML file that does not parse takes the whole shell down, and the
#             only symptom is a blank bar and a line in a log nobody reads.
#   tokens    Theme.<name> must exist. When the Catppuccin aliases were removed,
#             a stray Theme.surface0 would have been a runtime TypeError in
#             whichever binding evaluated first.
#   imports   a file using a component from components/ without importing that
#             directory is an unresolved type -- which also takes the whole shell
#             down, not just the one panel.
#   qmldir    a .qml that is not listed in its directory's qmldir is invisible to
#             the import system.
#   json      a malformed palette.json silently falls back to the shipped
#             defaults, so a typo in the palette looks like "the wallpaper script
#             did not run" rather than like an error.
#
# Usage: quickshell/scripts/check-qml.sh   (cd's to the tree root itself)
# Exits non-zero if any check fails.

set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1
root=$(pwd)
status=0

# ---- syntax ---------------------------------------------------------------
# qmlformat, not qmllint. qmlformat only parses; qmllint also resolves types, and
# it cannot resolve this tree's local components (Quickshell synthesises the
# qmldir files at load), so on Qt 6.4 it reports "not a type" for every file that
# uses HairBar -- 42 false failures out of 51. qmlformat answers the only
# question being asked here: does this file parse.
#
# Debian/Ubuntu put these in /usr/lib/qt6/bin, which is not on PATH.
fmt=""
if command -v qmlformat >/dev/null 2>&1; then
    fmt=$(command -v qmlformat)
elif [ -x /usr/lib/qt6/bin/qmlformat ]; then
    fmt=/usr/lib/qt6/bin/qmlformat
fi

mapfile -t qml_files < <(find . -name '*.qml' -not -path './.git/*' | sort)

if [ -n "$fmt" ]; then
    failures=0
    for f in "${qml_files[@]}"; do
        # stderr only: qmlformat writes the formatted file to stdout.
        if ! out=$("$fmt" "$f" 2>&1 >/dev/null); then
            printf 'FAIL  %s\n' "${f#./}"
            printf '%s\n' "$out" | sed 's/^/      /'
            failures=$((failures + 1))
        fi
    done
    if [ "$failures" -eq 0 ]; then
        echo "ok    syntax (${#qml_files[@]} files)"
    else
        echo "FAIL  syntax ($failures of ${#qml_files[@]} files)"
        status=1
    fi
else
    echo "skip  syntax (no qmlformat; install qt6-declarative-dev-tools)"
fi

# ---- tokens, imports, qmldir, json ----------------------------------------
python3 - "$root" <<'PY' || status=1
import json
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
failed = False


def report(name, problems):
    global failed
    if problems:
        failed = True
        print(f"FAIL  {name}")
        for p in problems:
            print(f"      {p}")
    else:
        print(f"ok    {name}")


def strip_comments(text):
    """Drop // comments, keeping URLs (the // after a colon) intact."""
    out = []
    for line in text.splitlines():
        i = line.find("//")
        while i != -1:
            if i > 0 and line[i - 1] == ":":
                i = line.find("//", i + 2)
                continue
            line = line[:i]
            break
        out.append(line)
    return "\n".join(out)


qml = sorted(p for p in root.rglob("*.qml") if ".git" not in p.parts)
sources = {p: strip_comments(p.read_text()) for p in qml}
theme_file = root / "theme" / "Theme.qml"

# Every Theme.<name> must be a property Theme actually declares. This is what
# makes removing the legacy aliases safe: a leftover reference now fails here
# rather than at load.
if theme_file in sources:
    declared = set(re.findall(r"(?:readonly\s+)?property\s+[A-Za-z_]+\s+(\w+)", sources[theme_file]))
    problems = []
    for path, text in sources.items():
        if path == theme_file:
            continue
        for m in re.finditer(r"\bTheme\.(\w+)", text):
            if m.group(1) not in declared:
                problems.append(f"{path.relative_to(root)}: Theme.{m.group(1)} is not a property of Theme")
    report("tokens", sorted(set(problems)))
else:
    report("tokens", [f"theme/Theme.qml not found under {root}"])

# A file that uses a component from components/ has to import that directory,
# by whatever relative path gets there.
components = (root / "components").resolve()
names = {p.stem for p in components.glob("*.qml")}
problems = []
for path, text in sources.items():
    if path.parent.resolve() == components:
        continue
    used = sorted(n for n in names if re.search(r"\b" + re.escape(n) + r"\s*\{", text))
    if not used:
        continue
    if not any((path.parent / imp).resolve() == components
               for imp in re.findall(r'^\s*import\s+"([^"]+)"', text, re.M)):
        problems.append(f"{path.relative_to(root)}: uses {', '.join(used)} without importing components/")
report("imports", problems)

# Every .qml in a directory that ships a qmldir has to be listed in it.
problems = []
for qmldir in sorted(root.rglob("qmldir")):
    if ".git" in qmldir.parts:
        continue
    listed = {line.split()[-1] for line in qmldir.read_text().splitlines()
              if line.split() and line.split()[-1].endswith(".qml")}
    for path in sorted(qmldir.parent.glob("*.qml")):
        if path.name not in listed:
            problems.append(f"{path.relative_to(root)}: missing from {qmldir.relative_to(root)}")
report("qmldir", problems)

# The palette and motion files are read at startup and their absence or damage
# is silent, so a parse error has to be caught before it ships.
problems = []
for path in sorted(root.rglob("*.json")):
    if ".git" in path.parts:
        continue
    try:
        json.loads(path.read_text())
    except Exception as exc:
        problems.append(f"{path.relative_to(root)}: {exc}")
report("json", problems)

sys.exit(1 if failed else 0)
PY

exit "$status"