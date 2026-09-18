# 0.1.0 质量验证记录

验证日期：2026-09-18。

- `moon fmt --check`：通过；
- native：`check`、`build`、66 项测试通过，编译警告按错误处理；
- wasm-gc：`check`、`build`、66 项测试通过，编译警告按错误处理；
- `moon run examples/quickstart` 与 `moon run cmd/main`：通过；
- `moon coverage analyze`：剩余 44 个未覆盖分支行，较首次审计的 116 行减少 62%；
- `moon package --list`：成功生成 `TangShiJi-moonpageflow-0.1.0.zip`，未包含 `_build`、凭据或生成接口文件；
- 核心有效 MoonBit 源码 1,638 行，测试有效代码 1,025 行。

重点覆盖路径包括复合键/NULL/升降序、同值 ID 兜底、正反向边界、数据插入漂移、快照不一致、游标损坏和畸形字段、Int64 边界、资源上限、适配器结果对照、检查点恢复，以及 2,048 条逆序输入的归并排序。

覆盖率工具按“未覆盖分支起始行”报告，不把该数字误写为行覆盖百分比。剩余项主要是前置校验后理论上不可达的错误转发分支和可执行示例的 `main` 输出路径；示例由 CI 直接运行。
