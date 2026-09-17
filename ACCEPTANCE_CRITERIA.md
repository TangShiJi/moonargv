# MoonPageFlow 验收标准

以下 P0 条目均有同名自动化测试，测试数量和源码行数仅作为佐证，不替代行为验收。

| ID | 可观察输入 | 必须输出/行为 |
|---|---|---|
| P0-ORDER-01 | 多条记录业务排序值相同 | 自动以唯一 ID 建立确定全序，不依赖输入顺序 |
| P0-CURSOR-01 | Unicode、NULL、升降序组成的复合位置 | 编码后解码得到完全相同的位置、排序元数据和快照 |
| P0-CURSOR-02 | 任意改动合法游标的校验字段 | 返回 `CursorChecksumMismatch`，不得继续查询 |
| P0-PAGE-01 | 相同数据分别请求首页与末页 | `first/after` 和 `last/before` 均采用排他边界并给出正确 PageInfo |
| P0-MUTATION-01 | 取首屏后在边界之前插入记录 | keyset 后续页不得重复首屏记录，完整遍历原基线不得漏读 |
| P0-SNAPSHOT-01 | 游标快照为 v1、后续请求快照为 v2 | 返回 `SnapshotMismatch` |
| P0-SEEK-01 | k 个业务排序键及唯一 ID | 输出 k+1 个字典序分支，反向页标明反转查询顺序 |
| P0-ADAPTER-01 | 数据库/ORM 适配器返回的 ID 序列 | 与内存参考预言机逐项比对，显式报告次序或成员不一致 |
| P0-RESUME-01 | 恢复任务收到相同结束游标 | 返回游标未前进错误，不得静默死循环 |
| P0-LIMIT-01 | 页大小超过宿主上限 | 在分页前返回结构化超限错误 |

完整验收命令：

```bash
moon fmt --check
moon check --target native
moon test --target native
moon check --target wasm-gc
moon test --target wasm-gc
moon run cmd/main
pwsh -File tools/source-metrics.ps1
```

Windows 与 Ubuntu 使用相同锁定版本工具链执行上述构建和测试。CI 页面：<https://github.com/TangShiJi/moonpageflow/actions/workflows/ci.yml>。
