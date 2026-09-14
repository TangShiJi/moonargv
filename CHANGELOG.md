# Changelog

## Unreleased

- 新增 `ParsedCommandLine` 与 `parse_command_line`，分离程序名和 argv 尾部。
- 新增与 MoonBit 标准库 `argparse` 的可运行组合示例及测试。
- 新增递归响应文件展开、循环/深度/资源限制和 `@@` 字面转义。
- 新增 `InvocationPlan` 及编译器长命令/响应文件集成示例。
- 新增微软 CRT 官方行为向量、1,500 组确定性模糊测试和 release 基准。
- 补充真实下游、不替代性、性能报告与版本维护计划。
- 补充 API 级职责对比、申报书说明和 2026-09-14 Mooncakes 全量查重。
- 测试数增加至 67 项。

## 0.1.0 - 2026-09-07

- 实现 POSIX 风格空白、引号、转义和续行分词。
- 实现 Microsoft CRT 风格 Windows 引号与反斜杠解析。
- 为两种方言提供可逆的参数引用和 argv 序列化。
- 提供源码范围、结构化错误和可配置资源限制。
- 提供 `CommandLine` 构建器、可运行示例和 48 项测试。
