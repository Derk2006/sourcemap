# 工单记录

## MZK-SM-001 建立 Source Map 基础模型

- 目标：定义 Source Map v3 数据结构、位置类型、mapping segment 和错误类型。
- 状态：已完成。
- 验证：纳入 `moon check` 和核心单元测试。

## MZK-SM-002 实现 VLQ 与 mappings 编解码

- 目标：实现 Source Map 使用的 Base64 VLQ 和 `mappings` 字段双向转换。
- 状态：已完成。
- 验证：覆盖正负数、连续值、非法字符、截断输入和 JSON 往返。

## MZK-SM-003 实现查询、校验和统计报告

- 目标：提供生成位置查询、原始位置反查、校验诊断、统计摘要和文本报告。
- 状态：已完成。
- 验证：覆盖正常查询、未映射查询、越界索引、排序检查和报告 smoke test。

## MZK-SM-004 完善构建工具辅助能力

- 目标：提供 builder、行索引、span、coverage、trace、diff、name 分析和策略化校验。
- 状态：已完成。
- 验证：覆盖 source/name 去重、span gap、覆盖率、trace 输出、diff 和 policy。

## MZK-SM-005 增加发布前工具链能力

- 目标：提供多阶段 Source Map 合成、范围裁剪、canonical 清理、line table 和 lint。
- 状态：已完成。
- 验证：覆盖合成、裁剪、未解析映射、文本行表、lint 阈值和 fixture 数据。

## MZK-SM-006 完成文档、CI 和发布准备

- 目标：整理 README、申报书、设计说明、调研记录、变更记录、CI 和许可证。
- 状态：已完成。
- 验证：`moon check`、`moon build`、`moon test`、`moon run cmd/main` 通过。
