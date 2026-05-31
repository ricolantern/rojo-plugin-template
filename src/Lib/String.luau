
const CHARS = "abcdefghijklmnopqrstuvwxyz"

const String = {}

function String.getChar(n: number): string
    return CHARS:sub(n, n)
end

return String