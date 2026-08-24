local m = {}

---Get selected text from either movement or visual selection
---@param move string | nil
---@return {reg: [[number, number, number, number], [number, number, number, number]][], text: string[]} | nil
function m.get_selection(move)
    if not move then -- get visual selection
        local mode = vim.api.nvim_get_mode().mode
        local vis_start = vim.fn.getpos(".")
        local vis_end = vim.fn.getpos("v")
        if mode == "v" then
            local selected_region = vim.fn.getregionpos(vis_start, vis_end)
            local selected_text = vim.fn.getregion(vis_start, vis_end)
            -- vim.notify("selected_text:"..selected_text[1])
            -- vim.notify("selected_region:"..vim.inspect(selected_region))
            return {
                reg = selected_region,
                text = selected_text,
            }
        elseif mode == "V" then
            if vis_start[2] > vis_end[2] then
                local tmp = vis_start
                vis_start = vis_end
                vis_end = tmp
            end
            -- vim.notify("vis_start[2]:"..vis_start[2])
            -- vim.notify("vis_end[2]:"..vis_end[2])
            local lines = vim.api.nvim_buf_get_lines(0, vis_start[2] - 1, vis_end[2], true)
            -- vim.notify("lines: "..vim.inspect(lines))
            vis_start = {vis_start[1], vis_start[2], 1, vis_start[4]}
            vis_end = {vis_end[1], vis_end[2], lines[#lines]:len(), vis_end[4]}
            local selected_region = vim.fn.getregionpos(vis_start, vis_end)
            -- vim.notify("selected_region: "..vim.inspect(selected_region))
            return {
                reg = selected_region,
                text = lines,
            }
        else
            vim.notify("Error: plugin only works in visual or visual-line mode for now.", 4)
            return nil
        end
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

---@param s string
---@return string
function string.to_hex(s)
    local s_len = s:len()
    local hex_str = ""
    for i=1, s_len do
        hex_str = hex_str .. string.format("%02x", s:byte(i, i+1))
    end
    return hex_str
end

return m
