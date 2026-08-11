# 版本发布记录

## 0.1.0

发布日期：2026-08-11

发布目标：

- 提供 MoonBit 原生 Source Map v3 基础能力。
- 支持 Mooncakes 包 `Derk2006/sourcemap` 的首次发布。
- 满足构建、测试、示例、README、CI、许可证和过程记录要求。

主要功能：

- Base64 VLQ 编解码。
- Source Map `mappings` 编解码。
- Source Map v3 JSON 读写。
- 位置查询、反向查询、合成、裁剪、校验、统计、lint 和报告。

发布前检查：

- 有效 MoonBit 代码行数超过 4000 行。
- Git 提交记录超过 5 次，且每次提交对应真实功能或工程材料。
- 公开包名和方向已做 Mooncakes 非重复调研。
- 项目使用 MIT 许可证。

后续维护方向：

- 增加 `sections` 索引型 Source Map 支持。
- 增加更细粒度的覆盖率统计。
- 增加更多构建工具示例。
