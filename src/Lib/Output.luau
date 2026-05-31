const Info = require(script.Parent.Info)

local Output = {}

function Output.print<T...>(msg: string, ...: T...): ()
    print(`[{Info.NAME}] :: {msg}`, ...)
end

function Output.warn<T...>(msg: string, ...: T...): ()
    warn(`[{Info.NAME}] :: {msg}`, ...)
end

function Output.blank(): ()
    print("\n\n")
end

return table.freeze(Output)