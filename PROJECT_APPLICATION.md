# MoonArgv 项目申报书

**基本信息**

- **项目名称：** MoonArgv——跨平台命令参数边界与响应文件库
- **参赛者：** 唐仕吉
- **联系方式：** 邮箱：t1622051617@qq.com；手机号：13384247418
- **GitHub 仓库链接：** https://github.com/TangShiJi/moonargv
- **项目方向：** MoonBit 开发工具基础库 / 构建与进程参数基础设施
- **项目性质：** 原创项目，非移植项目，未参考已有开源项目代码；本项目采用 MIT License

**项目简介与生态定位**

MoonArgv 补齐 MoonBit 的参数边界层。标准库 `argparse` 从已切分的 `Array[String]` 开始，但构建工具和任务配置仍需在命令字符串、argv 与响应文件之间转换。手工按空格拼接会破坏空参数、空格路径、引号和 Windows 结尾反斜杠；调用 shell 又增加展开语义和注入风险。本项目负责 `argparse` 之前的分词和进程调用之前的安全序列化。

实现为 POSIX quoting 与 Windows CRT 分别维护单遍状态机，以 `parse(join(argv)) == argv` 为不变量。响应文件展开限制深度和参数规模；文件 IO 与进程启动由宿主完成。

**项目方向与通用性**

方向为 MoonBit 开发工具和构建/进程参数基础设施。API 不绑定编译器、CLI 框架或进程库，可在 native、wasm-gc 的构建系统、任务运行器、测试框架和编辑器中复用。

**预期使用场景**

1. **大型编译与链接：** 命令过长时生成 `moonc @compile.rsp` 和文件内容；重新展开与原参数逐项一致，循环或超限直接拒绝。
2. **任务配置接入 CLI：** 将带引号的部署配置恢复为程序名和 argv，再交给 `argparse`；未闭合引号提前返回字符位置。
3. **跨平台进程与复现：** 数组接口直接传 argv，单字符串接口按 POSIX/Windows CRT 渲染；日志可按同一方言还原空参数、中文路径和结尾反斜杠。

**拟实现的核心功能**

- **POSIX：** 空白、单双引号、反斜杠、续行、空参数、错误偏移及 argv 往返；
- **Windows CRT：** 引号和反斜杠奇偶规则、路径末尾反斜杠、Microsoft 官方示例及 argv 往返；
- **响应文件与进程：** `@path` 递归、`@@` 转义、循环/深度/资源错误，以及长命令的可逆响应内容；
- **下游接口：** 程序名/argv 尾部分离、源码范围、结构化错误、输入上限，以及 `argparse` 和构建工具示例。

**工程边界**

POSIX 仅承诺 quoting 子集，不执行变量、通配符、命令替换、管道或重定向；Windows 不模拟 `cmd.exe`、PowerShell、`CommandLineToArgvW` 或 `argv[0]` 特例。响应文件 IO、编码和编译器私有格式由宿主处理；选项语义属于 `argparse`。详见 `COMPATIBILITY.md`。

**预期验收产物**

- 可安装库及 `argparse`、构建响应文件两个可运行示例；
- P0-POSIX、WIN、RSP、PROC、BRIDGE、LIMIT 共9项行为达到 `ACCEPTANCE_CRITERIA.md` 的输入和预期输出；
- Windows/Ubuntu 上 native、wasm-gc 构建与测试全部成功。

编号对应同名测试；76项测试、1,500组模糊样本和性能基线仅作佐证。仓库有效提交已超过章程要求的10个，均对应功能、测试、文档或验证，无空提交及重复提交。

**原创或参考说明**

本项目为原创项目，非移植，未复制或改写开源项目代码，采用 MIT License；仅以 [POSIX.1-2024](https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html) 和 [Microsoft CRT 规则](https://learn.microsoft.com/cpp/c-language/parsing-c-command-line-arguments) 作为行为规范。2026-09-15 检查 Mooncakes 2,487 个模块，未发现同名或覆盖完整边界的项目；`argparse/clap` 解析现成 argv，进程库负责启动，均不承担本项目的转换职责。
