# 下游集成与必要性验证

MoonArgv 针对的是“参数已经有结构，但下游边界并不统一”的工程问题。仓库用两条可运行链路验证它不是另一套 CLI 选项解析器。

## 构建工具 / 进程启动链路

[`examples/build_pipeline`](../examples/build_pipeline) 模拟编译器接收多源文件和输出路径。调用方始终逐项构造 `CommandLine`；短命令由 `InvocationPlan::argv()` 直接启动，超过宿主长度阈值后自动得到：

- 待启动的 `['moonc', '@build/compile.rsp']`；
- 宿主需要写入的响应文件路径、内容和方言；
- 可由 `expand_response_files` 验证的原始参数边界。

集成测试覆盖带空格的生成代码目录和产物路径，证明“生成响应文件—再次展开”保持编译器 argv 完全一致。核心库保持无 IO：不同后端使用自身文件系统和进程 API 写文件、启动进程，不把 native 能力强加给 wasm-gc。

## CLI 配置链路

[`examples/argparse_pipeline`](../examples/argparse_pipeline) 把配置中的单字符串先交给 MoonArgv，再把恢复出的 argv 尾部交给标准库 `argparse`。测试分别证明引号值不丢失、必填 option 仍由 `argparse` 校验。

## 不可替代性

- 仅使用 `argparse`：它的入口已经要求 `Array[String]`，无法恢复配置文本中的 POSIX/Windows 引号边界，也不生成响应文件内容。
- 仅手工拼接：空参数、含空格路径、内嵌引号和 Windows 结尾反斜杠会产生歧义，且无法提供可逆性质保证。
- 调用 shell：引入变量展开、管道和命令替换等额外语义，扩大注入面；也不能解决 Windows CRT 与 POSIX 的规则差异。
- MoonArgv：以无 IO 的统一数据层连接配置、构建描述、响应文件、选项解析器与进程 API，并用跨后端性质测试验证边界。
