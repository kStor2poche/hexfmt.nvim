local h = require("hexfmt.helpers")
local conf = require("hexfmt.config")
local esc = require("hexfmt.escape")
local swp = require("hexfmt.endianness")

local m = {}
-- TODO: déduplication du prologue des fonctions de transformation

---Swaps endianness according to `vim.g.hexfmt_word_size` and `vim.g.hexfmt_pad_incomplete_words`.
---@param motion_type OpFuncMotion
function m.swap_endianness(motion_type)
    local sel = h.get_opfunc_selection(motion_type)
    if sel == nil then
        vim.api.nvim_feedkeys(vim.keycode("<esc>"), "n", false)
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

    h.apply_changes(swapped_lines, sel, motion_type)
end

---Turns a hex selection (`0x` prefixed or not) into a sequence of `\x` prefixed bytes
---@param motion_type OpFuncMotion
function m.escape(motion_type)
    local sel = h.get_opfunc_selection(motion_type)
    if sel == nil then
        vim.api.nvim_feedkeys(vim.keycode("<esc>"), "x", false)
        return
    end

    ---[[@as table]]
    local text = sel.text
    ---@type string[]
    local escaped_lines = {}

    for _, line in ipairs(text) do
        local escaped = esc.escape_line(line)
        if escaped == nil then
            vim.api.nvim_feedkeys(vim.keycode("<esc>"), "n", false)
            return
        end
        table.insert(escaped_lines, escaped)
    end

    h.apply_changes(escaped_lines, sel, motion_type)
end

---Unescape hex string
---@param motion_type OpFuncMotion
function m.unescape(motion_type)
    local sel = h.get_opfunc_selection(motion_type)
    if sel == nil then
        vim.api.nvim_feedkeys(vim.keycode("<esc>"), "n", false)
        return
    end

    ---[[@as table]]
    local text = sel.text
    ---@type string[]
    local unescaped_lines = {}

    for _, line in ipairs(text) do
        local unescaped = esc.unescape_line(line)
        if unescaped == nil then
            vim.api.nvim_feedkeys(vim.keycode("<esc>"), "x", false)
            return
        end
        table.insert(unescaped_lines, unescaped)
    end

    h.apply_changes(unescaped_lines, sel, motion_type)
end

--- Encode string in hex -- meant to be used as an :h opfunc
---@param motion_type OpFuncMotion
function m.hex_encode(motion_type)
    local sel = h.get_opfunc_selection(motion_type)
    if sel == nil then
        vim.api.nvim_feedkeys(vim.keycode("<esc>"), "n", false)
        return
    end

    ---[[@as table]]
    local text = sel.text
    ---@type string[]
    local encoded_lines = {}

    for _, line in ipairs(text) do
        local encoded = line:to_hex()
        table.insert(encoded_lines, encoded)
    end

    local buf = 0-- selection.reg[1][1][1] - 1
    if motion_type == "block" then
        for i, subreg in ipairs(sel.reg) do
            local start_row = subreg[1][2] - 1
            local start_col = subreg[1][3] - 1
            local end_row = subreg[2][2] - 1
            local end_col = subreg[2][3]
            vim.api.nvim_buf_set_text(buf, start_row, start_col, end_row, end_col, {encoded_lines[i]})
        end
        local start_row = sel.reg[1][1][2] - 1
        local start_col = sel.reg[1][1][3] - 1
        -- vim.api.nvim_feedkeys(vim.keycode("<esc>"), "x", false) -- maybe that's the fix to the line below?
        vim.api.nvim_win_set_cursor(0, {start_row + 1, start_col}) -- FIXME: this somehow doesn't work... Except it now does ???
    else
        local start_row = sel.reg[1][1][2] - 1
        local start_col = sel.reg[1][1][3] - 1
        local end_row = sel.reg[#sel.reg][2][2] - 1
        local end_col = sel.reg[#sel.reg][2][3]
        vim.api.nvim_buf_set_text(buf, start_row, start_col, end_row, end_col, encoded_lines)
        -- vim.api.nvim_feedkeys(vim.keycode("<esc>"), "x", false) -- maybe that's the fix to the line below?
        vim.api.nvim_win_set_cursor(0, {start_row + 1, start_col}) -- FIXME: this somehow doesn't work... Except it now does ???
    end
end

-- setup function
---@param opts HexfmtOpts
function m.setup(opts)
    if not vim.g.hexfmt_nvim_loaded then
        vim.g.hexfmt_nvim_loaded = true

        -- Create the swap_endianness command ? (and others ?)
        -- vim.api.nvim_create_user_command("SwapEndianness", m.swap_endianness, {})

        -- Set up a key mapping: use opts.keymap if provided
        local keymap = opts.keymap
        local linewise = opts.keymap.generate_linewise_bindings

        h.setup_opfunc_bind(keymap.swap_endianness, "HexfmtSwapEndianness", "swap_endianness", "Swap endianness", linewise)

        h.setup_opfunc_bind(keymap.hex_encode, "HexfmtEncode", "hex_encode", "Encode string into hex sequence", linewise)

        h.setup_opfunc_bind(keymap.escape, "HexfmtEscape", "escape", "Escape hex sequence", linewise)
        h.setup_opfunc_bind(keymap.unescape, "HexfmtUnescape", "unescape", "Unescape hex sequence", linewise)

        vim.keymap.set({"n", "x"}, keymap.tweak_settings or "<Plug>(HexfmtTweakSettings)" , conf.tweak_settings, {desc="Tweak hexfmt.nvim settings", silent=true})

        return conf.setup(opts)
    end
end

return m
