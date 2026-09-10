# Mooncakes 生态查重记录

查重日期：2026-09-10

数据源：https://mooncakes.io/api/v0/modules

扫描范围：接口返回的全部 2,392 个公开模块，检索模块名称、简介和关键词；另复核 2026-09-07 之后新增的 177 个模块。

## 检索词

精确名称检索：`moonargv`、`argvkit`、`moonshlex`、`shlex`、`shellwords`。

功能检索：`argv`、`command line tokenizer`、`command-line tokenizer`、`shell lexer`、`shell quoting`、`POSIX quoting`、`Windows command line`、`Windows argv`、`command builder`。精确名称和核心功能组合均无命中。

## 相关但不重复的项目

| 项目 | 已有定位 | 与 MoonArgv 的边界 |
| --- | --- | --- |
| `DzmingLi/clap`、`Yoorkin/ArgParser`、`Milky2018/options`、`dowdiness/margs`、`cauchyQ/moonbit-argkit` | 从现成 argv 解析 flag、option 和子命令 | 不负责单个命令字符串与 argv 之间的跨平台可逆转换 |
| [bobzhang/myshell](https://mooncakes.io/docs/bobzhang/myshell) | shell-free 进程 EDSL | 负责进程组合；MoonArgv 是无 IO、跨后端的词法与序列化层 |
| [mizchi/moon-install](https://mooncakes.io/docs/mizchi/moon-install) | MoonBit CLI 安装器，内部提供 `shell_escape`、`shell_join` | 面向自身的 POSIX 输出辅助，没有公开声明 Windows CRT 解析、源码范围或资源限制 |
| `mizchi/bit_utils` | Git 实现中的字符串和引用工具 | Git 内部通用工具，不是独立的双向跨平台 argv 库 |
| [Haoxincode/moonbash](https://mooncakes.io/docs/Haoxincode/moonbash) | 纯内存 POSIX shell 沙箱 | 会解析并执行完整 shell；MoonArgv 不执行命令，并额外覆盖 Windows CRT |
| `moonbit-community/proton_process`、`trkbt10/subprocess` | 原生子进程启动与管理 | 可消费 MoonArgv 生成的 argv，职责互补 |

## 与 MoonBit 标准库 `argparse` 的边界

标准库 `moonbitlang/core/argparse` 不属于 Mooncakes 第三方模块，但属于必须披露的相邻能力。其 `Command::parse(argv=..., env=...)` 从已切分的 `Array[String]` 开始，解释 flag、option、位置参数、子命令、env/default、帮助及约束，输出 `Matches`。MoonArgv 从单个 POSIX/Windows 命令字符串恢复 argv，或把 argv 可逆地引用为字符串；不解释 CLI 业务语义。两者的组合与 API 级对照见 [`argparse-comparison.md`](argparse-comparison.md)，仓库提供可运行的集成示例。

## 结论

截至查重时间，Mooncakes 没有与 MoonArgv 同名的包，也没有同时提供 POSIX 与 Windows 两套命令行分词、可逆引用、源码位置和输入限制的项目。相邻第三方项目及标准库 `argparse` 已在申报书中披露。本结论仅对应 2026-09-10 的公开模块状态，正式提交和发布前仍应再次全量复核。
