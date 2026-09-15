# MoonArgv 项目申报书

## 基本信息

- **项目名称：** MoonArgv——跨平台命令参数边界与响应文件库
- **参赛者：** TangShiJi（GitHub ID）
- **联系方式：** https://github.com/TangShiJi；tangshiji@users.noreply.github.com
- **GitHub 仓库：** https://github.com/TangShiJi/moonargv
- **项目方向：** MoonBit 开发工具基础库 / 构建与进程参数基础设施
- **项目性质及许可证：** 原创项目，非移植项目，MIT License

## 项目简介与使用场景

MoonArgv 在命令文本、逻辑 argv、响应文件、`argparse` 与进程 API 之间提供确定、可逆的参数边界转换，解决空参数、空格路径、引号和 Windows 结尾反斜杠经手工拼接后失真的问题。实际场景包括：大型编译/链接命令超过系统长度限制时生成响应文件；任务配置文本先恢复 argv 再交给标准库 `argparse`；测试或编辑器按源码范围定位引号错误并复现失败命令。核心无 IO，可供 native 进程库与 wasm-gc 宿主复用。

## 核心功能范围

1. **POSIX 必做：** 解析空白、单双引号、反斜杠、续行、片段拼接和空参数；错误返回类型及字符偏移；`parse(join(argv))` 必须恢复原 argv。
2. **Windows CRT 必做：** 实现双引号边界及引号前反斜杠奇偶规则，保留普通路径和带空格路径末尾反斜杠；Microsoft 官方 5 组常规参数示例必须一致，并满足往返不变量。
3. **响应文件与进程必做：** 支持 `@path` 递归展开、`@@` 转义、缺失/循环/深度/资源限制；长命令生成 `[program, @path]` 与响应内容，重新展开必须等于原参数。
4. **下游衔接必做：** 分离程序名和 argv 尾部供 `argparse` 使用；提供源码范围、结构化错误、输入上限及两个可运行集成示例。

## 兼容边界

POSIX 模式仅承诺 quoting 词法子集，不执行变量、通配符、命令替换、管道、重定向或注释；Windows 模式遵循 Microsoft CRT 常规参数规则，不模拟 `cmd.exe`、PowerShell、`CommandLineToArgvW` 或 CRT 的 `argv[0]` 历史特例。响应文件编码、BOM、磁盘 IO 和编译器私有格式由宿主适配；option、flag、子命令语义由标准库 `argparse` 负责。完整边界见 `COMPATIBILITY.md`。

## 可直接验收标准

评审者运行 native/wasm-gc 测试即可按编号验收：`P0-POSIX-01/02` 验证引号、空参数和错误偏移；`P0-WIN-01/02` 验证 CRT 反斜杠引号行为与路径往返；`P0-RSP-01/02` 验证嵌套展开及循环拒绝；`P0-PROC-01` 验证长编译命令响应文件无损恢复；`P0-BRIDGE-01` 验证 `argparse` 输入衔接；`P0-LIMIT-01` 验证展开后上限。每项输入和期望输出见 `ACCEPTANCE_CRITERIA.md`。当前 76 项测试、1,500 组确定性模糊样本、双系统/双后端 CI 及 20,000 次往返性能基线仅作为上述行为和回归能力的佐证，不代替验收标准。

## 原创性与参考说明

项目未复制或移植第三方代码，依据 [POSIX.1-2024](https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html) 和 [Microsoft CRT 文档](https://learn.microsoft.com/cpp/c-language/parsing-c-command-line-arguments) 独立实现。2026-09-15 检查 Mooncakes 2,487 个公开模块，无同名或覆盖“POSIX/Windows 双向词法、响应文件、诊断与限制”完整边界的项目。标准库 `argparse` 从已切分 argv 开始解释业务选项，与本项目上下游互补。
