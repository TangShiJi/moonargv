# MoonArgv MVP 验收清单

复现工具链：MoonBit `0.10.9+6e6c44045`。GitHub Actions 固定使用同一版本，避免 `latest` 格式器变化造成与功能无关的失败。

## 自动验证

```bash
moon fmt --check
moon check --target native
moon test --target native
moon check --target wasm-gc
moon test --target wasm-gc
moon run cmd/main
moon run examples/argparse_pipeline/cmd/main
moon run examples/build_pipeline/cmd/main
moon run examples/execution_contract/cmd/main
moon run --release bench/roundtrip
powershell -File tools/source-metrics.ps1
```

预期结果：两种后端均有 99 项测试通过；其中 `acceptance_test.mbt` 的 13 个测试与 `ACCEPTANCE_CRITERIA.md` 的 P0 编号逐项对应。测试还执行 1,500 组确定性模糊输入和微软 CRT 对照表。三个下游示例分别输出 `argparse` 结果、编译器响应文件计划和部署执行契约；源码统计必须显示生产代码 1,994 行、排除空行及整行注释后 1,621 行。

2026-09-15 已在 GitHub Actions 完成 Ubuntu/Windows、native/wasm-gc 双后端、三个下游示例和 release 基准验证：https://github.com/TangShiJi/moonargv/actions/runs/34974659517

## 功能映射

| 能力 | 可观察结果 | 测试文件 |
| --- | --- | --- |
| POSIX 分词 | 空白、引号、转义、拼接与错误位置 | `posix_test.mbt` |
| POSIX 序列化 | 空参数、Unicode、单引号可逆 | `posix_quote_test.mbt` |
| Windows 分词 | 路径、双引号、反斜杠奇偶规则 | `windows_test.mbt` |
| Windows 序列化 | 内部引号与结尾反斜杠可逆 | `windows_quote_test.mbt` |
| 统一 API | 方言分发和跨方言参数恢复 | `api_test.mbt` |
| `argparse` 组合 | 分离程序名/argv，由标准库解释选项并校验必填值 | `examples/argparse_pipeline` |
| 响应文件 | 递归展开、转义、循环/深度/资源限制 | `response_file_test.mbt` |
| 进程/构建集成 | 长命令生成响应文件计划并无损恢复编译 argv | `examples/build_pipeline`、`invocation_test.mbt` |
| Windows CRT 对照 | 微软官方文档的 5 组系统行为示例 | `windows_crt_vectors_test.mbt` |
| 模糊性质验证 | 1,500 组随机 argv 在两种方言下往返一致 | `fuzz_test.mbt` |
| 性能基线 | release 下 20,000 次双向往返与 checksum | `bench/roundtrip` |
| P0 直接验收 | 9 个编号行为与公开验收表逐项对应 | `acceptance_test.mbt`、`ACCEPTANCE_CRITERIA.md` |
| 输入上限 | 参数数和字符数超限可定位 | `limits_test.mbt` |
| 命令构建 | 程序名校验、argv 和渲染 | `command_test.mbt` |
| 端到端流程 | 构建命令跨平台往返一致 | `integration_test.mbt` |
| 环境契约 | POSIX/Windows 键规则、set/remove、排序、敏感值和限制 | `environment_test.mbt` |
| 可执行候选 | PATH/PATHEXT、显式路径、去重和候选上限 | `executable_test.mbt` |
| 审计脱敏 | 位置、flag 后值、赋值 option、字面值及原 argv 不变 | `redaction_test.mbt` |
| 统一执行契约 | 工作目录、stdin、环境、候选、响应文件和审计一次产出 | `execution_contract_test.mbt`、`examples/execution_contract` |
| 源码量 | 排除生成物、测试、空行和整行注释后仍超过 1,000 行 | `tools/source-metrics.ps1`、`docs/source-metrics.md` |

## 明确不做

MVP 不执行命令或文件 IO，不探测候选是否存在，不做变量、通配符、管道或重定向展开，不替代 `argparse`，不实现任务 DAG，也不模拟完整 shell。IO-free 使同一核心可由 native 进程库、构建工具和 wasm-gc 宿主分别接入。
