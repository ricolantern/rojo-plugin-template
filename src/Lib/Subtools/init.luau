--!nonstrict
--[[
    Standardizes creating and modifying tools within a single plugin,
    useful for when you need to add more features to one.
]]

const ROOT = script.Parent.Parent
const Tool = require(script.Tool)
const String = require(ROOT.Lib.String)

const Subtools = {}

function Subtools.init(toolbar: PluginToolbar, folder: Folder): ()
    for i, module in next, folder:GetChildren() do
        assert(module:IsA("ModuleScript"), "All tools must be a valid ModuleScript!")

        const tool: Tool.Class = require(module)
        local toolName: string = `{i}. [{tool.name}]`
        local j: number = 0
        
        do -- about
            j += 1
            
            local name: string = `ABOUT {tool.name} v{tool.version}`
            local displayName: string = `{toolName} {String.getChar(j)}) {name}`
            local instance: PluginToolbarButton = toolbar:CreateButton(`{tool.name}.{name}`, "Displays this tool's information.", "", displayName)

            instance.Click:Connect(function()
                print(`{name}:\n{tool.desc}`)
            end)
        end
        
        for _, option in next, tool.options do
            j += 1
            
            local displayName: string = `{toolName} {String.getChar(j)}) {option.name}`
            local instance: PluginToolbarButton = toolbar:CreateButton(`{tool.name}.{option.name}`, option.desc, "", displayName)
            
            instance.Click:Connect(function()
                option.execute()
            end)
        end
    end
end

return table.freeze(Subtools)