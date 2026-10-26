--[[
    * this tools reads Iota from the configured inventory slot
    * if specify argument "dec" will be decompilation iota to hex code
    * author : Lanzr
]]
require("hexMap")

local cmd = arg[1]
local dev = require("iotaBridge")

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
    tipWriter("toStr", " get configured slot Iota to string and save in \"data\" file")
    tipWriter("dec", " get configured slot Iota and decompile code based on patMap and store it in \"dec_out\" file ")
    tipWriter("view", " Read the mapping patterns from patMap and draw a preview. ")
    tipWriter("append", " Read Iotas from the configured slot and add them to hexMap. ")
    return
end


function hexView(pattern)
    local pathData = "w"..pattern.."w"
    
    local RADIUS = 4          
    local MOVE_STEP = 8       
    local ANIM_SPEED = 0.2   
    
    local C_BG    = colors.black
    local C_LINE  = colors.cyan
    local C_NODE  = colors.blue
    local C_HEAD  = colors.white 
    local C_START = colors.red
    
    local DIRECTIONS = {
        {1, 0}, {0, 1}, {-1, 1}, {-1, 0}, {0, -1}, {1, -1}
    }
    local TURN_MAP = {
        ['a'] = -2, ['q'] = -1, ['w'] = 0, ['e'] = 1, ['d'] = 2
    }
    local function hex_to_rel_pixel(q, r)
        local x = (math.sqrt(3) * q + (math.sqrt(3)/2) * r) * RADIUS * 1.6
        local y = (3/2 * r) * RADIUS
        return math.floor(x), math.floor(y)
    end
    
    
    local function generate_path_points(data)
        local points = {}
        local q, r = 0, 0
        local dir_idx = 0 
        
        local sx, sy = hex_to_rel_pixel(0, 0)
        table.insert(points, {x = sx, y = sy})
        for i = 1, #data do
            local char = string.sub(data, i, i)
            local turn = TURN_MAP[char]
            if turn then
                dir_idx = (dir_idx + turn) % 6
                if dir_idx < 0 then dir_idx = dir_idx + 6 end
                local vec = DIRECTIONS[dir_idx + 1]
                q = q + vec[1]
                r = r + vec[2]
                local px, py = hex_to_rel_pixel(q, r)
                table.insert(points, {x = px, y = py})
            end
        end
        return points
    end
    
    
    local function draw_scene(points, progress_index, cam_x, cam_y)
        local ret = true
        term.setBackgroundColor(C_BG)
        term.clear()
        
        term.setCursorPos(1, 1)
        term.setTextColor(colors.gray)
        local pl = #points -1
        if progress_index < #points then
            term.write("Drawing... " .. math.floor(progress_index/pl*100) .. "%")
        else
            ret = false
        end
        
        
        for i = 1, progress_index - 1 do
            local p1 = points[i]
            local p2 = points[i+1]
            local x1, y1 = p1.x + cam_x, p1.y + cam_y
            local x2, y2 = p2.x + cam_x, p2.y + cam_y
            paintutils.drawLine(x1, y1, x2, y2, C_LINE)
            paintutils.drawPixel(x1, y1, C_NODE)
        end
        
        if progress_index >= 1 then
            
            local start = points[1]
            paintutils.drawPixel(start.x + cam_x, start.y + cam_y, C_START)
            
            local head = points[progress_index]
            paintutils.drawPixel(head.x + cam_x, head.y + cam_y, C_HEAD)
        end
        return ret
    end
    
    local function main()
        local all_points = generate_path_points(pathData)
        local w, h = term.getSize()
        local cam_x = math.floor(w/2) 
        local cam_y = math.floor(h/2) 
        while true do
            
            local current_step = 1       
            local running = true
            local stopFlag = false
            
            local anim_timer = os.startTimer(ANIM_SPEED)
            
            draw_scene(all_points, current_step, cam_x, cam_y)
            while running do
                
                local event, p1 = os.pullEvent()
               
                if event == "timer" and p1 == anim_timer then
                    
                    if current_step < #all_points then
                        current_step = current_step + 1
                        
                        
                        
                        
                        anim_timer = os.startTimer(ANIM_SPEED)
                        ret = draw_scene(all_points, current_step, cam_x, cam_y)
                       
                        if ret == false then
                            break
                        end
                        
                    end
                elseif event == "key" then
                    
                    local key = p1
                    local moved = false
                    if key == keys.q then
                        os.pullEvent()
                        running = false
                        stopFlag = true
                    elseif key == keys.r then
                        running = false
                    elseif key == keys.left then
                        cam_x = cam_x + MOVE_STEP; moved = true
                    elseif key == keys.right then
                        cam_x = cam_x - MOVE_STEP; moved = true
                    elseif key == keys.up then
                        cam_y = cam_y + MOVE_STEP; moved = true
                    elseif key == keys.down then
                        cam_y = cam_y - MOVE_STEP; moved = true
                    elseif key == keys.pageUp then
                        RADIUS = RADIUS + 0.5;
                        all_points = generate_path_points(pathData)
                    elseif key == keys.pageDown then
                        RADIUS = RADIUS - 0.5;
                        if RADIUS < 0.5 then
                            RADIUS = 0.5
                        end
                        all_points = generate_path_points(pathData)
                    end
                    
                    if moved then
                        draw_scene(all_points, current_step, cam_x, cam_y)
                    end
                end
             
            end
            
            term.setCursorPos(1, 1)
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.white)
            term.clear()
            term.setCursorPos(1, 1)
            if stopFlag then
                break
            end
        end
    end
    main()
end


function hexView(pattern)
    local pathData = "w"..pattern.."w"
    
    local RADIUS = 4          
    local MOVE_STEP = 8       
    local ANIM_SPEED = 0.2   
    
    local C_BG    = colors.black
    local C_LINE  = colors.cyan
    local C_NODE  = colors.blue
    local C_HEAD  = colors.white 
    local C_START = colors.red
    
    local DIRECTIONS = {
        {1, 0}, {0, 1}, {-1, 1}, {-1, 0}, {0, -1}, {1, -1}
    }
    local TURN_MAP = {
        ['a'] = -2, ['q'] = -1, ['w'] = 0, ['e'] = 1, ['d'] = 2
    }
    local function hex_to_rel_pixel(q, r)
        local x = (math.sqrt(3) * q + (math.sqrt(3)/2) * r) * RADIUS * 1.6
        local y = (3/2 * r) * RADIUS
        return math.floor(x), math.floor(y)
    end
    
    
    local function generate_path_points(data)
        local points = {}
        local q, r = 0, 0
        local dir_idx = 0 
        
        local sx, sy = hex_to_rel_pixel(0, 0)
        table.insert(points, {x = sx, y = sy})
        for i = 1, #data do
            local char = string.sub(data, i, i)
            local turn = TURN_MAP[char]
            if turn then
                dir_idx = (dir_idx + turn) % 6
                if dir_idx < 0 then dir_idx = dir_idx + 6 end
                local vec = DIRECTIONS[dir_idx + 1]
                q = q + vec[1]
                r = r + vec[2]
                local px, py = hex_to_rel_pixel(q, r)
                table.insert(points, {x = px, y = py})
            end
        end
        return points
    end
    
    
    local function draw_scene(points, progress_index, cam_x, cam_y)
        local ret = true
        term.setBackgroundColor(C_BG)
        term.clear()
        
        term.setCursorPos(1, 1)
        term.setTextColor(colors.gray)
        local pl = #points -1
        if progress_index < #points then
            term.write("Drawing... " .. math.floor(progress_index/pl*100) .. "%")
        else
            ret = false
        end
        
        
        for i = 1, progress_index - 1 do
            local p1 = points[i]
            local p2 = points[i+1]
            local x1, y1 = p1.x + cam_x, p1.y + cam_y
            local x2, y2 = p2.x + cam_x, p2.y + cam_y
            paintutils.drawLine(x1, y1, x2, y2, C_LINE)
            paintutils.drawPixel(x1, y1, C_NODE)
        end
        
        if progress_index >= 1 then
            
            local start = points[1]
            paintutils.drawPixel(start.x + cam_x, start.y + cam_y, C_START)
            
            local head = points[progress_index]
            paintutils.drawPixel(head.x + cam_x, head.y + cam_y, C_HEAD)
        end
        return ret
    end
    
    local function main()
        local all_points = generate_path_points(pathData)
        local w, h = term.getSize()
        local cam_x = math.floor(w/2) 
        local cam_y = math.floor(h/2) 
        while true do
            
            local current_step = 1       
            local running = true
            local stopFlag = false
            
            local anim_timer = os.startTimer(ANIM_SPEED)
            
            draw_scene(all_points, current_step, cam_x, cam_y)
            while running do
                
                local event, p1 = os.pullEvent()
               
                if event == "timer" and p1 == anim_timer then
                    
                    if current_step < #all_points then
                        current_step = current_step + 1
                        
                        
                        
                        
                        anim_timer = os.startTimer(ANIM_SPEED)
                        ret = draw_scene(all_points, current_step, cam_x, cam_y)
                       
                        if ret == false then
                            break
                        end
                        
                    end
                elseif event == "key" then
                    
                    local key = p1
                    local moved = false
                    if key == keys.q then
                        os.pullEvent()
                        running = false
                        stopFlag = true
                    elseif key == keys.r then
                        running = false
                    elseif key == keys.left then
                        cam_x = cam_x + MOVE_STEP; moved = true
                    elseif key == keys.right then
                        cam_x = cam_x - MOVE_STEP; moved = true
                    elseif key == keys.up then
                        cam_y = cam_y + MOVE_STEP; moved = true
                    elseif key == keys.down then
                        cam_y = cam_y - MOVE_STEP; moved = true
                    elseif key == keys.pageUp then
                        RADIUS = RADIUS + 0.5;
                        all_points = generate_path_points(pathData)
                    elseif key == keys.pageDown then
                        RADIUS = RADIUS - 0.5;
                        if RADIUS < 0.5 then
                            RADIUS = 0.5
                        end
                        all_points = generate_path_points(pathData)
                    end
                    
                    if moved then
                        draw_scene(all_points, current_step, cam_x, cam_y)
                    end
                end
             
            end
            
            term.setCursorPos(1, 1)
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.white)
            term.clear()
            term.setCursorPos(1, 1)
            if stopFlag then
                break
            end
        end
    end
    main()
end


function table2str(t)
    local function serialize(value)
        local kind = type(value)
        if kind == "string" then return string.format("%q", value) end
        if kind == "number" or kind == "boolean" then return tostring(value) end
        assert(kind == "table", "Unsupported Iota value: " .. kind)
        local count = #value
        local array = true
        for key in pairs(value) do
            if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > count then
                array = false
                break
            end
        end
        local parts = {}
        if array then
            for i = 1, count do parts[#parts + 1] = serialize(value[i]) end
        else
            local keys = {}
            for key in pairs(value) do keys[#keys + 1] = key end
            table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
            for _, key in ipairs(keys) do
                parts[#parts + 1] = "[" .. serialize(key) .. "]=" .. serialize(value[key])
            end
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return serialize(t)
end

function decompilation()
    local text = require("iotaDecompiler").render(dev.readIota(), hexMap, rawMap)
    local output = assert(io.open("_dec_out", "w"))
    output:write(text)
    output:close()
end


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


local function insert_data(filename, pos, text)
    
    local f = io.open(filename, "rb")
    if not f then return nil end
    local before = f:read(pos)
    local after = f:read("*a")
    
    f:close()
    
    local f = io.open(filename, "wb")
    f:write(before)
    f:write(text)
    f:write(after)
    f:close()
end
function append_pattern()
    data = dev.readIota()
    if data["angles"] ~= nil then
        data = {data}
    end
    local targetFile = "hexMap"
    
    anti_hexMap = {}
    for cmd, iota in pairs(hexMap) do
        anti_hexMap[iota] = true
    end

    
    f = io.open("hexMap", "rb")
    line = f:read("*all")
    f:close()
    local sp,ep = string.find(line, "[ ]*hexMap[ ]*=")
    sp,ep = string.find(line, "\r?\n",ep+1)
    
    o_str = ""
    o_str_lsit = {}
    o_list = {}
    for index,p_iota  in pairs(data) do
        local flag = anti_hexMap[p_iota["angles"]]
        if flag == nil then  
            
            
            local str =  "    [\"%s\"] = \"" .. p_iota["angles"] .. "\",\n"
            table.insert(o_str_lsit,str)
            table.insert(o_list,true)
        else 
            table.insert(o_list,false)
        end
    end
    
    key_ls = {}
    
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
    insert_data(targetFile, ep, o_str)
    
end

function append_raw()
    local param2 = arg[3]
    data = dev.readIota()
    if param2 == "list" then
        assert(type(data) == "table" and data.angles == nil
            and data.x == nil and data.y == nil and data.z == nil
            and not data.null and not data.garbage,
            "append raw list expects a list Iota")
        for key in pairs(data) do
            assert(type(key) == "number" and key % 1 == 0
                and key >= 1 and key <= #data,
                "append raw list expects a list Iota")
        end
    else
        data = {data}
    end
    local targetFile = "hexMap"
    

    
    f = io.open("hexMap", "rb")
    line = f:read("*all")
    f:close()
    local sp,ep = string.find(line, "[ ]*rawMap[ ]*=")
    sp,ep = string.find(line, "\r?\n",ep+1)
    
    o_str = ""
    o_str_lsit = {}
    o_list = {}
    for index,p_iota in ipairs(data) do
        
        table.insert(o_str_lsit, table2str(p_iota))
        table.insert(o_list,true)
    end
    
    key_ls = {}
    
    term_m:init()
    valid_index = 1
    for i, status in pairs(o_list) do
        if status then
            term_m:write(i..". ",false)
            ret = term_m:read()
            assert(ret:match("^[%a_][%w_]*$") and ret ~= "true"
                and ret ~= "false" and ret ~= "null" and ret ~= "garbage",
                "rawMap name must be a non-reserved identifier")
            o_str = o_str .. "    [" .. string.format("%q", ret) .. "] = "
                .. o_str_lsit[valid_index] .. ",\n"
            valid_index = valid_index + 1
        else
            term_m:write(i..". IOTA INVALID",true)
        end
    end
    term_m:init()
    insert_data(targetFile, ep, o_str)
end
function handler_append()
    local param1 = arg[2]
    if(param1 ~=nil and param1 == "raw")then
        append_raw()
        return true
    end
    append_pattern()
    return true
end

function handler_view()
    local key = arg[2]
    local pattern = hexMap[key]
    if pattern == nil then
        print("pattern "..key.." not found!")
        return true
    end
    hexView(pattern)
end


local function getIotaMap()
    d = dev.readIota()
    str = table2str(d)
    f = io.open("_toStr_out","w")
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
    ["view"] = (function (cStr)
        handler_view()
    return true end),
    ["append"] = (function (cStr)
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
