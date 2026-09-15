# MoonArgv 兼容边界

## P0 必须兼容

### POSIX 词法方言

- 将空格、制表符、换行和回车作为参数分隔符；
- 支持单引号、双引号、反斜杠转义、引号片段拼接和空参数；
- 双引号内仅对 `"`、`\\`、`$`、反引号和换行执行反斜杠转义；
- 未闭合单双引号、末尾孤立反斜杠必须返回类型化错误和字符偏移；
- `parse(join(argv, Posix), Posix)` 必须恢复原 argv。

这里的 POSIX 模式是面向配置文本和响应文件的 quoting 词法子集，不是 shell 解释器。

### Windows CRT 词法方言

- 空格和制表符在引号外分隔参数，双引号保护其中空白；
- 双引号前连续反斜杠按 Microsoft CRT 奇偶规则处理；
- 普通路径反斜杠和带空格路径末尾反斜杠必须无损；
- 未闭合末尾双引号按 CRT 常规参数行为接收到行尾；
- `parse(join(argv, Windows), Windows)` 必须恢复原 argv；
- Microsoft 文档给出的 5 组常规参数示例必须逐项一致。

## P0 响应文件和集成

- `@path` 按调用方选择的 POSIX 或 Windows 方言展开，保持参数顺序；
- `@@name` 产生字面量 `@name`；嵌套、缺失、循环、深度及最终参数上限均有确定行为；
- 命令超过阈值时，`plan_invocation` 返回 `[program, @path]` 和可写入的响应文件内容；内容再次展开必须等于原始参数；
- `parse_command_line` 将程序名与 argv 尾部分离，尾部可直接传给标准库 `argparse`。

## 明确不兼容或不承诺

- 不执行变量、波浪号、通配符、命令替换、管道、重定向、here-document 或注释语义；
- 不模拟 `cmd.exe`、PowerShell 或完整 POSIX shell；字符 `|;&<>` 在本库中只是普通参数字符；
- Windows 模式实现 Microsoft CRT 常规参数规则，不承诺 `CommandLineToArgvW` 的不同规则，也不单独模拟 CRT 对 `argv[0]` 的历史特例；
- 响应文件的磁盘 IO、字符编码、BOM 和各编译器私有选项由宿主适配层决定；核心库只处理调用方提供的文本；
- 不解析 option/flag/subcommand 业务语义，该职责属于标准库 `argparse`。

公共兼容行为由 [`ACCEPTANCE_CRITERIA.md`](ACCEPTANCE_CRITERIA.md) 锁定；超出 P0 的行为不能作为兼容承诺。
