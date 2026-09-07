# MoonArgv

MoonArgv 是纯 MoonBit 的跨平台命令行分词与安全引用库。它在“逻辑参数数组”和“单个命令行字符串”之间进行确定性转换，分别实现 POSIX 词法规则与 Windows Microsoft CRT 反斜杠/引号规则。

项目不解析 `--flag` 等业务选项，也不执行变量展开、管道、重定向或命令替换。它解决的是更底层的问题：构建工具、进程启动器和测试框架怎样在不同平台上保留准确的参数边界。

## MVP 能力

- POSIX 空白、单双引号、反斜杠转义与续行分词；
- Windows CRT 引号、路径反斜杠、奇偶反斜杠加引号规则；
- 两种方言的单参数引用和完整 `argv` 可逆序列化；
- 每个参数的源码字符范围和结构化错误；
- 可配置参数数量与单参数长度限制；
- 不经字符串拼接的 `CommandLine` 构建器；
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

## 运行与验证

```bash
moon check --target native
moon test --target native
moon check --target wasm-gc
moon test --target wasm-gc
moon run cmd/main
```

当前 MVP 包含 524 行生产代码、349 行测试代码和 48 项测试，核心包无第三方依赖。示例同时展示 POSIX 分词、Windows 命令渲染和可逆性检查。

## 边界与安全

`parse` 是词法工具，不是 shell。POSIX 模式有意不展开 `$NAME`、通配符或 `$(...)`，Windows 模式也不解释 `cmd.exe` 的 `%NAME%`、`^` 或管道语法。若宿主 API 支持直接传递 `argv`，优先使用 `CommandLine::argv()`；只有目标 API 要求单个字符串时才使用 `render`。

详细规则见 [设计说明](docs/design.md)，规则依据见 [标准参考](docs/references.md)，可复现步骤见 [MVP 验收清单](MVP_ACCEPTANCE.md)，生态查重见 [Mooncakes 查重记录](docs/ecosystem-audit.md)。

## 开源协议

MIT License。
