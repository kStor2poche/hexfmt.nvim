# hexfmt.nvim

Ça formatte de l'hexadecimal dans nvim. Bon voilà...

## Features

### ✨ escape/unescape hex string ✨
> 0x12345678 <-> \x12\x34\x56\x78
> \x12\x34\x56\x78 <-> 0x12345678

### ✨ swap endianness ✨
> with vim.g.hexfmt\_word\_size=4:
> 0x0123456789abcdef <-> 0x67452301efcdab89

> with vim.g.hexfmt\_word\_size=8:
> 0x0123456789abcdef <-> 0xefcdab8967452301

> with vim.g.hexfmt\_word\_size=3 and vim.g.hexfmt\_pad\_incomplete\_words=false:
> 0x0123456789 <-> 0x4523018967

> with vim.g.hexfmt\_word\_size=3 and vim.g.hexfmt\_pad\_incomplete\_words=true:
> 0x0123456789 --> 0x452301008967 <-> 0x012345678900

> and all of that also works on escaped hex strings:
> \x01\x23\x45\x67\x89\xab\xcd\xef <-> \x67\x45\x23\x01\xef\xcd\xab\x89

### ✨ fancy ui to adjust session settings ✨
> with `<Plug>HexfmtTweakSettings` or `:HexfmtTweakSettings` (latter is TODO)

## Roadmap
- add option for padding incomplete words when swapping endionness
- visual-line & visual-block support
- commands for all the `<Plug>` keybinds
- make it so that the keybind for `tweak\_settings`, if triggered in visual, restores the selection after it has been used
- ~~simply ignore stuff that's not correct hex rather throwing an error~~ &rarr; we \xcannot r\xeally guess what is hex and what isn't in an unesscaped hexstring so this is a no go &rarr; or at least we could do it for mixed escaped strings which could have its use (which entails converting non escaped ascii chars to hex (probably with utf-8 by default? or utf-8 only (the more I think about it the more it looks cumbersome to do in a minimalist language such as lua)))
    - though having a utility to turn the char under the cursor into its hex representation would also be cool and kinda in the scope of this plugin :3
- maybe separate validation and initialization steps
- find a way to do lazy loading (according to the lazy.nvim spec?) &rarr; at least only expose functions through nvim commands and/or 
- luarocks release??? (least important)
