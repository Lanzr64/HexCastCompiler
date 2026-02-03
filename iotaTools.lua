--[[
    * this tools is read iota from focal_port to string
    * if specify argument "dec" will be decompilation iota to hex code
    * author : Lanzr
]]
require("hexMap")

local cmd = arg[1]
local dev = peripheral.find("focal_port")

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
    tipWriter("dec", " get focal_port iota and decompile code based on patMap and store it in \"dec_out\" file ")
    tipWriter("view", " Read the mapping patterns from patMap and draw a preview. ")
    tipWriter("append", " Used to read iotas from the forcal port and add them to the hexMap. ")
    return
end
-- patch hexview
-- 功能：逐步绘制动画 + 实时自由视角
function hexView(pattern)
    local pathData = "w"..pattern.."w"
    -- === 1. 配置参数 ===
    local RADIUS = 4          -- 六边形大小
    local MOVE_STEP = 8       -- 按键移动速度
    local ANIM_SPEED = 0.2   -- 动画速度 (秒/步)
    -- 颜色配置
    local C_BG    = colors.black
    local C_LINE  = colors.cyan
    local C_NODE  = colors.blue
    local C_HEAD  = colors.white -- 当前正在画的那个头节点
    local C_START = colors.red
    -- === 2. 核心数学 ===
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
    -- === 3. 数据预计算 (Model) ===
    -- 即使我们要逐步画，也最好先算好所有坐标，这样效率最高
    local function generate_path_points(data)
        local points = {}
        local q, r = 0, 0
        local dir_idx = 0 -- 0=东
        -- 起点
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
    -- === 4. 渲染函数 (View) ===
    -- 参数：所有点，当前画到了第几个点，摄像机偏移
    local function draw_scene(points, progress_index, cam_x, cam_y)
        local ret = true
        term.setBackgroundColor(C_BG)
        term.clear()
        -- 1. 绘制UI提示
        term.setCursorPos(1, 1)
        term.setTextColor(colors.gray)
        local pl = #points -1
        if progress_index < #points then
            term.write("Drawing... " .. math.floor(progress_index/pl*100) .. "%")
        else
            ret = false
        end
        -- 2. 绘制路径 (只画到 progress_index 为止)
        -- 为了性能，如果点非常多，可以只绘制屏幕范围内的线，但这里暂且全部绘制
        for i = 1, progress_index - 1 do
            local p1 = points[i]
            local p2 = points[i+1]
            local x1, y1 = p1.x + cam_x, p1.y + cam_y
            local x2, y2 = p2.x + cam_x, p2.y + cam_y
            paintutils.drawLine(x1, y1, x2, y2, C_LINE)
            paintutils.drawPixel(x1, y1, C_NODE)
        end
        -- 3. 绘制特殊的点
        if progress_index >= 1 then
            -- 起点
            local start = points[1]
            paintutils.drawPixel(start.x + cam_x, start.y + cam_y, C_START)
            -- 当前的头节点 (动画的先锋)
            local head = points[progress_index]
            paintutils.drawPixel(head.x + cam_x, head.y + cam_y, C_HEAD)
        end
        return ret
    end
    -- === 5. 主循环 (Controller) ===
    local function main()
        local all_points = generate_path_points(pathData)
        local w, h = term.getSize()
        local cam_x = math.floor(w/2) -- 摄像机X
        local cam_y = math.floor(h/2) -- 摄像机Y
        while true do
            -- 状态变量
            local current_step = 1       -- 当前画到第几步
            local running = true
            local stopFlag = false
            -- 启动第一个计时器
            local anim_timer = os.startTimer(ANIM_SPEED)
            -- 初始绘制一次
            draw_scene(all_points, current_step, cam_x, cam_y)
            while running do
                -- 等待任何事件（可能是按键，可能是计时器到期）
                local event, p1 = os.pullEvent()
               
                if event == "timer" and p1 == anim_timer then
                    -- == 动画逻辑 ==
                    if current_step < #all_points then
                        current_step = current_step + 1
                        -- 自动跟随视角 (可选：如果你希望镜头一直跟着画笔走，取消下面两行的注释)
                        -- local head = all_points[current_step]
                        -- cam_x, cam_y = math.floor(w/2) - head.x, math.floor(h/2) - head.y
                        -- 设置下一次“闹钟”
                        anim_timer = os.startTimer(ANIM_SPEED)
                        ret = draw_scene(all_points, current_step, cam_x, cam_y)
                       
                        if ret == false then
                            break
                        end
                        
                    end
                elseif event == "key" then
                    -- == 移动逻辑 ==
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
                    -- 只有移动了才重绘，节省资源
                    if moved then
                        draw_scene(all_points, current_step, cam_x, cam_y)
                    end
                end
             
            end
            -- 退出清理
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
    -- 配置参数
    local RADIUS = 4          -- 六边形大小
    local MOVE_STEP = 8       -- 按键移动速度
    local ANIM_SPEED = 0.2   -- 动画速度 (秒/步)
    -- 颜色配置
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
    local function serialize(tbl)
        local tmp = {}
        local is_array = #tbl > 0
        
        for k, v in pairs(tbl) do
            local k_type = type(k)
            local v_type = type(v)
            
            local key = ""
            if not is_array then
                if k_type == "string" then
                    key = "[\"" .. k .. "\"]="
                elseif k_type == "number" then
                    key = "[" .. k .. "]="
                end
            end

            local value
            if v_type == "table" then
                value = serialize(v)
            elseif v_type == "boolean" then
                value = tostring(v)
            elseif v_type == "string" then
                value = "\"" .. v .. "\""
            elseif v_type == "number" then
                value = tostring(v)
            else
                value = tostring(v)
            end

            if value then
                table.insert(tmp, key .. value)
            end
        end

        return "{" .. table.concat(tmp, ",") .. "}"
    end

    assert(type(t) == "table", "Input must be a table")
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
        anti_hexMap[iota] = cmd
    end
    data = dev.readIota()
    f = io.open("_dec_out","w")
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
    
    local f = io.open(filename, "r+")
    if not f then return nil end

    f:seek("set", pos)
    
    local rest_content = f:read("*a")
    
    f:seek("set", pos)
    
    f:write(text)
    f:write(rest_content)
    
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
    if not (param2 ~= nil and param2 == "list")then 
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
    for index,p_iota  in pairs(data) do
        
        local str =  "    [\"%s\"] = " .. table2str(p_iota) .. ",\n"
        table.insert(o_str_lsit,str)
        table.insert(o_list,true)
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