
const Tool = {}
Tool.__index = {}

export type Option = {
    name: string,
    desc: string,
    execute: () -> (),
}
export type Constructor = {
    name: string,
    desc: string,
    version: string,
    options: {Option},
}
export type Class = setmetatable<{

} & Constructor, typeof(Tool)>

function Tool.new(params: Constructor): Class
    return setmetatable(params, Tool)
end

return table.freeze(Tool)