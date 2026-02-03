# HexCastCompiler
Chinese | [Engligh](README_EN.md)

一个用于Minecraft模组Ducky periperals和Hex Casting的编译器，可在游戏内使用。

## 快速入门
[点此查看教程](TUTORIAL.md)

## 文件说明

1. hexMap  
   编译器核心映射表，需完成hexMap映射后方可使用。

2. hex.lua  
   编译器脚本  
   使用方法：`hex <法术文件>`

3. hedit.lua  
   游戏内编辑器，用于编辑hex文件（即基于hexMap使用的代码）

4. iotaTools.lua  
   用于辅助完善hexMap和反编译的工具  
   使用方法：`iotaTools <命令> [参数]`  
   命令可选：  
   - `toStr`：将 `focal_port` 中的 iota 转为字符串并保存至 `data` 文件  
   - `dec`：根据hexMap对 `focal_port` 的 iota 进行反编译，结果存入 `dec_out` 文件  
   - `append`：获取 `focal_port` 的 iota，并生成 `hexMap` 中未包含的映射，结果保存于 `newHexMap` 文件；若附带参数 `overWrite`，则会覆盖原有 `hexMap`

5. startup.lua  
   在CC电脑启动时执行的初始化脚本，提供参数自动补全功能

## 测试内容  
   提供我的测试hexMap映射表及两个测试法术

## vscode 语法支持插件
[HexCast Compiler Support - Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=Lanzr.hexcast-compiler-support)
