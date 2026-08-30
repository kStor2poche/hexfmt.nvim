local m = {}

---@type HexfmtOpts
m.config = {
    default_word_size = 8,
    default_casing = "conserve",
    default_prefix_on_unescape = true,
    default_pad_incomplete_words = true,
    keymap = {
    },
}

---@alias HexfmtOpts {
    ---default_word_size: integer,
    ---default_casing: "lower"|"upper"|"conserve",
    ---default_prefix_on_unescape: boolean,
    ---default_pad_incomplete_words: boolean,
    ---keymap: {
        ---generate_linewise_bindings: boolean,
        ---swap_endianness: string,
        ---escape: string,
        ---unescape: string,
        ---tweak_settings: string,
        ---hex_encode: string,
    ---},
---}
---Sets up the plugin
---@param opts HexfmtOpts
---@return nil
function m.setup(opts)
    -- Merge user opts w/ defaults
    opts = opts or {}

    -- Validate the config
    vim.validate("keymap.swap_endianness", opts.keymap.swap_endianness, "string", true, "string")
    vim.validate("keymap.escape", opts.keymap.escape, "string", true, "string")
    vim.validate("keymap.unescape", opts.keymap.unescape, "string", true, "string")
    vim.validate("keymap.tweak_settings", opts.keymap.tweak_settings, "string", true, "string")
    vim.validate("word_size",
        opts.default_word_size,
        function(w) return type(w) == "number" and w >= 2 end,
        true,
        "number"
    )
    vim.validate("casing",
        opts.default_casing,
        function(c) return c == "lower" or c == "upper" or c == "conserve" end,
        true,
        "\"lower\" or \"upper\" or \"conserve\""
    )
    vim.validate("prefix_on_unescape", opts.default_prefix_on_unescape, "boolean", true, "boolean")
    vim.validate("pad_incomplete_words", opts.default_pad_incomplete_words, "boolean", true, "boolean")

    -- Setup config
    m.config = vim.tbl_extend('force', m.config, opts)
    vim.g.hexfmt_word_size = m.config.default_word_size
    vim.g.hexfmt_casing = m.config.default_casing
    vim.g.hexfmt_prefix_on_unescape = m.config.default_prefix_on_unescape
    vim.g.hexfmt_pad_incomplete_words = m.config.default_pad_incomplete_words
end

---Tweaks hexfmt.nvim settings
---TODO: separate into separate functions with associated commands/keybinds
function m.tweak_settings()
    local choices = {
        "Select word size (current = "..vim.g.hexfmt_word_size..")", -- int
        "Select casing (current = "..vim.g.hexfmt_casing..")", -- "lower"|"upper"|"conserve",
        "Toggle prepend `0x` on unescape (current = "..vim.inspect(vim.g.hexfmt_prefix_on_unescape)..")", -- bool
        "Toggle pad incomplete words (current = "..vim.inspect(vim.g.hexfmt_pad_incomplete_words)..")", -- bool
    }
    vim.ui.select(choices,
    {
        prompt = "Which setting do you want to change for this session?"
    },
    function(choice)
        if choice == choices[1] then
            -- Word size
            vim.ui.input(
                {prompt="Set word size (vim.g.hexfmt_word_size)"},
                function (input)
                    local parsed = tonumber(input)
                    if parsed == nil then
                        vim.notify("Invalid value. Word size, should be an integer >= 2", 4)
                        return
                    end
                    if parsed < 2 then
                        vim.notify("Invalid value. Word size, should be an integer >= 2", 4)
                        return
                    end
                    vim.g.hexfmt_word_size = parsed
                end
        )
        elseif choice == choices[2] then
            -- casing
            local casing_choices = {"lower", "upper", "conserve"}
            vim.ui.select(casing_choices,
                { prompt = "Set output casing" },
                function(casing_choice)
                    if casing_choice ~= nil then
                        vim.g.hexfmt_casing = casing_choice
                    end
                end
            )
        elseif choice == choices[3] then
            vim.g.hexfmt_prefix_on_unescape = not vim.g.hexfmt_prefix_on_unescape
        elseif choice == choices[4] then
            vim.g.hexfmt_pad_incomplete_words = not vim.g.hexfmt_pad_incomplete_words
        end

    end
)
end

return m
