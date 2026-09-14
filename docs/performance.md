# 性能评估

## 方法

`bench/roundtrip` 固定使用 8 个包含普通参数、空格、引号、Windows 路径与中文的 argv；每轮分别执行 POSIX 和 Windows 的 `join + parse`，共 20,000 次往返。`tools/benchmark.ps1` 以 release 模式运行 5 次并报告中位数，不设置易受机器波动影响的硬性门槛。

## 2026-09-14 基线

- 环境：Windows，Intel Core i9-12900H（14 核 / 20 线程）；
- 工具链：moon 0.1.20260819，moonc 0.10.9；
- 5 次端到端耗时：258.49、243.47、250.72、248.33、254.91 ms；
- 中位数：250.72 ms，即约 79,770 次 `join + parse` 往返/秒（包含 `moon run` 启动开销）。

该负载显著高于常规构建任务的一次命令处理量。基线用于后续版本比较；若同机同工具链中位数回退超过 20%，将先分析分配次数、超长参数和 Windows 反斜杠路径，再决定优化或记录原因。

复现：`powershell -File tools/benchmark.ps1 -Runs 5`。
