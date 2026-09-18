# MoonPageFlow

[![CI](https://github.com/TangShiJi/moonpageflow/actions/workflows/ci.yml/badge.svg)](https://github.com/TangShiJi/moonpageflow/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

MoonPageFlow 是面向 MoonBit 服务端、SDK 与数据工具的稳定游标分页内核。它把复合排序、唯一键、正反向游标、快照校验、数据库 seek 条件和可恢复批处理统一为一套与数据库、Web 框架无关的行为契约。

它解决的不是“把数组切成若干页”，而是数据持续变化时 offset 分页可能重复或漏读、各项目自行编码游标容易产生不兼容行为的问题。

## 项目目标

MoonPageFlow 负责分页语义层，而不是数据库连接层：应用声明排序和数据版本，库产生稳定页面、可传输游标与数据库 seek 计划。这样 HTTP API、GraphQL resolver、ORM 适配器和离线任务可以共享同一套边界行为。

## 核心能力

- Int64、String、Bool、Null 复合排序键，支持升降序及显式 NULL 位置；
- 自动追加唯一记录 ID，确保相同业务排序值仍有全序；
- 带版本、排序元数据、快照和校验和的 URL-safe 不透明游标；
- `first/after` 与 `last/before` 双向排页及完整 PageInfo；
- 将游标边界编译为与数据库无关的字典序 seek 分支；
- 快照漂移、游标损坏、排序不一致、重复 ID 和资源上限的结构化错误；
- 可持久化的批处理检查点，以及重复游标/重复记录保护；
- offset 兼容入口和遍历审计器，用于迁移前后行为对照。
- 稳定 O(n log n) 内存参考排序器，以及数据库适配结果预言机。

## 快速开始

```bash
moon add TangShiJi/moonpageflow@0.1.0
```

```moonbit
let rows = [
  @moonpageflow.page_row("event-2", [
    ("created_at", @moonpageflow.int_value(300L)),
  ]).unwrap(),
  @moonpageflow.page_row("event-1", [
    ("created_at", @moonpageflow.int_value(300L)),
  ]).unwrap(),
]
let sort = [
  @moonpageflow.sort_field("created_at", direction=@moonpageflow.Descending),
]
let page = @moonpageflow.paginate(
  rows,
  sort,
  @moonpageflow.first_page(limit=20).unwrap(),
  snapshot=Some("events-revision-42"),
).unwrap()

for row in @moonpageflow.page_rows(page) {
  println(row.id())
}
```

完整最小示例可以直接运行：

```bash
git clone https://github.com/TangShiJi/moonpageflow.git
cd moonpageflow
moon run examples/quickstart
```

预期输出前两条同时间事件、`has_next=true` 和可继续请求的不透明游标。`examples/activity_feed`、`examples/database_seek`、`examples/batch_export` 分别覆盖动态列表、数据库/ORM 条件适配和断点续传导出；`cmd/main` 一次运行三个场景。

## 常用 API

| 任务 | API |
|---|---|
| 声明记录和排序 | `page_row`、`sort_field` |
| 正向/反向请求 | `first_page`、`last_page` |
| 内存参考分页 | `paginate`、`page_rows` |
| 数据库条件适配 | `build_seek_plan`、`verify_seek_ids` |
| 批处理恢复 | `traversal_checkpoint`、`advance_checkpoint` |
| 迁移行为审计 | `paginate_offset`、`audit_traversal` |

错误使用 `PageErrorKind` 分类，宿主可以稳定映射为 HTTP、GraphQL 或任务状态。详细语义和适配步骤见 [API 使用指南](docs/api-guide.md)。

## 本地验证

```bash
moon fmt --check
moon check --target native --deny-warn
moon build --target native --deny-warn
moon test --target native --deny-warn
moon check --target wasm-gc --deny-warn
moon build --target wasm-gc --deny-warn
moon test --target wasm-gc --deny-warn
moon coverage analyze
moon package --list
```

CI 在 Windows 和 Ubuntu 上执行检查、构建、66 项测试、示例、覆盖率分析和发布包检查。验收标准见 [ACCEPTANCE_CRITERIA.md](ACCEPTANCE_CRITERIA.md)，设计见 [docs/design.md](docs/design.md)，兼容边界见 [COMPATIBILITY.md](COMPATIBILITY.md)，安全边界见 [SECURITY.md](SECURITY.md)。

## 明确边界

本库不连接数据库、不解析 SQL、不实现 ORM/GraphQL 服务器，也不替宿主决定事务隔离级别。游标校验和只发现误改，不承担鉴权或防伪；对外暴露游标时，应用可在其外层增加 MAC 或签名。内存参考分页器用于行为验证和小数据集；大数据集应由适配器把 `SeekPlan` 下推到数据库索引。

本项目采用 OSI 认可的 [MIT License](LICENSE)，为原创实现，未复制或移植第三方源码。
