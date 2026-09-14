# 贡献指南

提交修改前请先说明目标方言和对应规则，并同时提供正向解析、错误行为或往返不变量测试。POSIX 与 Windows 规则不得混用；涉及边界行为时，请在提交说明中给出最小输入和预期 argv。

本地检查：

```bash
moon fmt --check
moon check --target native
moon test --target native
moon check --target wasm-gc
moon test --target wasm-gc
moon run examples/build_pipeline/cmd/main
moon run --release bench/roundtrip
```

修改 Windows 行为时必须通过微软 CRT 对照表；修改分词或引用时必须通过 1,500 组固定模糊用例。性能敏感改动应运行 `tools/benchmark.ps1` 并与同机基线比较。

提交应围绕一个可说明的功能或修复，不接受空提交、重复生成文件或仅为增加提交数量的机械拆分。
