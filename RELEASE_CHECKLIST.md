# Release checklist

1. 更新 `moon.mod` 语义化版本和 `CHANGELOG.md`；
2. 运行格式、native/wasm-gc 的 check、build、test，所有警告视为错误；
3. 运行快速示例、覆盖率分析和 `moon package --list`，检查压缩包不含构建产物或凭据；
4. 确认 README 安装版本、仓库地址、MIT 许可证和安全边界；
5. 推送主分支并等待 Windows/Ubuntu CI 成功；
6. 执行 `moon publish --dry-run`，再执行 `moon publish`；
7. 在干净临时项目中 `moon add TangShiJi/moonpageflow@<version>` 并运行最小消费者；
8. 检查 mooncakes.io 包页面的 README、仓库、许可证和版本。
