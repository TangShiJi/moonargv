# Mooncakes 生态查重记录

核查日期：2026-09-17。核查范围：mooncakes.io 当日 2,504 个公开模块的名称、描述、README/文档检索。查询词包括 `cursor pagination`、`keyset pagination`、`seek pagination`、`opaque cursor`、`page token`、`continuation token`、`stable pagination`、`PageInfo`，并检查 `pagination`、`cursor`、`GraphQL`、`ORM` 相关结果。

| 模块 | 实际能力 | 与 MoonPageFlow 的边界 |
|---|---|---|
| `oboard/morm@0.4.1` | ORM 内的页码/offset、COUNT 和 Page<T> | 绑定其 ORM，仍是 offset；无独立 keyset 游标、快照或恢复检查点 |
| `moonbitstack/moondb` | 数据库连接上的前向流式 Row Cursor | 解决有状态取行/内存占用，不是跨 HTTP 请求的页面令牌 |
| `marianoguerra/slack@0.4.2` | Slack SDK 内部消费服务端 next cursor | 绑定 Slack 协议，不提供通用排序、seek 或审计 |
| `moonbitstack/moongql@0.8.1` | GraphQL schema、校验和执行 | 可在 resolver 中使用本项目，但其本身不是分页引擎 |
| `bobzhang/pagelayout@0.1.1` | 文档页面布局 | 同名词不同领域 |

结论：未发现与“数据库无关的复合 keyset + 双向不透明游标 + 快照保护 + 可恢复遍历”高度重合的独立 MoonBit 包。本项目若发布前出现同类包，将补做 API/行为差分并如实更新申报书；本记录不把一次检索当成永久结论。
