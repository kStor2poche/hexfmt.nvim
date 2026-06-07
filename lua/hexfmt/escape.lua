local _ = require("helpers") -- used for string.is_(un)escaped_hex functions
local m = {}

---Turns a hex string (`0x` prefixed or not) into a sequence of `\x` prefixed bytes
---@param line string
---@return string | nil
function m.escape_line(line)
    if line:sub(1, 2) == "0x" then
        line = line:sub(3)
    end

    if vim.g.hexfmt_casing == "upper" then
        line = line:upper()
    elseif vim.g.hexfmt_casing == "lower" then
        line = line:lower()
    end

    -- vim.notify("line after leading 0x removal & casing:"..line)

    if not line:is_unescaped_hex() then
        vim.notify("Error: text isn't a valid unescaped hex string", 4)
        return
    end

    local escaped = ""
    for i = 1, line:len(), 2 do
        escaped = escaped.."\\x"..line:sub(i, i+1)
    end

    return escaped
end

---Turns a sequence of `\x` prefixed bytes into a hex string (`0x` prefixed or not)
---@param line string
---@return string | nil
function m.unescape_line(line)
    if not line:is_escaped_hex() then
        vim.notify("Error: text isn't a valid escaped hex string", 4)
        return
    end

    local unescaped = ""

    for i = 1, line:len(), 4 do
        unescaped = unescaped..line:sub(i+2, i+3)
    end

    if vim.g.hexfmt_casing == "upper" then
        unescaped = unescaped:upper()
    elseif vim.g.hexfmt_casing == "lower" then
        unescaped = unescaped:lower()
    end
    if vim.g.hexfmt_prefix_on_unescape then
        unescaped = "0x"..unescaped
    end
    -- vim.notify("unescaped after potential 0x prepend & casing:"..unescaped)

    return unescaped
end

return m
