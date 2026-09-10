# MoonArgv 项目申报书

## 1. 项目名称与仓库

**MoonArgv——跨平台命令行分词与安全引用库**

GitHub：https://github.com/TangShiJi/moonargv

## 2. 项目简介、方向与通用性

MoonArgv 是纯 MoonBit 的开发工具基础库，在“仍含引号/转义的单个命令字符串”和“逻辑 argv 数组”之间进行确定性转换。项目分别实现 POSIX 与 Windows Microsoft CRT 规则，并提供统一 API、源码位置、结构化错误及输入上限。它不执行命令或 shell 展开，可供构建系统、任务运行器、编辑器、子进程封装和测试框架在 native、wasm-gc 后端复用。

## 3. 预期使用场景

1. **跨平台构建：** 将含空参数、中文路径、空格、引号或结尾反斜杠的 argv，按目标主机生成可无损恢复的 POSIX/Windows 命令文本。
2. **任务配置接入 CLI：** 先把 `deploy --target 'staging cluster'` 恢复为程序名与 argv 尾部，再交给标准库 `argparse` 校验 option、flag 和子命令。
3. **安全进程启动：** 用 `CommandLine` 逐项构造 argv；宿主支持数组时直接传递，仅在接口要求单字符串时按对应方言安全渲染。
4. **编辑器与测试：** 利用 `ArgToken` 范围定位未闭合引号等错误；把失败 argv 可逆写入日志并复现，对外部输入设置参数数与长度上限。

## 4. 核心功能与 MVP

已完成 POSIX 引号、转义、续行分词；Windows CRT 引号及奇偶反斜杠规则；两种方言的单参数引用与 argv 可逆序列化；`ParsedCommandLine` 程序名/参数分离；源码范围、结构化错误、资源限制及 `CommandLine` 构建器。仓库现有 17 个以上有效提交、53 项测试和可运行示例，native/wasm-gc 双后端及 Windows/Linux CI 均验证通过。

## 5. 与标准库 `argparse` 的区别

标准库 [`moonbitlang/core/argparse`](https://github.com/moonbitlang/core/tree/main/argparse) 的入口 `Command::parse(argv=...)` 接收**已经切分好的 `Array[String]`**，负责 flag、option、位置参数、子命令、env/default、帮助和业务约束；它不解释一整段 POSIX/Windows 命令文本，也不负责把 argv 跨平台反向引用。MoonArgv 位于其前后：负责引号/反斜杠词法、参数边界、字符位置与安全序列化，明确不识别 `--flag` 语义。组合流程为 `命令文本 → MoonArgv → argv → argparse → Matches`，仓库内已有组合示例和必填选项测试。因此两者职责互补，并非重复实现。

## 6. 原创性、参考来源与查重

项目为原创项目、非移植项目，未复制第三方代码，采用 MIT License；仅依据 [POSIX.1-2024](https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html) 与 [Microsoft CRT 参数解析规则](https://learn.microsoft.com/cpp/c-language/parsing-c-command-line-arguments) 独立实现。2026-09-10 全量复核 Mooncakes 2,392 个公开模块，未发现同名包或覆盖“POSIX+Windows 双向词法、源码范围、输入限制”完整边界的项目；相邻的参数解析器、进程库和 shell 项目及差异已记录于 `docs/ecosystem-audit.md`。
