# MoonArgv MVP 验收清单

## 自动验证

```bash
moon fmt --check
moon check --target native
moon test --target native
moon check --target wasm-gc
moon test --target wasm-gc
moon run cmd/main
moon run examples/argparse_pipeline/cmd/main
```

预期结果：两种后端均有 53 项测试通过；主示例输出 POSIX 参数与 Windows 可逆结果，组合示例输出 `staging cluster` 和 `true`。

2026-09-07 已在 GitHub Actions 的 Ubuntu 与 Windows 环境完成上述格式、构建和测试流程：https://github.com/TangShiJi/moonargv/actions/runs/34077836764

## 功能映射

| 能力 | 可观察结果 | 测试文件 |
| --- | --- | --- |
| POSIX 分词 | 空白、引号、转义、拼接与错误位置 | `posix_test.mbt` |
| POSIX 序列化 | 空参数、Unicode、单引号可逆 | `posix_quote_test.mbt` |
| Windows 分词 | 路径、双引号、反斜杠奇偶规则 | `windows_test.mbt` |
| Windows 序列化 | 内部引号与结尾反斜杠可逆 | `windows_quote_test.mbt` |
| 统一 API | 方言分发和跨方言参数恢复 | `api_test.mbt` |
| `argparse` 组合 | 分离程序名/argv，由标准库解释选项并校验必填值 | `examples/argparse_pipeline` |
| 输入上限 | 参数数和字符数超限可定位 | `limits_test.mbt` |
| 命令构建 | 程序名校验、argv 和渲染 | `command_test.mbt` |
| 端到端流程 | 构建命令跨平台往返一致 | `integration_test.mbt` |

## 明确不做

MVP 不执行命令，不做环境变量、通配符、管道或重定向展开，不替代标准库 `argparse` 等 CLI 选项解析器，也不模拟 `cmd.exe` 或完整 POSIX shell。
