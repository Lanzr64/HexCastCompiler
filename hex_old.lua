--[[
    * a  mineCraft HexCasting Mod Compiler, can compile the hCode in game and output to the focus
    * need mod : Ducky peripheral
    * author : Lanzr
]]
require("hexMap")
local completion = require "cc.shell.completion"
local complete = completion.build(
    completion.file
)
shell.setCompletionFunction("hex.lua", complete)
local path = arg[1]
if(path == nil) then
    local programName = arg[0] or fs.getName(shell.getRunningProgram())
    print("Usage: " .. programName .. " <path>")
    return
end
if(fs.exists(path) == false) then
    print("file "..path.." is not exist!")
    return
end

local inf = io.open(path,"r") -- the source_code filename
local codeStr = inf.read(inf,"*all")
inf.close(inf)

local fPort = peripheral.find("focal_port")

local lastIndex = 0
local index = -1
local leftBrackIndex = nil

local hexlist = {} -- the final table use to output

local funcKey = nil
local funcMap = {}


NumMap = {
    [0] = {["startDir"]="SOUTH_EAST",["angles"]="aqaa"},
    [1] = {["startDir"]="SOUTH_EAST",["angles"]="aqaaw"},
    [2] = {["startDir"]="SOUTH_EAST",["angles"]="aqaawa"},
    [3] = {["startDir"]="SOUTH_EAST",["angles"]="aqaawaw"},
    [4] = {["startDir"]="SOUTH_EAST",["angles"]="aqaawaa"},
    [5] = {["startDir"]="SOUTH_EAST",["angles"]="aqaaq"},
    [6] = {["startDir"]="SOUTH_EAST",["angles"]="aqaaqw"},
    [7] = {["startDir"]="SOUTH_EAST",["angles"]="aqaawaq"},
    [8] = {["startDir"]="SOUTH_EAST",["angles"]="aqaawwaa"},
    [9] = {["startDir"]="SOUTH_EAST",["angles"]="aqaawaaq"},
    [10] = {["startDir"]="SOUTH_EAST",["angles"]="aqaaqa"}
}

local regMap = {
    [genRegex("([{}>%*%+-=</])")] = (function (cStr)
        table.insert(hexlist,hexMap[cStr])
    return true end),
    [genRegex("rm[ ]+(%d+)")] = (function (cStr)
        addRMPattern(cStr)
    return true end),
    [genRegex("(-?[%d]+)")] = (function (cStr)
        addNumPattern(tonumber(cStr))
    return true end),
    [genRegex("([%a_]+[%w_]*)")] = (function (cStr)
        local t = hexMap[cStr]
        if t == nil then
            return false
        end
        table.insert(hexlist,t)
    return true end),
    [genRegex("([%a_]+[%w_]*)%(%)")] = (function (cStr)
        parseStr(funcMap[cStr])
    return true end)
}

function addNumPattern(num)
    local stackOpe = {}
    local len = 0
    local oper = 0
    local rem = num > 0 and num or -num
    if num < 0 then
        table.insert(hexlist,NumMap[0])
    end
    repeat
        oper = rem % 10
        rem = (rem - oper) /10
        table.insert(stackOpe,oper)
        len = len + 1
    until  rem < 1  
    rem = 0
    i = len
    while true do
        table.insert(hexlist,NumMap[stackOpe[i]])
        if(i < len) then
            table.insert(hexlist,hexMap["+"])
        end
        i = i - 1
        if i < 1 then
            break
        end
        table.insert(hexlist,NumMap[10])
        table.insert(hexlist,hexMap["*"])
    end
    if num < 0 then
        table.insert(hexlist,hexMap["-"])
    end
end

function addRMPattern(rmPos)
    local rmPattern = {}
    local angleStr = ""
    local pos = tonumber(rmPos)
    rmPattern["startDir"] = "EAST"
    if (pos > 1) then
        for i=1,pos-1,1 do
            angleStr = angleStr.."w"
        end
        angleStr = angleStr.."ea"
    else
        angleStr = "a"
    end
    rmPattern["angles"] = angleStr
    table.insert(hexlist,rmPattern)
end
 
function parseStr(str)
    local lastIndex = 0
    local index = -1
    local cut = ""
    local lineIndex = 0
    while ( index ~= nil ) do
        local syntaxFlag = true;
        lineIndex = lineIndex + 1
        index = string.find(str,"\n", index + 1);
        if( index ~= nil) then
            cut = string.sub(str,lastIndex+1, index-1)
        else
            cut = string.sub(str,lastIndex+1, index);
        end
        -- comment check
        repeat
            lastIndex = index 
            local commentPos = string.find(cut,"#")
            if commentPos ~= nil then
                cut = string.sub(cut, 1,commentPos-1)
            end
            -- preExp regMap
            -- include check
            if (string.match(cut,preMap["include"])) then
                local cStr = string.match(cut,preMap["include"])
                local inf = io.open(cStr,"r") -- the source_code filename
                local subStr = inf.read(inf,"*all")
                inf.close(inf)
                parseStr(subStr)
                break
            end
            -- func check
            if (string.match(cut,genRegex("@func[ ]+([%w_]+)"))~= nil) then
                local cStr = string.match(cut,preMap["func"])
                funcMap[cStr] = ""
                funcKey = cStr
                break
            elseif(string.match(cut,genRegex("@end"))) then
                funcKey = nil
                break
            else
                if(funcKey ~= nil) then
                    funcMap[funcKey] = funcMap[funcKey]..cut.."\n"
                    break
                end
            end
            -- common regMap
            for key, cb in pairs(regMap) do
                if (string.match(cut,key)~= nil) then
                    local cStr = string.match(cut,key)
                    syntaxFlag = cb(cStr)
                    break
                end   
            end
        until true
        if syntaxFlag ~= true then
            print("Line "..lineIndex.." : "..cut.." is illegal syntax")
        end
    end

    -- out put final hexlist    
    if(fPort ~= nil) then
        fPort.writeIota(hexlist)
        return
    end
end

function mainloop()
    parseStr(codeStr)
end

mainloop()
 