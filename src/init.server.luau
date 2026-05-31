const SelectionService = game:GetService("Selection")

const Info = require(script.Core.Info)
const Output = require(script.Core.Output)

const PLUGIN_TOOLBAR = plugin:CreateToolbar(Info.NAME)
const OPT_RUN_NAME = "Example Button"
const OPT_RUN_BTN = PLUGIN_TOOLBAR:CreateButton(tostring(os.clock()), "Example Description", "", OPT_RUN_NAME)

OPT_RUN_BTN.Click:Connect(function()
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
end)
