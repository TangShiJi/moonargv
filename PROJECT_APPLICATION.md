# MoonArgv 项目申报书

## 1. 项目名称与仓库

**MoonArgv——跨平台命令行分词与安全引用库**

GitHub：https://github.com/TangShiJi/moonargv

## 2. 项目简介、方向与通用性

MoonArgv 是纯 MoonBit 的命令参数边界基础库，在命令文本、逻辑 argv、响应文件、CLI 解析器与进程 API 之间做可验证转换。项目实现 POSIX 与 Windows CRT 规则、源码诊断和资源限制，不执行 shell，适用于构建系统、任务运行器、编辑器和子进程封装，并跨 native/wasm-gc 复用。

## 3. 预期使用场景

1. **大型构建/链接：** 构造含生成目录、中文或空格路径的编译 argv；超过平台阈值时生成 `@compile.rsp` 及进程启动数组，再展开验证边界一致。
2. **任务配置接入 CLI：** 将 `deploy --target 'staging cluster'` 恢复为 argv，再交给标准库 `argparse` 校验 flag、option 和子命令。
3. **跨平台进程启动：** 数组接口直接使用 argv；单字符串接口按 POSIX/Windows 安全渲染，避免手工拼接造成空参数、引号和结尾反斜杠歧义。
4. **编辑器/测试平台：** 用 token 范围定位引号错误，把失败 argv 可逆写入日志；对外部响应文件限制嵌套、循环、参数数与长度。

## 4. 核心功能与 MVP

已完成双平台分词/引用、`ParsedCommandLine`、`CommandLine`；新增递归响应文件展开、`@@` 转义、缺失/循环/深度错误和 `InvocationPlan` 长命令降级。仓库有 21 个以上有效提交、67 项测试；微软 CRT 官方示例表全部对齐，固定模糊测试覆盖 1,500 组、3,000 次双方言往返。release 基准在 i9-12900H 上完成 20,000 次 `join+parse` 的中位数为 250.72 ms。两个真实链路示例分别集成 `argparse` 与编译器响应文件，Windows/Linux、native/wasm-gc CI 验证。

## 5. 与标准库 `argparse` 的区别

标准库 [`argparse`](https://github.com/moonbitlang/core/tree/main/argparse) 从**已切分的 `Array[String]`**开始，负责 option、flag、子命令、env/default 和帮助；不解释整段 POSIX/Windows 文本、不生成可逆命令或响应文件。MoonArgv 负责其前后的参数边界层，组合为 `配置文本 → MoonArgv → argv → argparse` 或 `构建 argv → MoonArgv → 进程/响应文件`。仅用手工拼接会在空参数、引号和 Windows 反斜杠处失真；调用 shell 又引入展开和注入面，因此该无 IO、双方言、可性质验证的中间层不能由 `argparse` 替代。

## 6. 原创性、参考来源与查重

原创、非移植项目，未复制第三方代码，MIT License；依据 [POSIX.1-2024](https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html) 与 [Microsoft CRT 规则](https://learn.microsoft.com/cpp/c-language/parsing-c-command-line-arguments) 独立实现。2026-09-14 全量复核 Mooncakes 2,450 个模块，无同名或覆盖“双平台双向词法+响应文件+诊断/限制”的项目。维护上每周整理 issue、每次提交运行双系统/双后端测试，发布前复跑性能基线；后续完善编码/BOM、进程库适配和稳定错误模型，不扩展为 shell 或重复 `argparse`。
