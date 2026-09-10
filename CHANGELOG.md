# Changelog

## Unreleased

- 新增 `ParsedCommandLine` 与 `parse_command_line`，分离程序名和 argv 尾部。
- 新增与 MoonBit 标准库 `argparse` 的可运行组合示例及测试。
- 补充 API 级职责对比、申报书说明和 2026-09-10 Mooncakes 全量查重。
- 测试数增加至 53 项。

## 0.1.0 - 2026-09-07

- 实现 POSIX 风格空白、引号、转义和续行分词。
- 实现 Microsoft CRT 风格 Windows 引号与反斜杠解析。
- 为两种方言提供可逆的参数引用和 argv 序列化。
- 提供源码范围、结构化错误和可配置资源限制。
- 提供 `CommandLine` 构建器、可运行示例和 48 项测试。
