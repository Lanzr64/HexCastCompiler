local completion = require "cc.shell.completion"
local path_complete = completion.build(
    completion.file
)
local iotaTools_completion = completion.build(
    { completion.choice, { "toStr", "dec", "append" } },
    { completion.choice, { "overWrite" } }
)
shell.setCompletionFunction("hedit.lua", path_complete)
shell.setCompletionFunction("hex.lua", path_complete)
shell.setCompletionFunction("iotaTools.lua", iotaTools_completion)