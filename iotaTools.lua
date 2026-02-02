--[[
    * this tools is read iota from focal_port to string
    * if specify argument "dec" will be decompilation iota to hex code
    * author : Lanzr
]]
require("hexMap")

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
    ["q"] = (function (sum)
        return sum + 5
    end),
    ["e"] = (function (sum)
        return sum + 10
    end),
    ["d"] = (function (sum)
        return sum / 2
    end),
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
        for i = 1, indentation_level, 1 do
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
-- ----------------------------------------------
-- term_manger
local term_m = {
    content = "",
    line_index = 1,
    cursor_pos = 1,
    tw = 0,
    th = 0
}
function term_m:init()
    term.clear()
    term.setCursorPos(1,1)
    self.content = ""
    self.line_index = 1
    self.cursor_pos = 1
    self.tw,self.th = term.getSize()
end
function term_m:tryExtend()
    self.line_index = self.line_index + 1
    
    if self.cursor_pos > self.th-2 then
        term.scroll(1)
        term.setCursorPos(1, self.cursor_pos)
    else
        self.cursor_pos = self.cursor_pos + 1
        term.setCursorPos(1, self.cursor_pos)
    end
end
function term_m:write(line,move)
    term.write(line)
    self.content = self.content .. line
    if move then
        self:tryExtend()
    end
end
function term_m:read()
    line = ""
    tx,ty = term.getCursorPos()
    repeat
        line = io.read()
        term.setCursorPos(1, tx,ty)
        jug = string.match(line, "^[\t ]*$")
    until line ~= nil and line ~= "" and jug == nil
    self.content = self.content .. line .. "\n"    
    term_m:tryExtend()
    return line
end
-- ----------------------------------------------

local function insert_data(filename, pos, text)
    
    local f = io.open(filename, "r+")
    if not f then return nil end

    f:seek("set", pos)
    
    local rest_content = f:read("*a")
    
    f:seek("set", pos)
    
    f:write(text)
    f:write(rest_content)
    
    f:close()
end
-- ! append
function handler_append()
    data = dev.readIota()
    if data["angles"] ~= nil then
        data = {data}
    end
    local targetFile = "newHexMap"
    if g_force_mode then
        targetFile = "thexMap"
    end
    -- 查找现有的表
    anti_hexMap = {}
    for cmd, iota in pairs(hexMap) do
        anti_hexMap[iota] = true
    end

    -- 获取插入点位
    f = io.open("hexMap", "rb")
    line = f:read("*all")
    f:close()
    local sp,ep = string.find(line, "[ ]*hexMap[ ]*=")
    sp,ep = string.find(line, "\r?\n",ep+1)
    local str =  "    [\"\"] = {\"" .. 'asdasd' .. "\"},\n"
    -- 查找有没有新的图案
    o_str = ""
    o_str_lsit = {}
    o_list = {}
    for index,p_iota  in pairs(data) do
        local flag = anti_hexMap[p_iota["angles"]]
        if flag == nil then  -- 新的图案
            -- 原版hexMap使用下面的生成
            -- local tmp = "[\"startDir\"] = \"East\", [\"angles\"] = \"" .. p_iota["angles"] .. "\""
            local str =  "    [\"%s\"] = \"" .. p_iota["angles"] .. "\",\n"
            -- o_str_lsit.append(str)
            table.insert(o_str_lsit,str)
            -- o_list.append(true)
            table.insert(o_list,true)
        else
            -- 旧的图案
            -- o_list.append(false)
            table.insert(o_list,false)
        end
    end
    -- 插入
    key_ls = {}
    if g_force_mode then
        -- 打开一个新的UI用来逐个键写入
        term_m:init()
        valid_index = 1
        for i, status in pairs(o_list) do
            if status then
                term_m:write(i..". ",false)
                ret = term_m:read()
                o_str = o_str .. string.format(o_str_lsit[valid_index],ret)
                valid_index = valid_index + 1
            else
                term_m:write(i..". PATTERN INVALID",true)
            end
        end
    end
    
    insert_data("hexMap", ep, o_str)
    
end
-- ----------------------------------------------

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
        handler_append()
    return true end)
}
local function mainloop()
    local cb = toolsMap[cmd]
    if cb ~= nil then
        cb()
    else
        print("command "..cmd.." not found!")
    end
end

mainloop()