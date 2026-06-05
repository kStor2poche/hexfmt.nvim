local h = require("hexfmt.helpers")
local conf = require("hexfmt.config")
local esc = require("hexfmt.escape")
local swp = require("hexfmt.endianness")

local m = {}

function m.swap_endianness()
    local sel = h.get_selection()
    if sel == nil then
        vim.api.nvim_feedkeys(vim.keycode("<esc>"), "x", false)
        return
    end

    ---[[@as table]]
    local text = sel.text
    ---@type string[]
    local swapped_lines = {}

    for _, line in ipairs(text) do
        local swapped = nil
        if line:is_escaped_hex() then
            swapped = swp.swap_endianness_esc_line(line)
        elseif line:is_unescaped_hex() then
            swapped = swp.swap_endianness_unesc_line(line, false)
        elseif line:sub(3):is_unescaped_hex() then
            swapped = swp.swap_endianness_unesc_line(line, true)
        end
        if swapped == nil then
            vim.api.nvim_feedkeys(vim.keycode("<esc>"), "x", false)
            return
        end
        table.insert(swapped_lines, swapped)
    end
    vim.notify("swapped="..vim.inspect(swapped_lines))
    local buf = 0-- sel.reg[1][1][1] - 1
    local start_row = sel.reg[1][1][2] - 1
    local start_col = sel.reg[1][1][3] - 1
    local end_row = sel.reg[#sel.reg][2][2] - 1
    local end_col = sel.reg[#sel.reg][2][3]
    vim.api.nvim_buf_set_text(buf, start_row, start_col, end_row, end_col, swapped_lines)
    vim.api.nvim_feedkeys(vim.keycode("<esc>"), "x", false)
    -- vim.api.nvim_win_set_cursor(0, {start_row + #swapped_lines, swapped_lines[#swapped_lines]:len() - 1})
    vim.api.nvim_win_set_cursor(0, {start_row, start_col})
end

---Turns a hex selection (`0x` prefixed or not) into a sequence of `\x` prefixed bytes
function m.escape_sel()
    local sel = h.get_selection()
    if sel == nil then
        vim.api.nvim_feedkeys(vim.keycode("<esc>"), "x", false)
        return
    end

    ---[[@as table]]
    local text = sel.text
    ---@type string[]
    local escaped_lines = {}

    vim.notify("text="..vim.inspect(text))
    for _, line in ipairs(text) do
        local escaped = esc.escape_line(line)
        if escaped == nil then
            vim.api.nvim_feedkeys(vim.keycode("<esc>"), "x", false)
            return
        end
        table.insert(escaped_lines, escaped)
    end
    vim.notify("escaped="..vim.inspect(escaped_lines))
    local buf = 0-- sel.reg[1][1][1] - 1
    local start_row = sel.reg[1][1][2] - 1
    local start_col = sel.reg[1][1][3] - 1
    local end_row = sel.reg[#sel.reg][2][2] - 1
    local end_col = sel.reg[#sel.reg][2][3]
    vim.api.nvim_buf_set_text(buf, start_row, start_col, end_row, end_col, escaped_lines)
    vim.api.nvim_feedkeys(vim.keycode("<esc>"), "x", false)
    -- vim.api.nvim_win_set_cursor(0, {start_row + #swapped_lines, swapped_lines[#swapped_lines]:len() - 1})
    vim.api.nvim_win_set_cursor(0, {start_row, start_col})
end

function m.unescape_sel()
    local sel = h.get_selection()
    if sel == nil then
        vim.api.nvim_feedkeys(vim.keycode("<esc>"), "x", false)
        return
    end

    ---[[@as table]]
    local text = sel.text
    ---@type string[]
    local unescaped_lines = {}

    vim.notify("text="..vim.inspect(text))
    for _, line in ipairs(text) do
        local unescaped = esc.unescape_line(line)
        if unescaped == nil then
            vim.api.nvim_feedkeys(vim.keycode("<esc>"), "x", false)
            return
        end
        table.insert(unescaped_lines, unescaped)
    end

    vim.notify("unescaped="..vim.inspect(unescaped_lines))
    local buf = 0-- sel.reg[1][1][1] - 1
    local start_row = sel.reg[1][1][2] - 1
    local start_col = sel.reg[1][1][3] - 1
    local end_row = sel.reg[#sel.reg][2][2] - 1
    local end_col = sel.reg[#sel.reg][2][3]
    vim.api.nvim_buf_set_text(buf, start_row, start_col, end_row, end_col, unescaped_lines)
    vim.api.nvim_feedkeys(vim.keycode("<esc>"), "x", false)
    -- vim.api.nvim_win_set_cursor(0, {start_row + #swapped_lines, swapped_lines[#swapped_lines]:len() - 1})
    vim.api.nvim_win_set_cursor(0, {start_row, start_col})
end

function m.hex_of_string()
    -- TODO - maybe a first shot at a function that works both in normal mode with what's under the cursor and in visual
end

-- setup function
---@param opts HexfmtOpts
function m.setup(opts)
    if not vim.g.hexfmt_nvim_loaded then
        vim.g.hexfmt_nvim_loaded = true

        -- Create the swap_endianness command
        vim.api.nvim_create_user_command("SwapEndianness", m.swap_endianness, {})

        -- Set up a key mapping: use opts.keymap if provided
        local keymap = opts.keymap
        vim.keymap.set("x", keymap.swap_endianness or "<Plug>(HexfmtSwapEndianness)" , m.swap_endianness, {desc="Swap endianness", silent=true})
        vim.keymap.set("x", keymap.escape or "<Plug>(HexfmtEscape)" , m.escape_sel, {desc="Escape hex sequence", silent=true})
        vim.keymap.set("x", keymap.unescape or "<Plug>(HexfmtUnescape)" , m.unescape_sel, {desc="Unescape hex sequence", silent=true})
        vim.keymap.set({"n","x"}, keymap.tweak_settings or "<Plug>(HexfmtTweakSettings)" , conf.tweak_settings, {desc="Tweak hexfmt.nvim settings", silent=true})

        return conf.setup(opts)
    end
end

return m
