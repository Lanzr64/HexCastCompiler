# HexCastCompiler
Chinese | [Engligh](README_EN.md)

一个在 CC:Tweaked 中运行的 Hex Casting 编译器。本分支使用服务端 `cc_hex_plugin` 的全局 `hexIota` API，读写库存外设指定槽位内的 Iota 物品，无需 Ducky Peripherals 的 focal port。

服务端需要 CC:Tweaked、Hex Casting 和 `cc_hex_plugin` 1.0.1 或更新版本；客户端按服务器要求安装 CC:Tweaked 与 Hex Casting。编辑 `hccConfig.lua`，将 `inventoryName` 设为紧邻电脑的方位名，将 `slot` 设为目标物品的槽位（从 1 开始）。当前支持 `top`、`bottom`、`front`、`back`、`left`、`right`；有线网络的库存名称暂不支持。例如：

```lua
return { inventoryName = "top", slot = 1 }
```

目标槽位必须有可写 Iota 的物品。空槽、错误物品、只读库存等情况会由 `hexIota` 返回错误。写入支持图案、数字、布尔、向量及其列表，和 mod 的安全类型限制一致。

## 单文件离线安装

只需将 [HCCInstaller.lua](HCCInstaller.lua) 传入 CC 电脑，在电脑根目录运行：

```lua
HCCInstaller
```

安装器已内嵌 `hex.lua`、`hex_old.lua`、`hedit.lua`、`iotaTools.lua`、`iotaDecompiler.lua`、`iotaBridge.lua`、`hexMap`、`hccConfig.lua` 和 `startup.lua`，运行时无需 HTTP。也可用 `HCCInstaller <目录>` 指定安装目录。已有的 `hexMap`、`hccConfig.lua` 和 `startup.lua` 会保留；其他同名文件若需要更新，旧版会保存为 `.hcc-backup` 文件。首次安装 `startup.lua` 后重启电脑可启用命令补全；若电脑原本已有 `startup.lua`，安装器不会修改它。

修改运行文件后，可在开发机执行 `node tools/build-installer.js` 重新生成安装器。

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
   - `toStr`：将配置的库存槽位中的 Iota 转为字符串并保存至 `_toStr_out` 文件
   - `dec`：根据 hexMap 对该槽位中的 Iota 列表进行反编译，支持图案、数字、矢量、布尔值、空值、垃圾值和嵌套列表，结果存入 `_dec_out` 文件
   - `append`：读取该槽位中的 Iota，将新图案或原始 Iota 追加到 `hexMap`

`iotaBridge.lua` 负责 Lua Iota 与 Hex Casting SNBT 的转换；`hccConfig.lua` 保存库存外设名和槽位。下载器会下载这两个文件，且不会覆盖已有的 `hccConfig.lua`。

5. startup.lua  
   在CC电脑启动时执行的初始化脚本，提供参数自动补全功能

## 测试内容  
   提供我的测试hexMap映射表及两个测试法术

## vscode 语法支持插件
[HexCast Compiler Support - Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=Lanzr.hexcast-compiler-support)
