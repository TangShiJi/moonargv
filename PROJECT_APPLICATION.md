# MoonArgv 项目申报书

**基本信息**

- **项目名称：** MoonArgv——跨平台命令调用契约与进程规划库
- **参赛者：** 唐仕吉
- **联系方式：** 邮箱：t1622051617@qq.com；手机号：13384247418
- **GitHub 仓库链接：** https://github.com/TangShiJi/moonargv
- **项目方向：** MoonBit 开发工具基础设施 / 跨平台进程调用契约
- **项目性质：** 原创项目，非移植；MIT License

**项目简介与生态定位**

构建工具、测试框架和代码代理启动外部程序时，不只要“传 argv”，还要处理配置文本的引号边界、Windows CRT、长命令响应文件、PATH/PATHEXT、环境变量大小写、工作目录和日志脱敏。把这些规则散落在各宿主适配器中会产生只在特定系统复现的参数失真和令牌泄露。MoonArgv 提供无 IO 的 `ExecutionSpec → PreparedExecution` 契约层：输入逻辑调用，输出 argv/响应文件、环境快照、可执行文件候选和脱敏审计命令，再由现有 process 库执行。

标准库 `argparse` 在程序内部解释已切分 argv；process/subprocess 库负责真正启动与管理进程；任务运行器负责 DAG 和缓存。本项目不重复这些能力，而是补齐三者之间缺少的、可跨 native 与 wasm-gc 测试的调用准备层。常见的 shell 拼接会引入展开和注入语义，仅直接 spawn 又无法统一响应文件、环境覆盖和审计行为，因此采用纯数据契约与分别实现的 POSIX/Windows 状态机。

**项目方向与通用性**

API 不绑定编译器、CLI 框架或进程后端，可供构建系统、任务运行器、IDE/测试工具、代码代理和部署工具复用；同一调用可在 Web/Wasm 中预检，在 Windows/Linux 宿主执行。

**预期使用场景**

1. **大型构建：** 输入编译器、数百个源文件和输出路径；超长时生成 `moonc @compile.rsp` 及可逆内容，宿主写文件后启动，循环或超限提前拒绝。
2. **跨平台任务执行：** 输入程序名、PATH/PATHEXT、工作目录和环境覆盖；输出有序候选路径及 POSIX/Windows 环境快照，Windows 的 `Path/PATH` 按同一键处理。
3. **代理与部署审计：** 输入含 `--token value`、`--header=value` 及敏感环境变量的调用；真实 argv 保留给执行端，日志视图固定脱敏，确保密钥不进入构建日志。
4. **配置接入 CLI：** 输入带引号的单字符串任务配置；先恢复程序名和 argv，再交给 `argparse` 解释 option，未闭合引号返回字符位置。

**拟实现的核心功能**

- POSIX quoting、Windows CRT 分词与可逆 argv 序列化，含错误位置和资源限制；
- 递归响应文件、循环/深度检测及长命令 `InvocationPlan`；
- POSIX/Windows 环境覆盖、删除、稳定排序、敏感值标记及数量/长度限制；
- PATH/PATHEXT 可执行候选规划、重复消除与显式路径识别；
- 参数位置、flag 后值、赋值型 option 和字面值脱敏；
- 统一执行规范，产出工作目录、stdin 策略、环境、候选路径、响应文件和安全审计视图。

**工程边界与验收**

不启动进程、不读写文件、不实现 shell 展开、任务 DAG 或 `argparse` 的 option 语义；宿主负责探测候选路径并执行。仓库现有 1,994 行生产 MoonBit 源码，其中排除空行及整行注释仍有 1,621 行；99 项测试和 1,500 组模糊样本作为佐证。13 项 P0 行为覆盖 POSIX、Windows CRT、响应文件、环境、查找、脱敏和完整契约，必须在 Windows/Ubuntu 的 native、wasm-gc 全部通过。

**原创或参考说明**

项目为原创实现，未复制或移植第三方源码；POSIX.1-2024 与 Microsoft CRT 文档仅作行为规范。2026-09-15 全量检查 Mooncakes 2,488 个模块，无同名或覆盖上述完整契约的项目。`bobzhang/myshell`、`proton_process`、`sennenki/process`、`trkbt10/subprocess` 负责执行，`FrenchPicnic/which` 负责实际查找，CLI parser 负责选项语义；这些项目均未同时提供双平台 argv、响应文件、环境覆盖、候选规划和脱敏审计，详细对照见 `docs/ecosystem-audit.md`。
