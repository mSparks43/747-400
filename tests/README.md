# Tests

The test setup is described in `docs/overhaul/TESTING.md` (in Japanese). In short:

| What | How (from the repository root, Git Bash) |
|---|---|
| Syntax check of every Lua file | `tests/syntax_check.sh` |
| Regression tests (LuaJIT, no X-Plane) | `tests/run.sh` (or `tests/run.sh static` for one group) |
| Check that a refactor kept a module's behaviour | `luajit tests/tools/same_behaviour.lua tests/tools/scenarios/<name>.lua [git revision]` |
| Flight test in X-Plane (Web API) | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/flight/run_scenario.ps1 -Scenario tests/flight/scenarios/<name>.json -Acf custom` (or `-Acf stock`) |
| One-off Web API call | `powershell -NoProfile -ExecutionPolicy Bypass -File tests/flight/xp.ps1 get <dataref>` (also `set`, `cmd`, `shot`, `find`) |

- LuaJIT: `C:\Users\gakug\tools\luajit\bin\luajit.exe` (override with `LUAJIT=...`).
- The flight tests need X-Plane 12.4+ running with the Web API enabled (Settings > Network, incoming traffic allowed) and FlyWithLua NG+ with `tests/flight/fwl/B747_flighttest.lua` copied to `X-Plane 12/Resources/plugins/FlyWithLua/Scripts/`.
- Flight-test output goes to `tests/flight/runs/` (not committed).
- Layout: `tests/lib/` shared helpers (`xtlua.lua` runs an XTLua module without X-Plane), `tests/static/` checks over the whole code base, `tests/<system>/` tests per system, `tests/tools/` tools and their inputs, `tests/flight/` the X-Plane kit.
