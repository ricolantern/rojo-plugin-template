const SelectionService = game:GetService("Selection")

const ROOT = script.Parent.Parent
const LIB = ROOT.Lib

const Tool = require(LIB.Subtools.Tool)
const Output = require(LIB.Output)

return Tool.new {
    name = "Example",
    desc = "Example Tool",
    version = "1.0.0",
    options = {
        {
            name = "Print selection name",
            desc = "Outputs the name of the current selection to console.",
            version = "1.0.0",
            execute = function(): ()
                const selections = SelectionService:Get()

                if #selections > 1 then
                    Output.warn(`Multiple selections are not supported.`)
                    Output.blank()
                    return
                elseif #selections == 0 then
                    Output.warn(`You have nothing selected.`)
                    Output.blank()
                    return
                end

                const selected = selections[1]

                Output.print(`You selected {selected.Name}!`)
            end,
        }
    }
}