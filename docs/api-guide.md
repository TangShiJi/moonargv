# API 使用指南

## 1. 建立稳定全序

`PageRow` 的 `id` 必须非空且全局唯一。`SortField` 只声明业务键；MoonPageFlow 总会把 ID 作为最终升序 tie-breaker。每个字段都明确方向和 NULL 位置，避免依赖数据库默认行为。

```moonbit
let sort = [
  @moonpageflow.sort_field(
    "created_at",
    direction=@moonpageflow.Descending,
    nulls=@moonpageflow.NullsLast,
  ),
  @moonpageflow.sort_field("priority"),
]
```

数据库 collation 必须与库的 Unicode 字符字典序一致；不一致时，应在应用层生成规范化排序键。

## 2. API 页面

第一页使用 `first_page(limit=...)`，后续把 `PageInfo::end_cursor()` 作为 `after`。反向页面使用 `last_page` 与 `start_cursor()`。边界是排他的，同值业务键由 ID 保证不重复。

宿主若需要一次遍历的一致视图，应把事务版本、事件偏移或内容哈希传给 `snapshot`。后续请求必须使用相同值；不一致返回 `SnapshotMismatch`。

## 3. 数据库/ORM 适配

1. 从游标解码 `PagePosition`；
2. 调用 `build_seek_plan(position, sort, mode)`；
3. 将每个 `SeekBranch` 映射为参数化比较条件，将分支以 OR 组合；
4. 按声明顺序查询 `limit + 1` 条，反向模式按 `reverse_query_order` 处理；
5. 在适配器测试中用 `verify_seek_ids` 对照内存预言机。

不要把值直接拼进 SQL。MoonPageFlow 有意不返回 SQL 字符串，以便适配器使用自己驱动的参数类型、占位符和 NULL 语义。

## 4. 可恢复遍历

`TraversalCheckpoint` 保存快照、结束游标、已处理页数/记录数和已见 ID。每处理成功一页后调用 `advance_checkpoint` 再持久化；重启时调用 `restore_checkpoint`。重复游标、重复记录或快照漂移会中止任务，而不是继续生成不完整结果。

## 5. 错误映射

- 请求错误：`InvalidPageSize`、`InvalidOffset`、`CursorTooLong`；
- 数据契约错误：`EmptyRowId`、`DuplicateRowId`、`MissingSortValue`；
- 游标错误：`InvalidCursor`、`CursorChecksumMismatch`、`CursorSortMismatch`；
- 一致性错误：`SnapshotMismatch`、`RepeatedCursor`、`DuplicateTraversalItem`。

对不可信客户端统一返回安全的错误码即可；详细 `message()` 适合日志，不应包含数据库凭据或记录内容。
