local m = {}

---Get selected text from either movement or visual selection
---@param move string | nil
---@return {reg: [[number, number, number, number], [number, number, number, number]][], text: string[]} | nil
function m.get_selection(move)
    if not move then -- get visual selection
        -- vim.notify("visual mode:"..vim.api.nvim_get_mode().mode)
        if vim.api.nvim_get_mode().mode ~= "v" then
            vim.notify("Error: plugin only works in plain visual mode for now.", 4)
            return nil
        end
        local vis_start = vim.fn.getpos(".")
        local vis_end = vim.fn.getpos("v")
        local selected_region = vim.fn.getregionpos(vis_start, vis_end)
        local selected_text = vim.fn.getregion(vis_start, vis_end)
        -- vim.notify("selected_text:"..selected_text[1])
        -- vim.notify("selected_region:"..vim.inspect(selected_region))
        return {
            reg = selected_region,
            text = selected_text,
        }
    end
    return nil
end

---Whether or not char `c` matches PCRE2 `^[0-9a-zA-Z]$`
---@param c number
---@return boolean
local function is_hex(c)
    return (65 <= c and c <= 90)  -- A-Z
        or (97 <= c and c <= 122) -- a-z
        or (48 <= c and c <= 57)  -- 0-9
end

---Whether or not `s` matches PCRE2 `^(\\x[0-9a-zA-Z]{2})*$`
---@param s string
---@return boolean
function string.is_escaped_hex(s)
    local s_len = s:len()
    if not (s_len % 4 == 0) then
        return false
    end

    local valid = true
    for i = 1, s_len, 4 do
        valid = valid
            and s:sub(i, i+1) == "\\x"
            and is_hex(s:byte(i+2))
            and is_hex(s:byte(i+3))
        -- vim.notify("valid is "..vim.inspect(valid).." at i="..vim.inspect(i))
        -- vim.notify("s:sub(i,i+1) == \"\\x\": "..vim.inspect(s:sub(i, i+1) == "\\x"))
        -- vim.notify("is_hex(i+2): "..vim.inspect(is_hex(s:byte(i+2))))
        -- vim.notify("is_hex(i+3): "..vim.inspect(is_hex(s:byte(i+3))))

    end
    return valid
end

function string.is_unescaped_hex(s)
    return s:match("^%x*$") or not (s:len() % 2 == 0)
end

return m
