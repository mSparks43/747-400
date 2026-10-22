-- Run from the repository root with LuaJIT: luajit tests/static/interfaces_test.lua
-- The 3D cockpit, the panel instruments embedded in the acf files, the FMOD
-- sounds and AutoATC use the laminar/ datarefs and commands listed in
-- docs/overhaul/INTERFACES.tsv. A rebuild must keep every one of them
-- (CLAUDE.md). This checks that each listed dataref is still created by an
-- init script and each listed command is still created somewhere. Names the
-- code builds at run time (kind "dynamic") are not checked here.
local T = dofile("tests/lib/check.lua")("interfaces")
local src = dofile("tests/lib/source.lua")

-- Listed as datarefs but created only in an xt script, so they probably do not
-- exist at run time: an existing defect on 041c9ffa (the CHRONO switches of the
-- glareshield clocks). Remove an entry when its system is rebuilt.
local KNOWN = {
    ["laminar/B747/glareshiled/captain/chrono_switch_pos"] = true,
    ["laminar/B747/glareshiled/fo/chrono_switch_pos"] = true,
}

local drefs, cmds = src.created(src.lua_files())
local rows = 0
for line in io.lines("docs/overhaul/INTERFACES.tsv") do
    if line:sub(1, 1) ~= "#" and not line:find("^name\t") then
        local name, kind = line:match("^([^\t]+)\t([^\t]+)")
        if name then
            rows = rows + 1
            if kind == "dataref" then
                T.check(drefs[name] ~= nil or KNOWN[name], "dataref no longer created by an init script: " .. name)
            elseif kind == "command" then
                T.check(cmds[name] ~= nil, "command no longer created: " .. name)
            end
        end
    end
end
T.check(rows > 1500, "INTERFACES.tsv rows read (" .. rows .. ")")
T.done()
