local m = {}

---Swaps endianness of an escaped hex string
---***TODO:*** fix '\x' padding when hexfmt_pad_incomplete_words is set to false
---@param s string
---@return string
function m.swap_endianness_esc_line(s)
    local word_size = vim.g.hexfmt_word_size
    local s_len = s:len()
    local swapped = ""
    if vim.g.hexfmt_pad_incomplete_words then
        for _=1, s_len % (word_size * 4) do
            s = s.."\\x00"
        end
    end

    for i=1, s_len, 4 * word_size do
        for j = 4*(word_size - 1), 0, -4 do
            swapped = swapped.."\\x"..s:sub(i+j+2, i+j+3)
        end
    end

    return swapped
end

---Swaps endianness of an unescaped hex string
---@param s string
---@param prefixed boolean
---@return string
function m.swap_endianness_unesc_line(s, prefixed)
    local word_size = vim.g.hexfmt_word_size

    if prefixed then
        s = s:sub(3)
    end

    local s_len = s:len()
    if vim.g.hexfmt_pad_incomplete_words then
        for _=1, s_len % (word_size*2) do
            s = s.."00"
        end
    end

    local swapped = ""

    for i=1, s_len, word_size * 2 do
        for j = 2*(word_size - 1), 0, -2 do
            swapped = swapped..s:sub(i+j, i+j+1)
        end
    end

    if prefixed then
        swapped = "0x"..swapped
    end

    return swapped
end

return m
