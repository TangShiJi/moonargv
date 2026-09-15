# MoonArgv

[![CI](https://github.com/TangShiJi/moonargv/actions/workflows/ci.yml/badge.svg)](https://github.com/TangShiJi/moonargv/actions/workflows/ci.yml)

MoonArgv 是纯 MoonBit 的跨平台命令行分词与安全引用库。它在“逻辑参数数组”和“单个命令行字符串”之间进行确定性转换，分别实现 POSIX 词法规则与 Windows Microsoft CRT 反斜杠/引号规则。

项目不解析 `--flag` 等业务选项，也不执行变量展开、管道、重定向或命令替换。它解决的是更底层的问题：构建工具、进程启动器和测试框架怎样在不同平台上保留准确的参数边界。MoonBit 标准库 `argparse` 接收已经切分好的 `Array[String]`，负责 flag、option、位置参数和子命令语义；MoonArgv 负责在这一步之前恢复 argv、在这一步之后安全生成命令文本，两者可直接组合而非相互替代。

## MVP 能力

下列能力属于必须保持兼容的 P0 范围，逐项输入和期望输出见 [可直接验收标准](ACCEPTANCE_CRITERIA.md)，不兼容项见 [兼容边界](COMPATIBILITY.md)。

- POSIX 空白、单双引号、反斜杠转义与续行分词；
- Windows CRT 引号、路径反斜杠、奇偶反斜杠加引号规则；
- 两种方言的单参数引用和完整 `argv` 可逆序列化；
- 每个参数的源码字符范围和结构化错误；
- 可配置参数数量与单参数长度限制；
- 不经字符串拼接的 `CommandLine` 构建器；
- 可拆分程序名与 argv 尾部的 `ParsedCommandLine`，便于接入标准库 `argparse`；
- 递归 `@response-file` 展开、`@@` 转义、循环/深度/资源限制；
- 命令过长时生成“响应文件内容 + 进程 argv”的 `InvocationPlan`；
- 微软 CRT 官方行为向量、1,500 组确定性模糊样本和 release 性能基线；
- native 与 wasm-gc 双后端测试及 Windows/Linux CI。

## 快速使用

```moonbit
let tokens = @moonargv.parse(
  "deploy --message 'release candidate'",
  @moonargv.Posix,
).unwrap()
inspect(@moonargv.values(tokens), content="[deploy, --message, release candidate]")

let command = @moonargv.command_line("C:\\Program Files\\tool.exe").unwrap()
  .argument("--output")
  .argument("C:\\build folder\\")
let text = command.render(@moonargv.Windows)
let recovered = @moonargv.values(
  @moonargv.parse(text, @moonargv.Windows).unwrap(),
)
assert_eq(recovered, command.argv())
```

长编译命令可规划为响应文件，核心库只生成数据，不绑定文件系统或进程库：

```moonbit
let plan = @moonargv.plan_invocation(
  command,
  @moonargv.Windows,
  30000,
  "build\\compile.rsp",
).unwrap()
// 宿主写入 plan.response()，然后直接启动 plan.argv()
```

## 与标准库 `argparse` 的关系

处理链为：`命令字符串 → MoonArgv → Array[String] → argparse → Matches`。MoonArgv 处理 POSIX/Windows 引号、反斜杠、参数边界、源码范围、响应文件和可逆序列化；`argparse` 处理未知选项、必填值、冲突、默认值、环境变量、帮助与子命令。可运行的组合示例见 [`examples/argparse_pipeline`](examples/argparse_pipeline)，逐项对比见 [`docs/argparse-comparison.md`](docs/argparse-comparison.md)。

## 运行与验证

```bash
moon check --target native
moon test --target native
moon check --target wasm-gc
moon test --target wasm-gc
moon run cmd/main
moon run examples/argparse_pipeline/cmd/main
moon run examples/build_pipeline/cmd/main
powershell -File tools/benchmark.ps1 -Runs 5
```

当前实现包含 863 行生产代码、732 行测试代码和 76 项测试，核心包无第三方依赖；模糊测试固定覆盖 1,500 组 argv、两种方言共 3,000 次往返。这些数量与性能结果仅作为 P0 行为的回归佐证，不替代逐条验收标准。示例覆盖 `argparse` 分层组合和编译器长命令响应文件规划；Windows/Linux CI 执行 native、wasm-gc 双后端验证。

## 边界与安全

`parse` 是词法工具，不是 shell。POSIX 模式有意不展开 `$NAME`、通配符或 `$(...)`，Windows 模式也不解释 `cmd.exe` 的 `%NAME%`、`^` 或管道语法。若宿主 API 支持直接传递 `argv`，优先使用 `CommandLine::argv()`；只有目标 API 要求单个字符串时才使用 `render`。

详细规则见 [设计说明](docs/design.md)，P0 合同见 [验收标准](ACCEPTANCE_CRITERIA.md) 与 [兼容边界](COMPATIBILITY.md)，必要性和下游证据见 [集成说明](docs/downstream-integration.md)，性能见 [基线报告](docs/performance.md)，维护承诺见 [维护计划](MAINTENANCE.md)，可复现步骤见 [MVP 验收清单](MVP_ACCEPTANCE.md)，生态查重见 [Mooncakes 查重记录](docs/ecosystem-audit.md)。

## 开源协议

MIT License。
