local m = {}
---@alias OpFuncMotion "line" | "char" | "block"
---@alias Region [integer, integer, integer, integer]
---@alias Selection {reg: Region, text: string[]}

---Get selected text from opfunc
---@param motion_type OpFuncMotion
---@return {reg: [[number, number, number, number], [number, number, number, number]][], text: string[]} | nil
function m.get_opfunc_selection(motion_type)
    local sel_start = vim.fn.getpos("'[")
    local sel_end = vim.fn.getpos("']")
    if motion_type == "char" then
        local selected_region = vim.fn.getregionpos(sel_start, sel_end)
        local selected_text = vim.fn.getregion(sel_start, sel_end)
        return {
            reg = selected_region,
            text = selected_text,
        }
    elseif motion_type == "line" then
        local lines = vim.api.nvim_buf_get_lines(0, sel_start[2] - 1, sel_end[2], true)
        sel_start = {sel_start[1], sel_start[2], 1, sel_start[4]}
        sel_end = {sel_end[1], sel_end[2], lines[#lines]:len(), sel_end[4]}
        local selected_region = vim.fn.getregionpos(sel_start, sel_end)
        return {
            reg = selected_region,
            text = lines,
        }
    elseif motion_type == "block" then
        local full_lines = vim.api.nvim_buf_get_lines(0, sel_start[2] - 1, sel_end[2], true)
        local lines = {}
        for _, line in ipairs(full_lines) do
            table.insert(lines, line:sub(sel_start[3], sel_end[3]))
        end
        local selected_region = vim.fn.getregionpos(sel_start, sel_end, {type = vim.keycode("<C-v>" .. sel_end[3] - sel_start[3] + 1)})
        return {
            reg = selected_region,
            text = lines,
        }
    else
        vim.notify("Error: unknown opfunc motion_type: ".. vim.inspect(motion_type) ..".", 4)
        return nil
    end
end

---@param new_lines string[]
---@param selection Selection
---@param motion_type OpFuncMotion
function m.apply_changes(new_lines, selection, motion_type)
    local buf = 0-- selection.reg[1][1][1] - 1
    if motion_type == "block" then
        for i, subreg in ipairs(selection.reg) do
            local start_row = subreg[1][2] - 1
            local start_col = subreg[1][3] - 1
            local end_row = subreg[2][2] - 1
            local end_col = subreg[2][3]
            vim.api.nvim_buf_set_text(buf, start_row, start_col, end_row, end_col, {new_lines[i]})
        end
        local start_row = selection.reg[1][1][2] - 1
        local start_col = selection.reg[1][1][3] - 1
        vim.api.nvim_win_set_cursor(0, {start_row + 1, start_col})
    else
        local start_row = selection.reg[1][1][2] - 1
        local start_col = selection.reg[1][1][3] - 1
        local end_row = selection.reg[#selection.reg][2][2] - 1
        local end_col = selection.reg[#selection.reg][2][3]
        vim.api.nvim_buf_set_text(buf, start_row, start_col, end_row, end_col, new_lines)
        vim.api.nvim_win_set_cursor(0, {start_row + 1, start_col})
    end
end

---Whether or not char `c` matches PCRE2 `^[0-9a-fA-F]$`
---@param c number
---@return boolean
local function is_hex(c)
    return (65 <= c and c <= 70)  -- A-F
        or (97 <= c and c <= 102) -- a-f
        or (48 <= c and c <= 57)  -- 0-9
end

---Whether or not `s` matches PCRE2 `^(\\x[0-9a-fA-F]{2})*$`
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
    end
    return valid
end

function string.is_unescaped_hex(s)
    return s:match("^%x*$") or not (s:len() % 2 == 0)
end

---@param s string
---@return string
function string.to_hex(s)
    local fmt_str = vim.g.hexfmt_casing == "upper" and "%02X" or "%02x"
    local s_len = s:len()
    local hex_str = ""
    for i=1, s_len do
        hex_str = hex_str .. string.format(fmt_str, s:byte(i, i+1))
    end
    return hex_str
end

---Generates the function that binds and invokes the opfunc for an `expr=true` mapping
---@param func string
---@param linewise boolean
---@return function
local function to_opfunc(func, linewise)
    return function()
        vim.o.opfunc = "v:lua.require'hexfmt'."..func
        return "g@" .. (linewise and "_" or "")
    end
end

---***TODO:*** retrieve func name from symbol instead of passing a string (i.e. pass func as a function)
---@param bind string | nil
---@param plug_bind string
---@param func string
---@param desc string
---@param linewise boolean
function m.setup_opfunc_bind(bind, plug_bind, func, desc, linewise)
    plug_bind = "<plug>(" .. plug_bind .. ")"
    vim.keymap.set({"n", "x"}, bind or plug_bind , to_opfunc(func, false), {desc=desc, silent=true, expr=true})

    if linewise then
        vim.keymap.set(
            "n",
            bind and bind .. "<leader>" or plug_bind:sub(0, -2) .. "Line)",
            to_opfunc(func, true),
            {desc=desc .. " (line-wise)", silent=true, expr=true}
        )
    end
end

return m
