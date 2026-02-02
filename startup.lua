local ccm = require "cc.completion"
local completion = require("cc.shell.completion")
local path_complete = completion.build(
    completion.file
)
local function iotaTools_completion(shell, index, partial, previousArgs)
    if index == 1 then
        return ccm.choice(partial, {"append", "toStr", "dec" })
        
    elseif index == 2 then
        if previousArgs[2] == "append" then
            return ccm.choice(partial, { "overWrite" })
        end
    end
    return nil
end

shell.setCompletionFunction("iotaTools.lua", iotaTools_completion)
shell.setCompletionFunction("hex.lua", path_complete)
shell.setCompletionFunction("hedit.lua", path_complete)
