-- Convert the compiler's Lua Iota values to Hex Casting's serialized Iota SNBT.
-- The global hexIota API is supplied by the cc_hex_plugin server mod.
local config = require("hccConfig")
local bridge = {}

local dirs = {
    NORTH_EAST = 0, EAST = 1, SOUTH_EAST = 2,
    SOUTH_WEST = 3, WEST = 4, NORTH_WEST = 5,
}
local dirNames = {
    "NORTH_EAST", "EAST", "SOUTH_EAST", "SOUTH_WEST", "WEST", "NORTH_WEST",
}
local angles = { w = 0, e = 1, d = 2, s = 3, a = 4, q = 5 }
local angleNames = { "w", "e", "d", "s", "a", "q" }

local function target()
    if type(config.inventoryName) ~= "string" or config.inventoryName == "" then
        error("hccConfig.inventoryName must be a peripheral name", 2)
    end
    if type(config.slot) ~= "number" or config.slot % 1 ~= 0 or config.slot < 1 then
        error("hccConfig.slot must be a positive integer", 2)
    end
    if type(hexIota) ~= "table" then
        error("hexIota API unavailable; install cc_hex_plugin on the server", 2)
    end
    return config.inventoryName, config.slot
end

function bridge.isAvailable()
    if type(hexIota) ~= "table" or type(config.inventoryName) ~= "string"
        or type(config.slot) ~= "number" then return false end
    local ok, holder = pcall(hexIota.isIotaHolder, config.inventoryName, config.slot)
    return ok and holder == true
end

local function numberTag(value)
    if type(value) ~= "number" or value ~= value
        or value == math.huge or value == -math.huge then
        error("Iota number must be finite", 2)
    end
    return string.format("%.17g", value) .. "d"
end

local function wrap(kind, data)
    return '{"hexcasting:type":"hexcasting:' .. kind
        .. '","hexcasting:data":' .. data .. '}'
end

local function encode(value, depth)
    if depth > 16 then error("Iota list is too deep", 2) end
    local t = type(value)
    if t == "number" then return wrap("double", numberTag(value)) end
    if t == "boolean" then return wrap("boolean", value and "1b" or "0b") end
    if t ~= "table" then error("unsupported Lua Iota: " .. t, 2) end

    if value.startDir ~= nil or value.angles ~= nil then
        local dir = dirs[string.upper(value.startDir or "")]
        if dir == nil or type(value.angles) ~= "string" then
            error("invalid pattern Iota", 2)
        end
        local bytes = {}
        for i = 1, #value.angles do
            local angle = angles[value.angles:sub(i, i)]
            if angle == nil then error("invalid pattern angle", 2) end
            bytes[#bytes + 1] = tostring(angle) .. "b"
        end
        return wrap("pattern", "{start_dir:" .. dir .. "b,angles:[B;"
            .. table.concat(bytes, ",") .. "]}")
    end
    if value.x ~= nil or value.y ~= nil or value.z ~= nil then
        return wrap("vec3", "{x:" .. numberTag(value.x) .. ",y:"
            .. numberTag(value.y) .. ",z:" .. numberTag(value.z) .. "}")
    end
    if value.null then return wrap("null", "{}") end
    if value.garbage then return wrap("garbage", "{}") end

    local count = #value
    for key in pairs(value) do
        if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > count then
            error("unsupported Iota table", 2)
        end
    end
    local parts = {}
    for i = 1, count do parts[i] = encode(value[i], depth + 1) end
    return wrap("list", "[" .. table.concat(parts, ",") .. "]")
end

-- Split an NBT compound or list without splitting nested values or quoted keys.
local function splitTopLevel(contents)
    local parts, start, nesting, quote, escaped = {}, 1, 0, nil, false
    for i = 1, #contents do
        local ch = contents:sub(i, i)
        if quote then
            if escaped then escaped = false
            elseif ch == "\\" then escaped = true
            elseif ch == quote then quote = nil end
        elseif ch == '"' or ch == "'" then quote = ch
        elseif ch == "{" or ch == "[" then nesting = nesting + 1
        elseif ch == "}" or ch == "]" then nesting = nesting - 1
        elseif ch == "," and nesting == 0 then
            parts[#parts + 1] = contents:sub(start, i - 1)
            start = i + 1
        end
        if nesting < 0 then error("invalid Iota SNBT", 2) end
    end
    if quote or nesting ~= 0 then error("invalid Iota SNBT", 2) end
    if start <= #contents then parts[#parts + 1] = contents:sub(start) end
    return parts
end

local function trim(value)
    return value:match("^%s*(.-)%s*$")
end

local function fields(compound)
    if compound:sub(1, 1) ~= "{" or compound:sub(-1) ~= "}" then
        error("expected an Iota compound", 2)
    end
    local result = {}
    for _, part in ipairs(splitTopLevel(compound:sub(2, -2))) do
        local quote, escaped, colon = nil, false, nil
        for i = 1, #part do
            local ch = part:sub(i, i)
            if quote then
                if escaped then escaped = false
                elseif ch == "\\" then escaped = true
                elseif ch == quote then quote = nil end
            elseif ch == '"' or ch == "'" then quote = ch
            elseif ch == ":" then colon = i; break end
        end
        if not colon then error("invalid Iota compound field", 2) end
        local key = trim(part:sub(1, colon - 1))
        if key:sub(1, 1) == '"' or key:sub(1, 1) == "'" then
            key = key:sub(2, -2)
        end
        result[key] = trim(part:sub(colon + 1))
    end
    return result
end

local function byteValue(raw)
    local number = raw and tonumber(raw:match("^(%-?%d+)[bB]$"))
    if number == nil then error("invalid Iota byte", 2) end
    return number
end

local function decode(snbt, depth)
    if depth > 16 then error("Iota list is too deep", 2) end
    local outer = fields(snbt)
    local kind = outer["hexcasting:type"]
    local data = outer["hexcasting:data"]
    if not kind or not data then error("invalid Iota SNBT", 2) end
    kind = kind:match('^["\']hexcasting:([%w_]+)["\']$')
    if kind == "double" then
        local number = tonumber(data:match("^(.-)[dD]$"))
        if number == nil then error("invalid number Iota", 2) end
        return number
    elseif kind == "boolean" then
        return byteValue(data) ~= 0
    elseif kind == "null" then
        return { null = true }
    elseif kind == "garbage" then
        return { garbage = true }
    elseif kind == "vec3" then
        local xyz = fields(data)
        local x = tonumber((xyz.x or ""):match("^(.-)[dD]$"))
        local y = tonumber((xyz.y or ""):match("^(.-)[dD]$"))
        local z = tonumber((xyz.z or ""):match("^(.-)[dD]$"))
        if not x or not y or not z then error("invalid vector Iota", 2) end
        return { x = x, y = y, z = z }
    elseif kind == "pattern" then
        local pat = fields(data)
        local dir = dirNames[byteValue(pat.start_dir) + 1]
        if not dir or not pat.angles or not pat.angles:match("^%[B;.*%]$") then
            error("invalid pattern Iota", 2)
        end
        local seq = {}
        local body = pat.angles:sub(4, -2)
        for _, part in ipairs(splitTopLevel(body)) do
            local angle = angleNames[byteValue(trim(part)) + 1]
            if not angle then error("invalid pattern angle", 2) end
            seq[#seq + 1] = angle
        end
        return { startDir = dir, angles = table.concat(seq) }
    elseif kind == "list" then
        if data:sub(1, 1) ~= "[" or data:sub(-1) ~= "]" then
            error("invalid list Iota", 2)
        end
        local list = {}
        for _, part in ipairs(splitTopLevel(data:sub(2, -2))) do
            list[#list + 1] = decode(trim(part), depth + 1)
        end
        return list
    end
    error("unsupported Iota type: " .. tostring(kind), 2)
end

function bridge.readIota()
    local name, slot = target()
    local result, reason = hexIota.readIota(name, slot)
    if not result then error("readIota failed: " .. tostring(reason), 2) end
    return decode(result.snbt, 0)
end

function bridge.writeIota(value)
    local name, slot = target()
    local snbt = encode(value, 0)
    local ok, reason = hexIota.writeIota(name, slot, snbt)
    if not ok then error("writeIota failed: " .. tostring(reason), 2) end
    return true
end

bridge.encode = function(value) return encode(value, 0) end
bridge.decode = function(snbt) return decode(snbt, 0) end
return bridge
