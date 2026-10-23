-- List the laminar/ names an acf panel uses (DATAREF lines and SHOW_EQUAL /
-- SHOW_LESS / SHOW_GREATER conditions) that docs/overhaul/INTERFACES.tsv does
-- not list yet, as INTERFACES.tsv rows: kind "dataref" when an init script
-- creates the name literally, else "dynamic" (built at run time).
-- Run from the repository root after changing the custom acf's panel:
--   luajit tests/tools/panel_names.lua [acf]        (default 747-400_custom.acf)
-- and add the rows it prints to INTERFACES.tsv (sorted by name).
local src = dofile("tests/lib/source.lua")
local acf = arg and arg[1] or "747-400_custom.acf"

local listed = {}
for line in io.lines("docs/overhaul/INTERFACES.tsv") do
    local name = line:match("^([^\t#]+)\t")
    if name then listed[name] = true end
end

local used = {}
for line in io.lines(acf) do
    local name = line:match("^%s*DATAREF (laminar/[^%[%s]+)")
        or line:match("^%s*SHOW_%u+ %S+ (laminar/[^%[%s]+)")
    if name then used[name] = true end
end

local drefs = src.created(src.lua_files())
local function module_of(path)
    return path:match("([^/]+)%.lua$")
end
local names = {}
for name in pairs(used) do
    if not listed[name] then names[#names + 1] = name end
end
table.sort(names)
for _, name in ipairs(names) do
    if drefs[name] then
        print(string.format("%s\tdataref\tpanel\t%s", name, module_of(drefs[name])))
    else
        print(string.format("%s\tdynamic\tpanel\t", name))
    end
end
io.stderr:write(#names .. " name(s) not in INTERFACES.tsv\n")
