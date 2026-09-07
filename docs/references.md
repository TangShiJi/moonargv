# 标准参考

MoonArgv 是原创实现，没有复制或移植第三方项目代码。解析规则依据以下公开规范和平台文档独立编写：

- POSIX.1-2024 Shell Command Language 2.2 Quoting：https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html
- Microsoft C command-line argument parsing：https://learn.microsoft.com/cpp/c-language/parsing-c-command-line-arguments

本项目只实现与 argv 边界有关的词法子集。POSIX 参数展开、命令替换、运算符和重定向，以及 `cmd.exe`、PowerShell 的上层语法均不在实现范围内。
