# MoonArgv 可直接验收标准

以下是项目通过初审后必须持续满足的 P0 行为。评审者在仓库根目录运行 `moon test --target native` 和 `moon test --target wasm-gc` 即可直接验收；对应测试名与编号完全一致。

| 编号 | 给定输入 | 必须观察到的结果 |
| --- | --- | --- |
| P0-POSIX-01 | `tool '' "a b" c\\ d` | 得到 `tool`、空参数、`a b`、`c d` 四项 |
| P0-POSIX-02 | `tool 'open` | 返回 `UnterminatedSingleQuote`，偏移为 5 |
| P0-WIN-01 | Microsoft CRT 的三反斜杠加引号样例 | 得到一个反斜杠加字面双引号，后续参数正确分隔 |
| P0-WIN-02 | 带空格且以反斜杠结尾的 Windows 路径、空参数、内嵌引号 | `join` 后再 `parse` 与原 argv 逐项相等 |
| P0-RSP-01 | 响应文件嵌套引用源文件列表 | 递归展开并保持原顺序和带空格路径 |
| P0-RSP-02 | `a.rsp → b.rsp → a.rsp` | 返回 `ResponseFileCycle`，不得返回部分结果 |
| P0-PROC-01 | 超过 16 字符阈值的编译命令 | 生成 `moonc @compile.rsp`；内容展开等于原参数 |
| P0-BRIDGE-01 | 带引号值的部署命令文本 | 分离程序名；argv 尾部可直接交给 `argparse` |
| P0-LIMIT-01 | 展开后超过最终参数数上限 | 返回 `TooManyArguments` |
| P0-ENV-01 | Windows 基础环境含 `Path`，覆盖项含 `PATH` 和敏感 `TOKEN` | `Path/PATH` 合并为一个键，审计值显示 `<redacted>` |
| P0-LOOKUP-01 | Windows 程序 `moonc`、一个 PATH 目录及 `.EXE/.CMD` | 按顺序得到裸名、EXE、CMD 三个候选路径 |
| P0-AUDIT-01 | argv 含 `--token private` 与 `--header=secret` | 审计命令中不出现两个秘密，解析后相应值为 `<redacted>` |
| P0-CONTRACT-01 | 含目录、环境、秘密和超长参数的 `ExecutionSpec` | 同时得到候选路径、环境快照、响应文件 argv 和脱敏命令 |

## 交付门槛

1. 上述 P0 用例、Microsoft CRT 官方 5 组对照向量和 1,500 组确定性往返模糊样本全部通过；
2. native 与 wasm-gc 均完成检查和测试，Windows 与 Ubuntu CI 均成功；
3. 三个 examples 均可运行，分别证明 `argparse`、编译响应文件及完整执行契约集成；
4. 公开 API、README、兼容边界和 CHANGELOG 与实现一致；
5. 测试数量和性能结果仅作回归佐证，不替代上述行为验收。性能基线不设跨机器硬阈值；同机同工具链中位数回退超过 20% 时必须记录分析。
6. 生产 MoonBit 源码排除 `_build`、测试、空行和整行注释后仍不少于 1,000 行；运行 `tools/source-metrics.ps1` 可复算。
