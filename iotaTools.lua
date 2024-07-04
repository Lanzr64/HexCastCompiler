require("hexMap")
--[[
    * this tools is read iota from focal_port to string
    * if specify argument "dec" will be decompilation iota to hex code
    * author : Lanzr
]]
local completion = require "cc.shell.completion"
local complete = completion.build(
    { completion.choice, { "toStr", "dec", "append" } },
    { completion.choice, { "overWrite" } }
)
shell.setCompletionFunction("iotaTools.lua", complete)

local cmd = arg[1]
local param = arg[2]
local dev = peripheral.find("focal_port")
local g_force_mode  =false

local function tipWriter(left,right)
    term.setTextColor(colors.orange)
    write(left)
    term.setTextColor(colors.yellow)
    print(":"..right)
    term.setTextColor(colors.white)
end
if cmd == nil then
    local programName = arg[0] or fs.getName(shell.getRunningProgram())
    print("Usage: " .. programName .. " <cmd> [Param]")
    print("cmd can be :")
    tipWriter("toStr", " get focal_port iota to string and save in \"data\" file")
    tipWriter("dec", " get focal_port iota and decompile code based on hexMap and store it in \"dec_out\" file ")
    tipWriter("append", " get focal_port iota and Generate mappings that are not included in the hexMap, store the results in a \"newHexMap\" file, and if append parameter \"overWrite\", the hexMap will be overwritten ")
    return
end

function table2str(t)
    local function serialize(tbl)
        local tmp = {}
        for k, v in pairs(tbl) do
            local k_type = type(k)
            local v_type = type(v)
            local key = (k_type == "string" and "[\"" .. k .. "\"]=") or (k_type == "number" and "")
            local value = (v_type == "table" and serialize(v)) or (v_type == "boolean" and tostring(v)) or (v_type == "string" and "\"" .. v .. "\"") or (v_type == "number" and v)
            tmp[#tmp + 1] = key and value and tostring(key) .. tostring(value) or nil
        end
        if table.maxn(tbl) == 0 then
            return "\n[\"\"] = {" .. table.concat(tmp, ",") .. "},"
        else
            return "[" .. table.concat(tmp, " ") .. "\n]"
        end
    end
    assert(type(t) == "table")
    return serialize(t)
end

local numMap = {
    ["w"] = (function (sum)
        return sum + 1
    end),
    ["a"] = (function (sum)
        return sum * 2
    end)
}
local function getPatternNum(str)
    str = string.gsub(str,"aqaa","")
    local sum = 0 
    for char in str:gmatch(".") do
        sum = numMap[char](sum)
    end
    return tostring(sum)
end
function decompilation()
    local indentation_level = 0
    anti_hexMap = {}
    for cmd, iota in pairs(hexMap) do
        anti_hexMap[iota["angles"]] = cmd
    end
    data = dev.readIota()
    f = io.open("dec_out","w")
    for index,iota  in pairs(data) do
        local str = ""
        local cmd = anti_hexMap[iota["angles"]]
        if cmd == "}" then
            indentation_level = indentation_level - 1
        end
        for i = 0, indentation_level, 1 do
            str = str.."    "
        end
        if cmd ~= nil then 
            str = str..cmd
        elseif string.match(iota["angles"],"^aqaa") ~= nil then
            str = str..getPatternNum(iota["angles"])
        else
            str = str..iota["angles"]
        end
        f.write(f,str.."\n")
        if cmd == "{" then
            indentation_level = indentation_level + 1
        end
    end
    f.close(f)
end

function append()
    local targetFile = "newHexMap"
    if g_force_mode then
        targetFile = "hexMap"
    end
    anti_hexMap = {}
    for cmd, iota in pairs(hexMap) do
        anti_hexMap[iota["angles"]] = cmd
    end
    
    f = io.open("hexMap", "r+")
    io.input(f)
    io.output(f)
    local hexMapFindLck =false
    local text = ""
    repeat  
        local ret = io.read() 
        if ret ~= nil then
            if not hexMapFindLck then
                local findHexMap = string.match(ret, "^[ ]*hexMap[ ]*=")
                if findHexMap ~= nil then
                    hexMapFindLck = true
                end
            else
                local findBracket = string.match(ret, "^[ ]*}[ ]*$")
                if findBracket then
                    break
                end
            end
            text = text..ret.."\n"
        end
    until ret == nil
    f.close(f)
    f = io.open(targetFile,"w")
    f.write(f,text)
    data = dev.readIota()
    for index,iota  in pairs(data) do
        local cmd = anti_hexMap[iota["angles"]]
        if cmd == nil then
            if string.match(iota["angles"],"^aqaa") == nil then
                local tmp = {}
                for k, v in pairs(iota) do
                    local k_type = type(k)
                    local v_type = type(v)
                    local key = (k_type == "string" and "[\"" .. k .. "\"]=") or (k_type == "number" and "")
                    local value = (v_type == "table" and serialize(v)) or (v_type == "boolean" and tostring(v)) or (v_type == "string" and "\"" .. v .. "\"") or (v_type == "number" and v)
                    tmp[#tmp + 1] = key and value and tostring(key) .. tostring(value) or nil
                end
                local str =  "    [\"\"] = {" .. table.concat(tmp, ",") .. "},"
                f.write(f,str.."\n")
            end
        end
    end
    f.write(f,"}")
    f.close(f)
end

local function getIotaMap()
    d = dev.readIota()
    str = table2str(d)
    f = io.open("data","w")
    f.write(f,str)
    f.close(f)
end

local toolsMap = {
    ["toStr"] = (function (cStr)
        getIotaMap()
    return true end),
    ["dec"] = (function (cStr)
        decompilation()
    return true end),
    ["append"] = (function (cStr)
        if(param ~=nil)then
            if(param == "overWrite")then
                g_force_mode = true
            end
        end
        append()
    return true end)
}
local function mainloop()
   toolsMap[cmd]()
end

mainloop()