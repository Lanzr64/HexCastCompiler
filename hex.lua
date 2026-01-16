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


-- ---------------------------
-- patch
function findAndReplaceLiteral(source_string, target_substring, replacement_substring, num_replacements)
    local escaped_target = string.gsub(target_substring, "([%.%+%-%*%?%^%$%(%)%[%]%{}])", "%%%1")
    local new_string, count = string.gsub(
        source_string,
        escaped_target,
        function()
            return replacement_substring
        end,
        num_replacements
    )

    return new_string, count
end


function parseFuncDefine(funcstr)
    local start1, end1 = string.find(funcstr,"^[\t ]*@func[ ]+([%w_]+)[\t ]*%(([%w,_ \t]*)%)[\t ]*\n")
    local fundef = string.sub(funcstr,start1,end1-1)
    local start2 = string.find(funcstr,"[\t ]*@end[\t ]*")
    local funcbody = string.sub(funcstr,end1+1,start2-2)

    local funcname, params = string.match(fundef,genRegex("@func[ ]+([%w_]+)[\t ]*%(([%w,_ \t]*)%)"))
    local index = 0
    for s in params:gmatch("([^ ,\t]+)") do
        funcbody = findAndReplaceLiteral(funcbody,"$"..s,"$"..index)
        index = index + 1
    end
    funcMap[funcname]=funcbody
end

function funcInvoke(cut)
    local funcname, params_string = string.match(cut,genRegex("([%w_]+)[\t ]*%(([%w,_ %(%)\t]*)%)"))
    local index = 0
    local funcbody = funcMap[funcname]
    
    if params_string:match("^%s*$") then
        return funcbody
    end

    local balance = 0
    local start_index = 1 
    local args = {}
    for i = 1, #params_string do
        local char = params_string:sub(i, i) 

        if char == '(' then
            balance = balance + 1
        elseif char == ')' then
            balance = balance - 1
        elseif char == ',' and balance == 0 then
            local arg = params_string:sub(start_index, i - 1)
            arg = arg:match("^%s*(.-)%s*$")
            table.insert(args, arg)
            start_index = i + 1
        end
    end

    local last_arg = params_string:sub(start_index)
    last_arg = last_arg:match("^%s*(.-)%s*$")
    table.insert(args, last_arg)
    local index = 0
    for i, arg in ipairs(args) do
        index = i - 1
        if string.match(arg,genRegex("([%a_]+[%w_]*)%(([%w,_ \t]*)%)")) then
            local retstr = funcInvoke(arg)
            funcbody = findAndReplaceLiteral(funcbody,"$"..index, retstr)
        else
            funcbody = findAndReplaceLiteral(funcbody,"$"..index, arg)
        end
    end
 
    return funcbody    
end
-- ---------------------------

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
    -- [genRegex("([%a_]+[%w_]*)%(%)")] = (function (cStr)
    --     parseStr(funcMap[cStr])
    -- return true end)
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
    local funcstr = ""
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
            if (string.match(cut,genRegex("@func[ ]+([%w_]+[\t ]*%([%w,_ %(%)\t]*%))"))~= nil) then
                funcstr = cut.."\n"
                funcKey = true
                break
            elseif(string.match(cut,genRegex("@end"))) then
                funcKey = nil
                funcstr = funcstr..cut.."\n"
                parseFuncDefine(funcstr)
                break
            else
                if(funcKey ~= nil) then
                    funcstr = funcstr..cut.."\n"
                    break
                end
            end

            if string.match(cut,genRegex("([%a_]+[%w_]*)%((.*)%)")) then
                retstr = funcInvoke(cut)
                parseStr(retstr)
                break
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

end

function mainloop()
    parseStr(codeStr)
    if(fPort ~= nil) then
        fPort.writeIota(hexlist)
    end
end

mainloop()
 