# 下游集成与必要性验证

MoonArgv 针对的是“任务已经有结构，但不同宿主的进程边界并不统一”的工程问题。仓库用三条可运行链路验证它既不是 CLI parser，也不是另一个 process 库。

## 构建工具 / 进程启动链路

[`examples/build_pipeline`](../examples/build_pipeline) 模拟编译器接收多源文件和输出路径。调用方始终逐项构造 `CommandLine`；短命令由 `InvocationPlan::argv()` 直接启动，超过宿主长度阈值后自动得到：

- 待启动的 `['moonc', '@build/compile.rsp']`；
- 宿主需要写入的响应文件路径、内容和方言；
- 可由 `expand_response_files` 验证的原始参数边界。

集成测试覆盖带空格的生成代码目录和产物路径，证明“生成响应文件—再次展开”保持编译器 argv 完全一致。核心库保持无 IO：不同后端使用自身文件系统和进程 API 写文件、启动进程，不把 native 能力强加给 wasm-gc。

## CLI 配置链路

[`examples/argparse_pipeline`](../examples/argparse_pipeline) 把配置中的单字符串先交给 MoonArgv，再把恢复出的 argv 尾部交给标准库 `argparse`。测试分别证明引号值不丢失、必填 option 仍由 `argparse` 校验。

## 代码代理 / 部署执行契约

[`examples/execution_contract`](../examples/execution_contract) 模拟代理调用部署工具：声明工作目录、环境覆盖、关闭 stdin、搜索目录以及 `--token` 秘密。一次 `prepare_execution` 同时产出：

- 不含秘密的可复制审计命令；
- 保留真实值但在环境审计中隐藏的确定性环境快照；
- `/opt/deploy/bin` 和 `/usr/bin` 下的候选可执行路径；
- 因长度阈值触发的 argv 与响应文件载荷。

该示例对应真实的工具集成方式：Web/Wasm 侧可先验证和展示计划，native process 适配器再完成文件写入、候选探测及 spawn。

## 不可替代性

- 仅使用 `argparse`：它的入口已经要求 `Array[String]`，无法恢复配置文本中的 POSIX/Windows 引号边界，也不生成响应文件内容。
- 仅手工拼接：空参数、含空格路径、内嵌引号和 Windows 结尾反斜杠会产生歧义，且无法提供可逆性质保证。
- 调用 shell：引入变量展开、管道和命令替换等额外语义，扩大注入面；也不能解决 Windows CRT 与 POSIX 的规则差异。
- 仅使用 process 库：可以 spawn，但环境覆盖、PATH/PATHEXT 顺序、响应文件和日志脱敏仍会散落在每个调用点。
- 使用完整 task runner：会引入 DAG、缓存和调度等上层概念，不能作为轻量库嵌入现有构建器、IDE 或测试框架。
- MoonArgv：以无 IO 的统一数据层连接配置、构建描述、响应文件、选项解析器与进程 API，并用跨后端测试验证边界。
