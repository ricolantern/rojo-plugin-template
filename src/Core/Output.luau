const Constants = require(script.Parent.Constants)

local Output = {}

function Output.print<T...>(msg: string, ...: T...): ()
    print(`[{Constants.PLUGIN_NAME}] :: {msg}`, ...)
end

function Output.warn<T...>(msg: string, ...: T...): ()
    warn(`[{Constants.PLUGIN_NAME}] :: {msg}`, ...)
end

function Output.blank(): ()
    print("\n\n")
end

return table.freeze(Output)