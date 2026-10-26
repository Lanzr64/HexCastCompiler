-- Render a Hex Casting list Iota as source accepted by hex.lua.
local decompiler = {}

local function isPattern(value)
    return type(value) == "table" and type(value.angles) == "string"
        and type(value.startDir) == "string"
end

local function isEscape(value)
    return isPattern(value) and value.angles == "qqqaw"
        and value.startDir:upper() == "EAST"
end

local function isList(value)
    if type(value) ~= "table" or isPattern(value) or value.x ~= nil
        or value.y ~= nil or value.z ~= nil or value.null or value.garbage then
        return false
    end
    local count = #value
    for key in pairs(value) do
        if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > count then
            return false
        end
    end
    return true
end

local function same(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for key, value in pairs(a) do
        if not same(value, b[key]) then return false end
    end
    for key in pairs(b) do
        if a[key] == nil then return false end
    end
    return true
end

local function rawName(value, rawMap)
    local names = {}
    for name, mapped in pairs(rawMap) do
        if type(name) == "string" and name ~= "true" and name ~= "false"
            and name ~= "null" and name ~= "garbage"
            and name:match("^[%a_][%w_]*$")
            and same(value, mapped) then names[#names + 1] = name end
    end
    table.sort(names)
    return names[1]
end

local function numberText(value)
    if type(value) ~= "number" or value ~= value
        or value == math.huge or value == -math.huge then
        error("cannot decompile a non-finite number Iota")
    end
    return string.format("%.17g", value)
end

local numMap = {
    q = function(sum) return sum + 5 end,
    e = function(sum) return sum + 10 end,
    d = function(sum) return sum / 2 end,
    w = function(sum) return sum + 1 end,
    a = function(sum) return sum * 2 end,
}

local function patternText(value, names, rawMap)
    local alias = rawName(value, rawMap)
    if value.startDir:upper() ~= "EAST" then
        if alias then return alias, true end
        error("pattern with startDir " .. value.startDir
            .. " needs a rawMap alias before decompilation")
    end
    local command = names[value.angles]
    if command then return command, false end
    if value.angles:match("^aqaa[qedaw]*$") then
        local sum = 0
        for char in value.angles:sub(5):gmatch(".") do
            sum = numMap[char](sum)
        end
        return numberText(sum), false
    end
    if not value.angles:match("^[qedaws]*$") then
        error("invalid pattern angles")
    end
    return value.angles, false
end

local function rawText(value, rawMap)
    if type(value) == "number" then return numberText(value) end
    if type(value) == "boolean" then return tostring(value) end
    if type(value) == "table" then
        if value.x ~= nil or value.y ~= nil or value.z ~= nil then
            return "(" .. numberText(value.x) .. "," .. numberText(value.y)
                .. "," .. numberText(value.z) .. ")"
        end
        if value.null then return "null" end
        if value.garbage then return "garbage" end
    end
    local alias = rawName(value, rawMap)
    if alias then return alias end
    error("Iota needs a rawMap alias before decompilation")
end

function decompiler.render(data, hexMap, rawMap)
    if not isList(data) then error("dec expects a list Iota") end
    local names = {}
    local commands = {}
    for command, angles in pairs(hexMap) do commands[#commands + 1] = command end
    table.sort(commands)
    for _, command in ipairs(commands) do
        local angles = hexMap[command]
        if names[angles] == nil then names[angles] = command end
    end

    local lines, indent = {}, 0
    local function emit(line)
        if line == "}" then indent = math.max(0, indent - 1) end
        lines[#lines + 1] = string.rep("    ", indent) .. line
        if line == "{" then indent = indent + 1 end
    end
    local function renderList(list, depth)
        if depth > 16 then error("Iota list is too deep") end
        local index = 1
        while index <= #list do
            local value = list[index]
            local nextValue = list[index + 1]
            local escaped = isEscape(value) and nextValue ~= nil
                and (not isPattern(nextValue)
                    or (nextValue.startDir:upper() ~= "EAST"
                        and rawName(nextValue, rawMap) ~= nil))
            if escaped then
                index = index + 1
                value = list[index]
            end
            if isList(value) then
                emit(escaped and "[" or "%%[")
                indent = indent + 1
                renderList(value, depth + 1)
                indent = indent - 1
                emit("]")
            elseif isPattern(value) then
                local literal, raw = patternText(value, names, rawMap)
                emit(raw and (escaped and "%" or "%%") .. literal or literal)
            else
                emit((escaped and "%" or "%%") .. rawText(value, rawMap))
            end
            index = index + 1
        end
    end
    renderList(data, 0)
    return table.concat(lines, "\n") .. (#lines > 0 and "\n" or "")
end

return decompiler
