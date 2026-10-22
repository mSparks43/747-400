-- Reading the aircraft's Lua sources for the static checks (tests/README.md).
local M = {}

function M.read(path)
    local file = assert(io.open(path, "rb"))
    local text = file:read("*a")
    file:close()
    return text
end

-- Every .lua file under plugins/, as forward-slash paths relative to the repository root.
function M.lua_files()
    local windows = package.config:sub(1, 1) == "\\"
    local command = windows and 'dir /s /b "plugins\\*.lua"' or 'find plugins -name "*.lua"'
    local pipe = assert(io.popen(command))
    local files = {}
    local cwd
    if windows then
        local p = assert(io.popen("cd"))
        cwd = p:read("*l"):gsub("\\", "/") .. "/"
        p:close()
    end
    for line in pipe:lines() do
        local path = line:gsub("\\", "/")
        if cwd and path:sub(1, #cwd):lower() == cwd:lower() then path = path:sub(#cwd + 1) end
        if not path:find("/json/", 1, true) then files[#files + 1] = path end
    end
    pipe:close()
    table.sort(files)
    return files
end

-- init scripts (create datarefs and commands) vs xt scripts (logic)
function M.is_init(path) return path:find("/init/scripts/", 1, true) ~= nil end
function M.is_xt(path) return path:find("/scripts/", 1, true) ~= nil and not M.is_init(path) end

-- Names created with a literal string: deferred_dataref/create_dataref and
-- deferred_command/create_command. Names built at run time are not seen.
function M.created(files)
    local drefs, cmds = {}, {}
    for _, path in ipairs(files) do
        local text = M.read(path)
        if M.is_init(path) then
            for name in text:gmatch('deferred_dataref%s*%(%s*"([^"]+)"') do drefs[name] = path end
            for name in text:gmatch('create_dataref%s*%(%s*"([^"]+)"') do drefs[name] = path end
        end
        for name in text:gmatch('deferred_command%s*%(%s*"([^"]+)"') do cmds[name] = path end
        for name in text:gmatch('create_command%s*%(%s*"([^"]+)"') do cmds[name] = path end
    end
    return drefs, cmds
end

return M
