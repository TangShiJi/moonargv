# MoonArgv

[![CI](https://github.com/TangShiJi/moonargv/actions/workflows/ci.yml/badge.svg)](https://github.com/TangShiJi/moonargv/actions/workflows/ci.yml)

MoonArgv 是纯 MoonBit 的跨平台命令调用契约与进程规划库。它把程序、逻辑 argv、工作目录、环境变更、标准输入和秘密标记编译为确定性的 `PreparedExecution`：进程 argv 或响应文件、环境快照、PATH/PATHEXT 候选路径以及脱敏审计命令。真正的文件 IO、候选路径探测和进程启动交给宿主适配器。

项目解决的是 process API 之前容易分散实现的边界规则，而不是另一套进程库或 CLI parser。MoonBit 标准库 `argparse` 解释程序内部已经切分的 argv；process/subprocess 库启动和管理进程；MoonArgv 负责在构建配置、任务描述、日志和这些 API 之间生成可验证的调用契约。

## MVP 能力

- POSIX quoting 与 Windows Microsoft CRT 分词、源码范围和可逆 argv 序列化；
- 递归 `@response-file`、`@@` 转义、循环/深度/资源限制；
- 长命令生成响应文件内容及进程 argv；
- POSIX 大小写敏感和 Windows 大小写不敏感的环境覆盖、删除与稳定排序；
- 环境名称、数量和值长度验证，敏感环境值的审计脱敏；
- PATH/PATHEXT 可执行候选规划、显式路径识别和平台化去重；
- 参数位置、flag 后值、赋值型 option 和字面值秘密脱敏；
- `ExecutionSpec → PreparedExecution` 统一契约，携带工作目录与 stdin 策略；
- 标准库 `argparse`、编译响应文件和部署执行契约三个可运行示例；
- Windows/Linux CI 上 native 与 wasm-gc 双后端验证。

## 快速使用

```moonbit
let command = @moonargv.command_line("deploy-agent")
  .unwrap()
  .append_all(["--token", "private", "--workspace", "release workspace"])
let spec = @moonargv.execution_spec(command)
  .in_directory("/workspace/app")
  .set_environment("CI", "true")
  .set_environment("DEPLOY_TOKEN", "private", sensitive=true)
  .redact(@moonargv.secret_after_flag("--token"))
  .stdin(@moonargv.ClosedInput)
let prepared = @moonargv.prepare_execution(
  spec,
  [@moonargv.environment_entry("PATH", "/usr/bin")],
  ["/opt/deploy/bin", "/usr/bin"],
  @moonargv.PosixTarget,
).unwrap()
// 宿主探测 prepared.executable().candidates()，写可选响应文件，
// 然后使用 prepared.invocation().argv() 启动；日志只记录 audit_command()。
```

若只有单字符串任务配置，可先恢复 argv，再交给 `argparse`：

```moonbit
let parsed = @moonargv.parse_command_line(
  "deploy --region 'cn shanghai'",
  @moonargv.Posix,
).unwrap()
// parsed.arguments() 可直接传给 argparse
```

## 分层关系

| 层 | 负责 | 不负责 |
| --- | --- | --- |
| MoonArgv | argv 边界、响应文件、环境覆盖、候选规划、审计脱敏、执行契约 | 文件 IO、进程生命周期、业务 option |
| `argparse` / CLI parser | flag、option、位置参数、帮助与子命令 | 命令字符串、PATH、环境快照、进程启动 |
| process/subprocess 库 | 实际路径探测、spawn、stdin/stdout、退出状态 | 跨后端的声明式调用准备 |
| task runner / build graph | DAG、缓存、并发调度 | 单个进程调用的跨平台边界细节 |

## 运行与验证

```bash
moon fmt --check
moon test --target native
moon test --target wasm-gc
moon run examples/argparse_pipeline/cmd/main
moon run examples/build_pipeline/cmd/main
moon run examples/execution_contract/cmd/main
powershell -File tools/source-metrics.ps1
```

当前仓库含 1,994 行生产 MoonBit 源码；排除空行和整行注释仍有 1,621 行，统计不含测试及 `_build`。20 个测试文件共 1,153 行，运行得到 99 项测试；模糊测试固定覆盖 1,500 组 argv。源码量的可复算口径见 [源码量核验](docs/source-metrics.md)，P0 输入与期望输出见 [验收标准](ACCEPTANCE_CRITERIA.md)。

## 边界与文档

MoonArgv 不执行 shell 展开，不启动进程，不访问文件系统，不实现任务 DAG，也不替代 `argparse`。IO-free 设计使同一核心可在 Web/Wasm 预检，在 Windows/Linux 宿主执行。

- [兼容边界](COMPATIBILITY.md)
- [设计说明](docs/design.md)
- [下游集成与必要性](docs/downstream-integration.md)
- [Mooncakes 生态查重](docs/ecosystem-audit.md)
- [MVP 验收清单](MVP_ACCEPTANCE.md)
- [维护计划](MAINTENANCE.md)

## 开源协议

MIT License。
