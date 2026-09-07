# 贡献指南

提交修改前请先说明目标方言和对应规则，并同时提供正向解析、错误行为或往返不变量测试。POSIX 与 Windows 规则不得混用；涉及边界行为时，请在提交说明中给出最小输入和预期 argv。

本地检查：

```bash
moon fmt --check
moon check --target native
moon test --target native
moon check --target wasm-gc
moon test --target wasm-gc
```

提交应围绕一个可说明的功能或修复，不接受空提交、重复生成文件或仅为增加提交数量的机械拆分。
