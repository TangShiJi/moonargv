# MoonArgv 项目申报书

## 基本信息

**项目名称：** MoonArgv——跨平台命令行分词与安全引用库  
**项目方向：** MoonBit 开发工具基础库 / 跨平台进程参数基础设施  
**项目性质：** 原创项目，参考公开标准独立实现，非移植项目  
**GitHub：** https://github.com/TangShiJi/moonargv

## 项目简介与通用性

MoonArgv 解决一个容易被低估的跨平台问题：构建工具或进程启动器拿到一段命令文本时，怎样准确恢复参数边界；只有单字符串接口时，又怎样把 argv 安全、可逆地表示出来。项目用纯 MoonBit 分别实现 POSIX 引号/转义规则和 Windows Microsoft CRT 反斜杠/双引号规则，并提供统一 API、源码位置和输入上限。它不做业务选项解析，不执行 shell，也不展开变量、管道或重定向，因此可以作为构建系统、任务运行器、子进程库和测试工具的通用底层组件，在 native 与 wasm-gc 后端复用。

## 预期使用场景

1. **跨平台构建工具：** 构建描述保存逻辑参数数组，MoonArgv 按运行主机生成 POSIX 或 Windows 命令文本；包含空参数、中文路径、空格、引号和结尾反斜杠时仍可无损恢复。
2. **进程启动与任务编排：** 调用方通过 `CommandLine` 逐项加入程序和参数，直接把 `argv()` 交给子进程 API；若平台只接受单字符串，再使用对应方言的 `render`，避免手工拼接破坏参数边界。
3. **编辑器与测试框架：** 编辑器解析用户填写的运行配置，通过 `ArgToken` 的起止位置标注未闭合引号或末尾转义；测试框架可把失败用例序列化到日志，再按同一方言复现。
4. **外部任务配置与响应文本：** 对不可信输入使用 `parse_limited` 限制参数数量和单参数字符数，在进入执行层前拒绝异常大的命令文本。

## 核心功能与实现范围

当前 MVP 已完成 POSIX 空白、单双引号、反斜杠和续行分词；Windows CRT 路径反斜杠、引号及奇偶反斜杠规则；两种方言的参数引用与 argv 可逆序列化；字符级源码范围、结构化错误、资源限制和 `CommandLine` 构建器。仓库包含可运行示例、48 项测试、native/wasm-gc 双后端检查及 Windows/Linux CI。明确不实现 shell 执行、变量/通配符展开、重定向、管道或 CLI flag 语义。

## 原创性、参考依据与生态查重

项目为原创实现，没有复制或移植第三方代码，采用 MIT License。规则依据 [POSIX.1-2024 Shell Command Language](https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html) 与 [Microsoft C command-line argument parsing](https://learn.microsoft.com/cpp/c-language/parsing-c-command-line-arguments) 独立编写。2026-09-07 全量检查 Mooncakes 2,352 个公开模块，未发现同名或覆盖相同完整功能边界的包。`clap/ArgParser` 类项目解析已形成的 argv，`myshell/proton_process` 负责进程构建或启动，`moon-install` 仅含面向自身的 POSIX 引用辅助，`moonbash` 是完整 POSIX shell 沙箱；这些项目与 MoonArgv 的双向、双平台词法层职责不同。完整记录见 `docs/ecosystem-audit.md`。
