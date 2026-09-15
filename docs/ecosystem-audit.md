# Mooncakes 生态查重记录

查重日期：2026-09-15

数据源：https://mooncakes.io/api/v0/modules

扫描范围：接口返回的全部 2,488 个公开模块；检索模块名称和简介。精确及边界组合 `moonargv`、`moonexec`、`execspec`、`execplan`、`invocation contract`、`command invocation contract`、`argument boundary`、`secret redaction`、`PATHEXT` 均为 0 个命中。

## 相邻项目逐项对照

| 项目 | Mooncakes 公开定位 | 与 MoonArgv 的实质边界 |
| --- | --- | --- |
| `bobzhang/myshell@0.3.0` | shell-free process EDSL | 负责表达和执行进程组合；未声明 Windows CRT/响应文件、环境快照、PATH 候选和秘密审计的统一纯数据契约 |
| `moonbit-community/proton_process@0.2.6` | Windows/Linux/macOS 原生子进程启动 | 是 MoonArgv 的执行端；MoonArgv 自身无 IO，可在 wasm-gc 预检 |
| `sennenki/process@0.1.0` | 进程启动与管理 | 管理真实进程生命周期，不承担调用前的跨平台确定化 |
| `trkbt10/subprocess@0.2.0` | Node.js child_process 风格子进程管理 | 提供 Node 风格执行接口，不提供跨 native/wasm-gc 的调用契约层 |
| `totto2727/agent-cli-sdk@0.2.1` | JSONL agent CLI 进程基础 | 面向 agent CLI 协议，定位不是通用命令调用准备 |
| `FrenchPicnic/which@0.1.3` | 跨平台查找已安装可执行文件 | 实际访问系统完成 which；MoonArgv 只生成可测试的 PATH/PATHEXT 候选并与环境、argv、审计组合 |
| `cauchyQ/moonbit-argkit@0.1.0` 及其他 CLI parser | 从 argv 解析业务参数 | 位于程序内部，不恢复命令文本、不准备宿主执行契约 |
| `ZSeanYves/MoonJust@0.1.3-rc.1`、`mizchi/bitflow@0.4.1`、`Zcxssxx/moon-ninja@0.3.2` | task runner、工作流或构建图 | 负责 DAG、缓存及调度；MoonArgv 只规范单个进程调用，可作为其下游基础层 |

## 与标准库 `argparse` 的边界

`moonbitlang/core/argparse` 的入口是已切分的 `Array[String]`，负责 flag、option、位置参数、子命令、帮助与约束。MoonArgv 在其之前恢复任务配置的 argv，在其外部为宿主准备环境、响应文件、可执行路径候选和安全审计。两者组合示例见 `examples/argparse_pipeline`。

## 结论

截至查重时间，没有 Mooncakes 包覆盖“POSIX/Windows argv + 响应文件 + 环境 overlay + PATH/PATHEXT 候选 + 参数/环境脱敏 + 统一执行契约”的完整边界。相邻项目不是隐瞒的竞品，而是 MoonArgv 的上游或下游：任务工具产生 `ExecutionSpec`，MoonArgv 确定化，process 库探测并执行。正式发布前仍须重新全量查询。
