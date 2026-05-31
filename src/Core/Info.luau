
const META = script.Parent:FindFirstChild("Metadata") :: Configuration
const VERSION = META:GetAttribute("Version") :: string
const NAME = `{string.match(script.Parent.Name, "user_(.+)%.rbxmx") :: string} v{VERSION}`
const DESC = [[
    Example plugin.
]]

const Core = {
    VERSION = VERSION,
    NAME = NAME,
    DESC = DESC,
}

return Core