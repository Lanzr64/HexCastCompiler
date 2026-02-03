--[[
    * a  mineCraft HexCasting Mod Compiler, can compile the hCode in game and output to the focus
    * need mod : Ducky peripheral
    * author : Lanzr
]]
require("hexMap")
require("json")
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
local braceletSum = 0


-- ---------------------------
-- patch
function appendHexlist(iota)
    table.insert(hexlist,iota)
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
-- ---------------------------

-- ---------------------------
-- patch
function genPattern(angle)
    return {["startDir"]="East",["angles"]=angle}
end

function addEscape()
    p_esc = genPattern("qqqaw")
    appendHexlist(p_esc)
end
-- ---------------------------

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
    -- [genRegex("([%a_]+[%w_]*)%(%)")] = (function (cStr)
    --     parseStr(funcMap[cStr])
    -- return true end)
}
-- 其他iota的处理都在这里
function addOtherIota(cStr, needEscape)
    local outIota = nil
   
    -- 数字
    if string.match(cStr,"^([%d.]+)$") then 
        local num = string.match(cStr,"([%d.]+)")
        outIota = tonumber(num)
    -- 矢量
    elseif string.match(cStr,"^%([\t ]*([%d]+)[\t ]*,[\t ]*([%d]+)[\t ]*,[\t ]*([%d]+)[\t ]*%)$") then
        local x,y,z = string.match(cStr,"%([\t ]*([%d]+)[\t ]*,[\t ]*([%d]+)[\t ]*,[\t ]*([%d]+)[\t ]*%)")
        outIota = {x = tonumber(x),y = tonumber(y),z = tonumber(z)}
    end 
    if outIota ~= nil then
        if needEscape and braceletSum > 0 then
            addEscape()
        end
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
        appendHexlist(genPattern(hexMap[0]))
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
            if (string.match(cut,genRegex(""))) then
                break
            end
            -- @ 预编译符号
            if (string.match(cut,genRegex("@.*"))) then
                if (string.match(cut,preMap["include"])) then
                    local cStr = string.match(cut,preMap["include"])
                    local inf = io.open(cStr,"r") -- the source_code filename
                    local subStr = inf.read(inf,"*all")
                    inf.close(inf)
                    parseStr(subStr)
                    break
                end
                -- func check
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
                -- not found anything
                syntaxFlag = false
                break
            end
            -- 添加函数体
            if(funcKey ~= nil) then
                funcstr = funcstr..cut.."\n"
                break
            end
            -- 函数调用
            if string.match(cut,genRegex("([%a_]+[%w_]*)%((.*)%)")) then
                retstr = funcInvoke(cut)
                parseStr(retstr)
                break
            end
            -- rawMap
            if (string.match(cut,genRegex("%%.*"))) then
                if string.match(cut,genRegex("%%[%a_]+[%w_]*")) then
                    local cStr = string.match(cut,genRegex("%%([%a_]+[%w_]*)"))
                    syntaxFlag = addRawIota(cStr)
                    break
                end
                syntaxFlag = false
                break
            end
            -- 非图案iota，此处不转义
            if (string.match(cut,genRegex("\\\\.*"))) then
                local cStr = string.match(cut,genRegex("\\\\(.*)"))
                syntaxFlag = addOtherIota(cStr,true)
                break
            -- 非图案iota 此处转义
            elseif (string.match(cut,genRegex("\\.*"))) then
                local cStr = string.match(cut,genRegex("\\(.*)"))
                syntaxFlag = addOtherIota(cStr,false)
                break
            end
            -- 普通的方法映射（无优先级）
            -- common regMap 
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
        if(fPort ~= nil) then
            fPort.writeIota(hexlist)
        end
    end
end

mainloop()
 