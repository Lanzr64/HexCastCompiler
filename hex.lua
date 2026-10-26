--[[
    * a  mineCraft HexCasting Mod Compiler, can compile the hCode in game and output to the focus
    * need mod : cc_hex_plugin (server)
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

local inf = io.open(path,"r") 
local codeStr = inf.read(inf,"*all")
inf.close(inf)

local iotaBridge = require("iotaBridge")

local lastIndex = 0
local index = -1
local leftBrackIndex = nil
local hexList = {}
local currentHexlist = hexList 
local hexListStack = {}

local funcKey = nil
local funcMap = {}
local braceletSum = 0
local listBraceLetSum = 0




function appendHexlist(iota)
    table.insert(currentHexlist,iota)
end
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
    local start1, end1 = string.find(funcstr,"^[\t ]*@func[ ]+([%w_]+)[\t ]*%(([%w,_ \t]*)%)[\t ]*\r?\n")
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




function genPattern(angle)
    return {["startDir"]="East",["angles"]=angle}
end

function addEscape()
    p_esc = genPattern("qqqaw")
    appendHexlist(p_esc)
end

NumMap = {
    [0] = "aqaa",
    [1] = "aqaaw",
    [2] = "aqaawa",
    [3] = "aqaawaw",
    [4] = "aqaawaa",
    [5] = "aqaaq",
    [6] = "aqaaqw",
    [7] = "aqaawaq",
    [8] = "aqaawwaa",
    [9] = "aqaawaaq",
    [10] = "aqaaqa"
}

local regMap = {
    [genRegex("([{}>%*%+-=</])")] = (function (cStr)
        if cStr == "{" then
            braceletSum = braceletSum + 1
        elseif cStr == "}" then
            braceletSum = braceletSum - 1
        end
        appendHexlist(genPattern(hexMap[cStr]))
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
        local pt = genPattern(t)
        appendHexlist(pt)
    return true end),
    
    
    
}

function addOtherIota(cStr)
    local outIota = nil
    if cStr == "true" then outIota = true
    elseif cStr == "false" then outIota = false
    elseif cStr == "null" then outIota = {null = true}
    elseif cStr == "garbage" then outIota = {garbage = true}
    elseif cStr:match("^%b()$") then
        local x, y, z = cStr:match("^%(%s*([^,]+)%s*,%s*([^,]+)%s*,%s*([^,]+)%s*%)$")
        x, y, z = tonumber(x), tonumber(y), tonumber(z)
        if x and y and z then outIota = {x = x, y = y, z = z} end
    elseif cStr:match("^[%+%-%d%.eE]+$") then
        outIota = tonumber(cStr)
    end
    if outIota ~= nil then
        appendHexlist(outIota)
        return true
    end
    return false
end

function addNumPattern(num)
    local stackOpe = {}
    local len = 0
    local oper = 0
    local rem = num > 0 and num or -num
    if num < 0 then
        appendHexlist(genPattern(NumMap[0]))
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
        appendHexlist(genPattern(NumMap[stackOpe[i]]))
        if(i < len) then
            appendHexlist(genPattern(hexMap["+"]))
        end
        i = i - 1
        if i < 1 then
            break
        end
        appendHexlist(genPattern(NumMap[10]))
        appendHexlist(genPattern(hexMap["*"]))
    end
    if num < 0 then
        appendHexlist(genPattern(hexMap["-"]))
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
    appendHexlist(rmPattern)
end

function addRawIota(cStr)
    local t = rawMap[cStr]
    if t == nil then
        return false
    end
    appendHexlist(t)
    return true
end

function parseStr(str)
    local lastIndex = 0
    local index = -1
    local cut = ""
    local lineIndex = 0
    local funcstr = ""
    while ( index ~= nil ) do
        local syntaxFlag = true
        local escapeFlag = false
        lineIndex = lineIndex + 1
        index = string.find(str,"\n", index + 1);
        if( index ~= nil) then
            cut = string.sub(str,lastIndex+1, index-1)
        else
            cut = string.sub(str,lastIndex+1, index);
        end
        
        repeat
            lastIndex = index 
            local commentPos = string.find(cut,"#")
            if commentPos ~= nil then
                cut = string.sub(cut, 1,commentPos-1)
            end
            
            
            if (string.match(cut,genRegex(""))) then
                break
            end
            
            if (string.match(cut,genRegex("@.*"))) then
                if (string.match(cut,preMap["include"])) then
                    local cStr = string.match(cut,preMap["include"])
                    local inf = io.open(cStr,"r") 
                    local subStr = inf.read(inf,"*all")
                    inf.close(inf)
                    parseStr(subStr)
                    break
                end
                
                if (string.match(cut,preMap["func"])~= nil) then
                    funcstr = cut.."\n"
                    funcKey = true
                    break
                elseif(string.match(cut,preMap["end"])) then
                    funcKey = nil
                    funcstr = funcstr..cut.."\n"
                    parseFuncDefine(funcstr)
                    break
                end
                
                syntaxFlag = false
                break
            end
            
            if(funcKey ~= nil) then
                funcstr = funcstr..cut.."\n"
                break
            end
            
            if string.match(cut,genRegex("([%a_]+[%w_]*)%((.*)%)")) then
                retstr = funcInvoke(cut)
                parseStr(retstr)
                break
            end
            if string.match(cut, genRegex("%%%%%[")) then
                listBraceLetSum = listBraceLetSum + 1
                hexListStack[listBraceLetSum] = currentHexlist
                currentHexlist = {}
                break
            end
            if string.match(cut,genRegex("%%.*")) then
                local raw = cut:match("^%s*(.-)%s*$")
                local cStr
                if raw:sub(1, 2) == "%%" then
                    cStr = raw:sub(3)
                else
                    escapeFlag = true
                    cStr = raw:sub(2)
                end
                if cStr == "" then syntaxFlag = false; break end
                if escapeFlag then addEscape() end
                if cStr ~= "true" and cStr ~= "false" and cStr ~= "null"
                    and cStr ~= "garbage" and cStr:match("^[%a_][%w_]*$")
                    and rawMap[cStr] ~= nil then
                    syntaxFlag = addRawIota(cStr)
                else
                    syntaxFlag = addOtherIota(cStr)
                end
                break
            end
            if (string.match(cut,genRegex("%["))) then
                listBraceLetSum = listBraceLetSum + 1
                addEscape()
                hexListStack[listBraceLetSum] = currentHexlist
                currentHexlist = {}
                break
            elseif (string.match(cut,genRegex("%]"))) then
                listBraceLetSum = listBraceLetSum - 1
                if (listBraceLetSum < 0) then
                    print("Line : "..cut.." is open brace error")
                    return false
                end
                table.insert(hexListStack[listBraceLetSum+1], currentHexlist)
                currentHexlist = hexListStack[listBraceLetSum+1]
                break
            end
            
            for key, cb in pairs(regMap) do
                if (string.match(cut,key)~= nil) then
                    local cStr = string.match(cut,key)
                    syntaxFlag = cb(cStr)
                    break
                end   
            end
            if syntaxFlag then
                break
            end
            syntaxFlag = false
        until true
        if syntaxFlag ~= true then
            print("Line : "..cut.." is illegal syntax")
            return false
        end
    end
    return true

end

function mainloop()
    ret = parseStr(codeStr)
    if ret then
        if listBraceLetSum ~= 0 then
            print("not all braces are closed")
            return false
        end
        iotaBridge.writeIota(currentHexlist)
    end
end

mainloop()
