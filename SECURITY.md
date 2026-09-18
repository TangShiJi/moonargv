# Security policy

## Supported version

Security and data-integrity fixes are applied to the latest published 0.x version. Until 1.0, minor releases may evolve APIs; cursor format changes must use a new explicit version and never be silently reinterpreted.

## Reporting

Please do not publish an exploit or sensitive production cursor in a public issue. Send a minimal reproduction to `t1622051617@qq.com`, including the MoonPageFlow version, MoonBit version, cursor version, sort declaration and target backend. Remove record contents, credentials and database connection details.

## Trust boundary

The built-in checksum detects accidental corruption only. It is not a MAC and does not authenticate callers. Services accepting cursors from untrusted clients must add an application-level keyed signature, validate authorization independently and enforce `PageLimits`. Snapshot values are supplied and trusted by the host application.
