
const PLUGIN = script.Parent.Parent.Parent
const ROOT = script.Parent.Parent
const META = ROOT:FindFirstChild("Metadata") :: Configuration
const VERSION = META:GetAttribute("Version") :: string
const NAME = `{string.match(PLUGIN.Name, "user_(.+)%.rbxmx") :: string} v{VERSION}`
const DESC = [[
    Example plugin.
]]

const Core = {
    VERSION = VERSION,
    NAME = NAME,
    DESC = DESC,
}

return Core