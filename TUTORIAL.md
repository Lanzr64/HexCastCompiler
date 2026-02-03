**因为真的不想去记那些图案的名字，加上服务器常驻CC，所以就有了这个编译器**

使用该编译器的前提是，需要安装 [cc:tweak](https://modrinth.com/mod/cc-tweaked) 和 [hexCasting](https://modrinth.com/mod/hex-casting) 以及 [ducky-periphs](https://modrinth.com/mod/ducky-periphs) 三个mod，其中 `cc:tweak` 这个mod，简称 CC

- 下文中，如果提到核心端口，那么指的就是 `ducky-periphs` 中的 `focal port` 方块
- 如果没有特别说明，那么一切操作都是在 CC 的计算机中进行的，

# 下载器

`HCCDownloader.lua` 可以直接下载github上最新的程序文件，包括 `hex.lua`, `hexMap`,`iotaTools`, `hedit.lua` `startup.lua`。
只需要下载下来运行它一次即可，它会检查本地有没有 `hexMap` 文件，如果有则不会下载 `hexMap`，但是其他文件不会进行类似检查

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

如果有核心端口连接至此计算机，那么编译结果会输入到核心端口中的核心之中

## hedit.lua

为该编译器调整的cc文本编辑器，使用方式为：`hedit <文件名>`

可以提供对应关键字的高亮，以及 `rawMap` 和 `hexMap` 的关键字补全
如果有核心端口连接至此计算机那么按下ctrl后，选项中会出现 `Compile`，选择确认会将编辑器打开的代码编译入核心端口中的核心之中

## iotaTools

用来辅助操作hexMap的四合一工具  使用方法：`iotaTools <命令> [参数1,参数2,..]`  

可选命令：
- `toStr`：将 核心端口 中的 iota 转为字符串并保存至 `_toStr_out` 文件  
- `dec`：根据 `hexMap` 对 核心端口 的 iota 进行反编译，结果存入 `_dec_out` 文件  
- `append`：用来为 `hexMap` 插入新数据的工具
	- 如果不带参数使用，那么需要 核心端口 中是图案，或者图案列表，不能有其他的iota，会将 `hexMap` 中没有的映射记录，随后弹出ui，根据核心中列表的顺序依此让你输入你希望的键名，输入完成后会插入到 `hexMap` 的最上面
	- 如果 `参数1` 是 `pattern`，那么和无参数一样
	- 如果 `参数1` 是 `raw` 且没有 `参数2` ，那么会将核心中的 iota 认为是一整个iota，将会弹出ui，让你输入你希望的键名，输入完成后会插入到 `rawMap` 的最上面
	- 如果 `参数1` 是 `raw` 且 `参数2` 是 `list` ,那么会将核心中的 iota 认为是iota列表，将会弹出ui，根据核心中列表的顺序依此依此让你输入你希望的键名，输入完成后会插入到 `rawMap` 的最上面
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

## 图案

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

如果编译成功，那么对应的关键字就会被替换成对应的图案Iota，随后存入核心端口中的核心中。下面的一些语法的运行逻辑也类似图案的替换逻辑

## 数字

数字有两种类型，纯图案，和数字iota

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

### 数字iota

数字iota比较特殊，因为如果希望写一个法术但是又不想压入一堆图案，就可以使用数字iota

数字 iota 只需要在数字前加入 `\` 即可， 支持正负与小数

数字iota的写法：
```r
\1
\-12
\-234.4
```

如果需要确保在图案列表中也一定可以正常运行，可以使用 `\\`，这样如果写入位置在列表中，会自动添加一个考察

比如:
```r
\\1
\\-12
\\-245.5
# 上面的三个 等效于单 \ 加数字
{
	\\12
	# 这个12 等效于单 \ 加数字前面还加了个考察
}
```

## 原始Iota

原始 Iota 就是将Iota不做任何处理映射原始保留的放入栈中，类似 图案，原始 Iota 的映射关系存储在 `rawMap` 中

通过 `%键名` 可以调用对应的原始Iota

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
@include tools
 
# 直接调用包中函数
getblockpos()
getblockrule()
```

## 样例
`test` 目录中，有两份代码和一个 `hexMap` 文件，如果需要使用那两份文件进行测试，只需要把 `test` 目录中的 `hexMap` 替换到本地后，直接编译对应文件即可
# VSCode 插件
[HexCast Compiler Support - Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=Lanzr.hexcast-compiler-support)

专门提供该编译器使用的插件，需要将 `hexMap` 放在工作目录根目录下，会为 `.hex` 结尾的文件提供代码补全，高亮等功能，且会自动识别库或者本地的函数名以自动补全
