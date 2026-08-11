# sourcemap 项目申报书

## 基本信息

- 项目名称：sourcemap：MoonBit 原生 Source Map v3 工具库
- 参赛者：苗张琨
- 联系方式：15176082079
- GitHub 账户：Derk2006
- 仓库链接：https://github.com/Derk2006/sourcemap
- Mooncakes 包名：Derk2006/sourcemap
- 项目类型：原创 MoonBit 开源库、开发工具基础组件
- 开源许可证：MIT

## 项目简介

`Derk2006/sourcemap` 实现一个 MoonBit 原生 Source Map v3 工具库，用于解析、生成、校验、查询和合成编译产物与原始源码之间的位置映射。项目面向编译器实验、代码生成器、WASM 构建链、前端资源管线和 CI 质量检查，补充 MoonBit 生态中 Source Map 基础能力。

## 现有基础

当前工程已经建立完整 MoonBit 模块结构，完成核心数据模型、Base64 VLQ、`mappings` 编解码、JSON 读写、位置查询、反向查询、校验诊断、统计报告、builder、索引、span、coverage、trace、policy、diff、name 分析、fixture 测试、多阶段合成、范围裁剪、line table 和 lint。项目提供可运行示例、README、设计说明、变更记录、Mooncakes 调研记录、MIT 许可证和 GitHub Actions CI。

## 本次计划新增内容

- 完善 Source Map v3 普通单文件 map 的完整读写与校验链路
- 提供多阶段 Source Map 合成能力，支持构建工具把中间产物映射回原始源码
- 提供生成范围与原始范围裁剪能力，适用于 bundle 片段发布和调试报告缩减
- 提供 CI lint、覆盖率统计、行表分析和可读报告
- 补充单元测试、白盒测试、fixture 测试和可运行示例
- 配置 CI，并按 Mooncakes 要求执行发布前 dry-run

## 预期目标和技术路线

项目以 MoonBit 作为主要实现语言，不依赖第三方运行时。技术路线分为五层：

1. 数据层：定义 `SourceMap`、`MappingSegment`、位置类型、诊断类型和错误类型。
2. 编码层：实现 Base64 VLQ 和 Source Map `mappings` 的双向转换。
3. 结构层：实现 JSON 读写、builder、索引、span、range、canonical 和 transform。
4. 分析层：实现查询、校验、覆盖率、lint、trace、diff、name 统计和报告。
5. 工程层：补充测试、示例、README、设计说明、CI 和 Mooncakes 发布配置。

## 预计完成功能、测试和文档

- 功能：Source Map v3 JSON 读写、VLQ 编解码、mappings 编解码、位置查询、反向查询、多阶段合成、范围裁剪、覆盖率统计、lint、报告输出。
- 测试：覆盖正常输入、错误输入、边界值、fixture 数据、builder 行为、JSON 往返、合成、裁剪、line table、lint 和示例 smoke test。
- 文档：README、设计说明、Mooncakes 非重复调研记录、变更记录、许可证和申报书。
- 验收命令：`moon check`、`moon build`、`moon test`、`moon run cmd/main`、`moon publish --dry-run`。

## 非重复性说明

已围绕 `sourcemap`、`source-map`、`source map`、`source_map`、`vlq`、`base64 vlq`、`mappings` 等关键词检查 Mooncakes 公开包索引，未发现同类 Source Map v3 工具库或拟发布包名 `Derk2006/sourcemap` 已存在。项目不是对已有 MoonBit 包做轻微差异化，而是补充 Source Map v3 这一编译器和构建工具常用格式的原生基础库能力。

## 开源合规

本项目为原创 MoonBit 实现，不移植第三方源代码，不包含私有代码、闭源代码、商业代码或来源不明素材。项目采用 OSI 认可的 MIT 许可证发布。
