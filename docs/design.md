# MoonArgv 设计说明

## 分层边界

MoonArgv 分为五层：词法层在文本和 argv 之间转换；响应文件层处理嵌套参数载荷；环境层合并并校验宿主快照；候选与审计层生成 PATH/PATHEXT 探测顺序并隐藏秘密；契约层用 `prepare_execution` 一次产出宿主需要的全部纯数据。库不启动进程，也不实现 shell 展开、CLI 选项语义或任务 DAG。

## POSIX 词法

POSIX 模式识别空白、单引号、双引号和反斜杠。单引号内字符全部按字面量处理；双引号中的反斜杠只转义双引号、反斜杠、美元符号、反引号和换行；引号片段可与普通片段拼接。未闭合引号和末尾反斜杠返回含字符位置的错误。序列化优先保留安全字符，其他参数用单引号表示，内部单引号使用可逆的分段引用。

## Windows CRT 词法

Windows 模式保留普通路径反斜杠。引号前连续反斜杠按奇偶处理：偶数个产生一半反斜杠并切换引号状态，奇数个产生一半反斜杠和字面双引号。序列化在必要时添加外层双引号，对内部双引号前的反斜杠和结尾反斜杠进行成倍处理，从而满足 `parse_windows(join_windows(argv)) == argv`。

## 资源限制

`parse_limited` 在同一解析规则上增加最大参数数和最大单参数字符数，适合处理响应文件、任务配置或外部输入。长度按 Unicode 字符而不是 UTF-16 单元计算。

## 响应文件与进程规划

`expand_response_files` 从宿主提供的“路径—文本”映射递归展开 `@path`，支持 `@@` 字面转义，并检测文件缺失、引用环、嵌套深度、最终参数数和单参数长度。读取文件仍由宿主负责，因此 wasm-gc 与 native 共享同一确定性核心。

`plan_invocation` 根据渲染后的字符数决定直接返回完整 argv，还是返回 `[program, @path]` 与待写入的 `ResponseArtifact`。调用方可以先写文件再启动进程；MoonArgv 不取得文件系统或进程副作用权限。

## 环境、候选路径与审计

`apply_environment` 对调用方捕获的基础环境执行有序 set/remove。POSIX 使用原始键比较，Windows 使用小写比较键，避免 `Path` 和 `PATH` 并存。输出稳定排序便于生成日志、缓存输入和测试快照；敏感位仅影响审计视图，不破坏执行值。

`executable_candidates` 把已经拆分的 PATH 与 PATHEXT 转成有序候选，不访问文件系统。显式路径跳过 PATH，Windows 候选按大小写去重。`redact_arguments` 在逻辑 argv 层处理独立值和赋值型 option，再调用已有 quoting 生成可复制但不泄密的审计命令。

## 统一执行契约

`ExecutionSpec` 声明命令、工作目录、环境 overlay、stdin 和秘密规则；`prepare_execution` 选择一致的平台语义，先校验资源限制，再组合 `EnvironmentPlan`、`ExecutablePlan`、`InvocationPlan` 和审计命令。宿主只需探测候选、写可选响应文件并 spawn，避免在每个工具中重复边界逻辑。

## 不变量

- 同一方言下，任意测试覆盖的 argv 经 `join` 后可被 `parse` 无损恢复；
- 引号和转义不会触发命令执行或变量展开；
- 普通 Windows 路径中的反斜杠不会被误删；
- 所有解析错误和资源限制错误都带可定位的字符偏移；
- 响应文件计划再次展开后等于原始 `CommandLine::arguments()`；
- 环境 overlay 在同一平台比较规则下没有重复键，输出顺序稳定；
- 脱敏只改变审计副本，绝不改变交给执行端的 argv 和环境值；
- 同一个 `ExecutionTarget` 同时决定 quoting、环境键和路径规则，不能混用平台方言；
