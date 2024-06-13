local path = arg[1]
if(path == nil) then
    print("#param 1 : filePath")
    return
end
if(fs.exists(path) == false) then
    print("file "..path.." is not exist!")
    return
end
local inf = io.open(path,"r") -- the source_code filename
local str = inf.read(inf,"*all")
inf.close(inf)

local fPort = peripheral.find("focal_port")

local lastIndex = 0
local index = -1
local leftBrackIndex = nil

local hexlist = {} -- the final table use to output

local hexMap = { -- add pattern table to this table
    ["me"] = {["startDir"]="EAST",["angles"]="qaq"},
    ["{"] = {["startDir"]="WEST",["angles"]="qqq"},
    ["}"] = {["startDir"]="EAST",["angles"]="eee"},
    ["pos"] = {["startDir"]="EAST",["angles"]="aa"},
    ["sight"] = {["startDir"]="EAST",["angles"]="wa"},
    ["unpack"] = {["startDir"]="NORTH_WEST",["angles"]="qwaeawq"},
    ["+"] = {["startDir"]="NORTH_EAST",["angles"]="waaw"},
    ["-"] = {["startDir"]="NORTH_WEST",["angles"]="wddw"},
    ["*"] = {["startDir"]="SOUTH_EAST",["angles"]="waqaw"}
}

local NumMap = {
    [0] = {["startDir"]="SOUTH_EAST",["angles"]="aqaa"},
    ["+1"] = (function () return "w" end),
    ["*2"] = (function () return "a" end)
}

local regMap = {
    ["^[ ]*([{}*+])[ ]*$"] = (function (cStr)
        table.insert(hexlist,hexMap[cStr])
    return true end),
    ["^[ ]*rm[ ]*(%d+)[ ]*$"] = (function (cStr)
        addRMPattern(cStr)
    return true end),
    ["^[ ]*(-?[%w_]+)[ ]*$"] = (function (cStr)
        if( tonumber(cStr) ~= nil) then
            addNumPattern(tonumber(cStr))
        else
            local t = hexMap[cStr]
            if t == nil then
                return false
            end
            table.insert(hexlist,t)
        end
    return true end),
}

function addNumPattern(num)
    local numPattern = {}
    local opers = {}
    local size = 0
    local rem = num > 0 and num or -num
    local numStr = "aqaa"
    numPattern["startDir"] = "SOUTH_EAST"
    repeat
        if rem % 2 == 0 then
            table.insert(opers, "*2")
            rem = rem / 2
        else
            table.insert(opers,"+1")
            rem = rem -1
        end
        size = size +1
    until  rem < 1  
    for i = size, 1, -1 do
        numStr = numStr..NumMap[opers[i]]()
    end
    numPattern["angles"] = numStr
    if num < 0 then
        table.insert(hexlist,NumMap[0])
        table.insert(hexlist,numPattern)
        table.insert(hexlist,hexMap["-"])
    else 
        table.insert(hexlist,numPattern)
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
   
function mainloop()
    local lastIndex = 0
    local index = -1
    local cut = ""
    local lineIndex = 0
    while ( index ~= nil) do
        local syntaxFlag = true;
        lineIndex = lineIndex + 1
        index = string.find(str,"\n", index + 2);
        if( index ~= nil) then
            cut = string.sub(str,lastIndex, index-1);
        else
            cut = string.sub(str,lastIndex, index);
        end
        cut = string.gsub(cut,"\n","")
        lastIndex = index

        for key, cb in pairs(regMap) do
            if (string.match(cut,key)~= nil) then
                local cStr = string.match(cut,key)
                syntaxFlag = cb(cStr)
                break
            end   
        end
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

mainloop()