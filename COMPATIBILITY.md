# 兼容性与语义边界

## 运行目标

- 必做并持续验证：MoonBit native、wasm-gc；
- CI 主机：Windows latest、Ubuntu latest；
- 编译器与 core：`0.10.9+6e6c44045`。

## 排序契约

- 支持 Int64、String、Bool 和 Null；不同非 Null 类型不能互比；
- 字符串按 Unicode 字符字典序比较，不采用数据库 locale/collation；数据库适配器必须选择等价 collation，或在进入本库前规范化键；
- NULL 位置由每个字段的 `NullsFirst/NullsLast` 显式决定，不依赖数据库默认值；
- 业务字段之后总是追加非空唯一字符串 ID；重复 ID 或缺失字段是错误；
- 游标中的字段名、方向和 NULL 策略必须与当前请求完全相同。

## 一致性契约

keyset 能避免“边界前插入导致下一页重复”这一类 offset 漂移，但不能自行冻结数据。需要强一致遍历时，宿主必须把事务版本、事件偏移或内容哈希传入 `snapshot`，并在后续请求使用同一值。库发现不一致即拒绝继续。

## 安全边界

游标是 URL-safe ASCII 且包含校验和；校验和只检测传输误改，不抵御伪造。把游标暴露到不可信边界的应用，应在外层使用带密钥的 MAC/签名并执行授权检查。
