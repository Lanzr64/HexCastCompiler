# HexCastCompiler
English | [Chinese](README.md)

a  compiler for Minecraft mod Ducky periperals and hex casting, use in game

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
    - `toStr`:  get `focal_port` iota to string and save in `data` file
    - `dec`:  get `focal_port` iota and decompile code based on hexMap and store it in `dec_out` file 
    - `append`:  get `focal_port` iota and Generate mappings that are not included in the `hexMap`, store the results in a `newHexMap` file, and if append parameter `overWrite`, the `hexMap` will be overwritten
   
5. startup.lua
   the initial script in cc computer lanuch,and provide param completion


## test
    provides my test hexmap mapping table and two test spells
