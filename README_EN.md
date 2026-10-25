# HexCastCompiler
English | [Chinese](README.md)

An in-game Hex Casting compiler for CC:Tweaked. This branch uses the server-side `cc_hex_plugin` global `hexIota` API to read and write an Iota item in a named inventory peripheral. It does not require Ducky Peripherals or a focal port.

Install CC:Tweaked, Hex Casting, and `cc_hex_plugin` 1.0.1 or newer on the server. Edit `hccConfig.lua` with a directly adjacent side (`top`, `bottom`, `front`, `back`, `left`, or `right`) and a one-based slot number. Wired network inventory names are not supported by the current bridge version:

```lua
return { inventoryName = "top", slot = 1 }
```

The slot must contain a writable Iota item. `iotaBridge.lua` converts the compiler's Lua values to Hex Casting SNBT. The downloader preserves an existing `hccConfig.lua`.
## Quick Start
[jump to turtorial](TUTORIAL.md)

## files

1. hexMap
   the compiler core map, complete the hexMap table to use it
2. hex.lua
   the compiler
   `Usage: hex <path>`
3. hedit.lua
   the text editor for in game edit hex code(hex code is code that use hexMap)
4. iotaTools.lua
   the helpful tool for complete hexMap and decompilation
    `Usage: iotaTools <cmd> [Param]`
    cmd can be :
    - `toStr`: save the configured slot's Iota as `_toStr_out`
    - `dec`: decompile a pattern list from the configured slot to `_dec_out`
    - `append`: add patterns or raw Iotas read from the configured slot to `hexMap`
   
5. startup.lua
   the initial script in cc computer lanuch,and provide param completion


## test
   provides my test hexmap mapping table and two test spells

## vscode syntax Support extension
[HexCast Compiler Support - Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=Lanzr.hexcast-compiler-support)
