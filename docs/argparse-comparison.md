# MoonArgv 与标准库 `argparse` 的区别

两者位于命令行处理链的不同层级，可以组合使用，不是重复实现：

| 对比项 | MoonArgv | `moonbitlang/core/argparse` |
| --- | --- | --- |
| 输入 | 一段仍含引号与转义的命令字符串，或待序列化的逻辑参数数组 | 已由操作系统或上游组件切分好的 `Array[String]`，以及环境变量映射 |
| 主要职责 | 按 POSIX / Windows CRT 规则恢复参数边界，并安全、可逆地生成命令字符串 | 按命令声明解释 flag、option、位置参数和子命令 |
| 输出 | 含源码范围的 `ArgToken`、程序名与 argv 尾部，或命令字符串 | `Matches`：选项值、flag 状态、来源和子命令结果 |
| 处理的错误 | 未闭合引号、末尾转义、参数数量或长度超限 | 未知选项、缺少必填值、参数冲突、命令定义错误 |
| 明确不做 | 不识别 `--flag` 语义，不生成帮助，不读取 env/default，不做子命令分派 | 不负责解释 POSIX/Windows 命令字符串的引号与反斜杠，也不提供跨平台 argv 反向引用 |

标准库接口 `Command::parse(argv=...)` 的输入已经是参数数组。例如，配置文件中的：

```text
deploy --target 'staging cluster' --verbose
```

先由 MoonArgv 恢复为程序名 `deploy` 和 argv 尾部
`["--target", "staging cluster", "--verbose"]`，再把尾部交给
`argparse`，由后者识别 `target` 与 `verbose`。反向生成仅接受单字符串的进程接口时，则继续由 MoonArgv 保证 POSIX / Windows 参数边界可逆。

可运行代码见 [`examples/argparse_pipeline`](../examples/argparse_pipeline)。该示例及测试同时验证：MoonArgv 保留带空格的引号值，标准库 `argparse` 负责必填选项校验。
