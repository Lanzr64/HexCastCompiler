local ccm = require "cc.completion"
local completion = require("cc.shell.completion")
local path_complete = completion.build(
    completion.file
)
require("hexMap")
local hexMapKey = {}
for name, iota in pairs(hexMap) do
    table.insert(hexMapKey, name)
end
local function iotaTools_completion(shell, index, partial, previousArgs)
    if index == 1 then
        return ccm.choice(partial, {"append", "toStr", "dec", "view" })
        
    elseif index == 2 then
        if previousArgs[2] == "append" then
            return ccm.choice(partial, { "pattern", "raw" })
        elseif previousArgs[2] == "view" then
            return ccm.choice(partial, hexMapKey)
        end
    elseif index == 3 then
        if previousArgs[3] == "raw" then
            return ccm.choice(partial, { "list" })
        end
    end
    return nil
end

shell.setCompletionFunction("iotaTools.lua", iotaTools_completion)
shell.setCompletionFunction("hex.lua", path_complete)
shell.setCompletionFunction("hedit.lua", path_complete)
