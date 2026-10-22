#!/usr/bin/env bash
# Syntax-check every Lua file of the aircraft and of the tests with LuaJIT
# (luajit -bl compiles without running), including new files not yet
# committed. docs/overhaul/TESTING.md.
cd "$(dirname "$0")/.." || exit 2
LUAJIT="${LUAJIT:-/c/Users/gakug/tools/luajit/bin/luajit.exe}"
n=0
bad=0
while IFS= read -r f; do
    n=$((n + 1))
    if ! err=$("$LUAJIT" -bl "$f" 2>&1 >/dev/null); then
        bad=$((bad + 1))
        echo "FAIL $f: $(printf '%s\n' "$err" | head -n 1)"
    fi
done < <({ git ls-files --cached --others --exclude-standard 'plugins/*.lua'; find tests -name '*.lua'; } | sort -u)
echo "checked $n files, syntax errors: $bad"
[ "$bad" -eq 0 ]
