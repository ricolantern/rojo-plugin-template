const SelectionService = game:GetService("Selection")

const Info = require(script.Lib.Info)
const Subtools = require(script.Lib.Subtools)

const TOOLBAR = plugin:CreateToolbar(Info.NAME)

Subtools.init(TOOLBAR, script.Tools)