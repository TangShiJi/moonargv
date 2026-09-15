# MoonBit 源码量核验

核验范围只包含仓库中的 `.mbt` 文件，排除 `_build` 生成目录；生产代码进一步排除 `_test.mbt` 和 `_wbtest.mbt`。运行 `powershell -File tools/source-metrics.ps1` 可复算。

2026-09-15 的结果：

| 分类 | 文件数 | 物理行 | 非空行 | 排除空行及整行注释 |
| --- | ---: | ---: | ---: | ---: |
| 生产源码 | 23 | 1,994 | 1,865 | 1,621 |
| 测试源码 | 20 | 1,153 | 1,069 | 962 |

因此“有效 MoonBit 源码超过 1,000 行”不依赖测试、示例生成物、空行或注释。新增生产代码主要位于 `environment.mbt`、`executable.mbt`、`redaction.mbt` 和 `execution_contract.mbt`，分别实现环境覆盖、PATH/PATHEXT 候选规划、秘密脱敏和统一执行契约，并非重复代码。
