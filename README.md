# MoonPageFlow

MoonPageFlow 是面向 MoonBit 服务端、SDK 与数据工具的稳定游标分页内核。它把复合排序、唯一键、正反向游标、快照校验、数据库 seek 条件和可恢复批处理统一为一套与数据库、Web 框架无关的行为契约。

它解决的不是“把数组切成若干页”，而是数据持续变化时 offset 分页可能重复或漏读、各项目自行编码游标容易产生不兼容行为的问题。

## 已完成的 MVP

- Int64、String、Bool、Null 复合排序键，支持升降序及显式 NULL 位置；
- 自动追加唯一记录 ID，确保相同业务排序值仍有全序；
- 带版本、排序元数据、快照和校验和的 URL-safe 不透明游标；
- `first/after` 与 `last/before` 双向排页及完整 PageInfo；
- 将游标边界编译为与数据库无关的字典序 seek 分支；
- 快照漂移、游标损坏、排序不一致、重复 ID 和资源上限的结构化错误；
- 可持久化的批处理检查点，以及重复游标/重复记录保护；
- offset 兼容入口和遍历审计器，用于迁移前后行为对照。

## 快速开始

```bash
moon add TangShiJi/moonpageflow
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
```

运行可执行示例：

```bash
moon run cmd/main
moon test
moon test --target wasm-gc
```

`examples/activity_feed`、`examples/database_seek`、`examples/batch_export` 分别覆盖动态列表、数据库/ORM 条件适配和断点续传导出。验收标准见 [ACCEPTANCE_CRITERIA.md](ACCEPTANCE_CRITERIA.md)，设计与边界见 [docs/design.md](docs/design.md)。

## 明确边界

本库不连接数据库、不解析 SQL、不实现 ORM/GraphQL 服务器，也不替宿主决定事务隔离级别。游标校验和只发现误改，不承担鉴权或防伪；对外暴露游标时，应用可在其外层增加 MAC 或签名。内存参考分页器用于行为验证和小数据集；大数据集应由适配器把 `SeekPlan` 下推到数据库索引。

License: MIT
