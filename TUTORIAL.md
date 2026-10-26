**因为真的不想去记那些图案的名字，加上服务器常驻CC，所以就有了这个编译器**

使用本分支的前提是服务端安装 [CC:Tweaked](https://modrinth.com/mod/cc-tweaked)、[Hex Casting](https://modrinth.com/mod/hex-casting) 和 `cc_hex_plugin`。客户端按服务器要求安装前两个 mod。其中 CC:Tweaked 简称 CC。

- 下文旧称“核心端口”的地方，在本分支指 `hccConfig.lua` 中配置的邻接库存方位与槽位。配置示例：`return { inventoryName = "top", slot = 1 }`。支持 `top`、`bottom`、`front`、`back`、`left`、`right`，槽位从 1 开始，目标槽位应放入可写 Iota 的物品。当前版本暂不支持有线网络库存名称。
- 如果没有特别说明，那么一切操作都是在 CC 的计算机中进行的，

# 下载器

更简便的离线安装方式：只传输 `HCCInstaller.lua`，在电脑根目录运行 `HCCInstaller`。脚本会解压并安装全部运行文件，保留已有 `hexMap`、`hccConfig.lua` 和 `startup.lua`，不需要启用 HTTP。首次安装后编辑 `hccConfig.lua`，必要时重启电脑以加载命令补全。

`HCCDownloader.lua` 下载本分支的程序文件，包括 `hex.lua`、`hexMap`、`iotaTools.lua`、`iotaBridge.lua`、`hccConfig.lua`、`hedit.lua` 和 `startup.lua`。
只需要下载下来运行它一次即可；若本地已有 `hexMap` 或 `hccConfig.lua`，下载器不会覆盖，其他文件会更新。

# 程序说明

## hexMap

hexMap 相当于一个库，用于存储多个文件可能需要公用的部份，我提供的只是示范映射，具体映射需要自己去实现，毕竟命名规则各有不同

- `genRegex` 用来生成整行匹配语义的正则表达式框架
- `preMap` 用来匹配预编译参数，函数定义，包含等
- `hexMap` 用来存储图案的映射
- `rawMap` 用来存储原始iota的映射

其中特殊字符的部分，需要用来做一些特殊处理，不能修改
特殊字符
```lua
    ["{"] = "qqq",
    ["}"] = "eee",
    ["+"] = "waaw",
    ["-"] = "wddw",
    ["*"] = "waqaw",
    ["/"] = "wdedw",
```
## hex.lua

编译器本体，使用方式为：`hex <文件名>`

编译结果会写入 `hccConfig.lua` 指定的库存外设槽位中的 Iota 物品。

## hedit.lua

为该编译器调整的cc文本编辑器，使用方式为：`hedit <文件名>`

可以提供对应关键字的高亮，以及 `rawMap` 和 `hexMap` 的关键字补全
当配置的库存外设可用时，按下 Ctrl 后选项中会出现 `Compile`；选择确认后会将编辑器打开的代码编译并写入配置的槽位。

## iotaTools

用来辅助操作hexMap的四合一工具  使用方法：`iotaTools <命令> [参数1,参数2,..]`  

可选命令：
- `toStr`：将配置槽位中的 Iota 转为字符串并保存至 `_toStr_out` 文件
- `dec`：根据 `hexMap` 对配置槽位中的 Iota 列表进行反编译，支持图案、数字、矢量、布尔值、空值、垃圾值和嵌套列表，结果存入 `_dec_out` 文件。未收录的非东向图案需要先通过 `append raw` 加入 `rawMap`
- `append`：用来为 `hexMap` 插入新数据的工具
	- 如果不带参数使用，那么配置槽位中的 Iota 需要是图案或图案列表；未映射的图案会弹出输入界面，按列表顺序输入键名后插入到 `hexMap` 顶部
	- 如果 `参数1` 是 `pattern`，那么和无参数一样
	- 如果 `参数1` 是 `raw` 且没有 `参数2`，将整个 Iota 作为一项加入 `rawMap`
	- 如果 `参数1` 是 `raw` 且 `参数2` 是 `list`，将列表中的 Iota 逐项加入 `rawMap`
- `view` : `参数1` 需要输入 `hexMap` 中存在键值，会在屏幕上反复绘制图案以让用户检查具体是什么图案或者画法，按下 `R` 可以立即重绘， 方向键可以移动相机位置，`pgDown` 缩小图像尺寸，`pgUp`放达图像尺寸，`Q`结束绘制

## startup.lua

初始化程序参数智能补全的脚本，可以加入到任何 `startup` 中

# 编程语法

## 规范

每行只能写一个语义，注释除外

比如一个简单的推进法术：
**正确写法**:
```hex
me
2
boost
```
**错误写法**:
```hex
me 2 boost
```

## 列表

### 单纯图案绘制版列表
在hexMap中，已经预设了内省和反思的图案，分别对应的关键字是 `{ 和 }`
如果代码中这么写，相当于运行的时候重新绘制了列表
```hex
me
{
	me
	pos
}
```
也就是说编译出来的是一个图案列表 ： `[自我, 内省, 自我, 指南针, 反思]`
对于需要制作法术环但是不想加入核心之类的时候，可以这么使用，但是可读性差，而且对于需要转义的场合，会导致需要绘制的考察数量指数型上升，所以不建议使用该方法制作列表

### 真实列表
真实列表，编译出来的就是实际列表，而不是加入反思和内省，对于嵌套的部分，会自动加入考察
真实列表的关键字是 `[ 和 ]`
```hex
me
[
	me
	[
		pos
	]
]
```
编译出来的结果就是：`[自我,[自我,考察,[指南针]]]`
那么这样做可读性高，内部需要转义的时候也不需要绘制指数多个考察

## 图案 Iota

图案就是 `hexMap` 中所记录的映射值，其中每个映射的键，就是编程所使用的编码

如果 `hexMap` 中有:
```lua
hexMap = {
    ["me"] = "qaq",
    ["pos"] = "aa",
    ["sight"] = "wa",
    ["rayCast_getEntity"] = "weaqa",
    ["rayCast_getBlock"] = "wqaawdd",
    ["rayCast_getBlockRule"] = "weddwaa",
}
```
那么就可以在代码中使用这些键值进行编码

获取玩家视线指向的实体：
```r
me
pos
me
sight
rayCast_getEntity 
```
如果使用 `hexMap` 中不存在的键，那么编译就会报错

如果编译成功，对应关键字会被替换成图案 Iota，随后写入配置的库存槽位。下面的一些语法也采用类似的图案替换逻辑。

### 图案版数字

图案数字使用只需要直接输入数字就可以，不支持小数，但是支持负数
图案版数字的写法：
```r
1
20
-105
```

通过堆栈式的十进制遍历每一位来生成计算图案列表，如果数字位数为 N > 1，图案列表
长度为 4(N-1) + 2, N = 1 时长度为 1


## 非图案 Iota
非图案Iota，比如数字，列表，等不是图案的Iota，如果放在图案列表中运行，是不能直接绘制出来的，需要增加转义符，所有非图案的格式都是 `%关键字` 或者 `%%关键字`

其中**一个** `%` 会自动添加考察转义，**两个** `%` 会保留原始Iota转态压入列表

### 数字iota

数字 iota 只需要在数字前加入 `%` 即可， 支持正负与小数

数字iota的写法：
```r
%1
%-12
%-234.4
%%-222
```

### 矢量Iota

矢量Iota 会向列表中压入一个矢量

矢量Iota的写法
```r
%(1,2,3)
%%(-12,2.55,9000)
```

### 原始Iota

原始 Iota 就是将Iota不做任何处理映射原始保留的放入栈中，类似 图案，原始 Iota 的映射关系存储在 `rawMap` 中

通过 `%键名` 可以调用对应的原始Iota

单个 `%` 会在原始 Iota 前加入转义图案；`%%` 只插入原始 Iota，不加入转义。数字、矢量还可直接写成 `%1.25`、`%(1,2,3)`，布尔值和空值可写成 `%true`、`%false`、`%null`、`%garbage`。列表直接用 `[` 和 `]` 表示，编译器会在列表前自动加入转义图案。若读到的嵌套列表原本没有前置转义图案，为保持原数据不变，`dec` 会使用现有的 `rawMap` 别名；没有对应别名时会报错，需先用 `append raw` 加入。

如果 `rawMap` 中有
```lua
rawMap = { 
    ["demopos_"] = {["y"]=68.620000004768,["x"]=-89.37155533412,["z"]=-185.44644438205},
}
```

那么就可以在代码中直接调用这个原始Iota

```r
%demopos_
```

## 注释

注释所在的后面任何代码都不会被编译

注释可以是整行注释，也可以注释在代码行后面，关键字是 #

用注释来标注的代码：
```r
me
pos
me
sight # 栈顶应该有玩家坐标和视线矢量
rayCast_getBlock
dig 
# 当前栈顶应该是空栈
# explosion # 不应该在这里使用爆炸
```

## 函数
函数在文件中定义，类似 C 的宏定义替换。定义函数以 _**@func 函数名(参数1, 参数2...)**_ 开始，以 _**@end**_ 结束。

其中参数在函数体内通过 **$参数名** 来使用， 形参会被直接替换为实参，支持函数嵌套

调用时，使用 **函数名(实参1, 实参2....)** 来实现函数调用。如果要调用函数，需要保证函数的定义在调用之前。

### 无参函数定义和调用
```r
# 定义一个无参函数
@func getblockpos()
    me
    pos
    me
    sight
    rayCast_getBlock # 获取玩家视线指向的方块
@end
 
# 调用一个无参函数
get_sightCastBlock()
```

### 带参数的函数定义和调用
```r
# 读取渡鸦中列表的指定元素
@func getmem(index)
    readFmem
    $index # 调用参数位置
    listSelect
@end
# 求和
@func sum(a, b)
    a
    b
    +
@end
 
getmem(2)
getmem(sum(1,2)) # 嵌套使用
```

## 库和包含

库用于复用函数，库是函数的集合，是一种特殊的文件，与普通文件相比，就是只有函数定义，没有其他普通代码，一个文件中不允许出现在函数体之外的代码，否则会解析不正常。使用 **_@include 文件路径_** 关键字来导入包。

这里提供一个示范，将函数写在 `tools.hex` 中，但是在 `tst.hex` 中去调用该函数

tools.hex
```r
# 在包中定义函数
@func getblockpos()
    me
    pos
    me
    sight
    rayCast_getBlock
@end
 
@func getblockrule()
    me
    pos
    me
    sight
    rayCast_getBlockRule
@end
```

tst.hex
```r
# 导入包
@include tools.hex
 
# 直接调用包中函数
getblockpos()
getblockrule()
```

## 样例
`test` 目录中，有两份代码和一个 `hexMap` 文件，如果需要使用那两份文件进行测试，只需要把 `test` 目录中的 `hexMap` 替换到本地后，直接编译对应文件即可
# VSCode 插件
[HexCast Compiler Support - Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=Lanzr.hexcast-compiler-support)

专门提供该编译器使用的插件，需要将 `hexMap` 放在工作目录根目录下，会为 `.hex` 结尾的文件提供代码补全，高亮等功能，且会自动识别库或者本地的函数名以自动补全
