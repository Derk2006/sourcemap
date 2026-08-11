# 设计说明

## 目标

`Derk2006/sourcemap` 的目标是提供一个纯 MoonBit 的 Source Map v3 基础库。项目优先保证格式处理正确、错误可解释、API 边界清晰、测试可运行，并保持无外部运行时依赖，便于在 MoonBit 编译器实验、WASM 工具链和构建流程中复用。

## 模块划分

- `sourcemap.mbt`：公开数据模型、错误类型和构造器
- `vlq.mbt`：Base64 VLQ 编码解码
- `mappings.mbt`：Source Map `mappings` 字段解析和生成
- `json_codec.mbt`：Source Map v3 JSON 读写
- `query.mbt`：生成位置查询、反向查询和映射平移
- `validate.mbt`、`policy.mbt`：基础校验和策略化校验
- `stats.mbt`：统计摘要、源文件摘要和文本报告
- `builder.mbt`：自动维护 source/name 索引的构造器
- `index.mbt`、`span.mbt`：行索引、span 和 gap 分析
- `coverage.mbt`、`line_table.mbt`：覆盖率统计和生成代码文本行表
- `compose.mbt`：多阶段 Source Map 合成
- `range.mbt`：生成范围和原始范围裁剪
- `canonical.mbt`：去重、裁剪无用索引和排序
- `lint.mbt`：发布前质量门禁和 CI 报告
- `trace.mbt`：VLQ 与 mappings 追踪调试
- `diff.mbt`、`names.mbt`：差异分析和名称引用分析
- `fixtures.mbt`：稳定测试数据
- `cmd/main`：可运行示例

## 技术路线

Source Map 的核心难点在 `mappings` 字段。项目先通过 Base64 VLQ 解码得到相对字段，再按 Source Map v3 的增量规则恢复绝对位置。生成时反向执行差分编码，并按生成行列排序，输出稳定的 `mappings` 字符串。

JSON 层使用 MoonBit 标准库 `moonbitlang/core/json`，不引入第三方解析器。所有面向用户的解析函数返回 `Result`，把 JSON、VLQ 和字段错误转换为项目内的 `SourceMapError`，避免调用方只能处理运行时崩溃。

查询层保留解码后的 `MappingSegment`，提供生成位置到原始位置、原始位置到生成位置的查询。索引、span 和 coverage 模块围绕同一数据结构提供更适合构建报告和 CI 的派生视图。

合成层把后一阶段 Source Map 的原始位置当作前一阶段 Source Map 的生成位置查询，生成最终指向原始源码的新 map。未能合成的片段可以保留中间映射，也可以转为 unmapped，适合不同构建工具策略。

裁剪层采用半开区间，支持按生成代码范围和原始源码范围保留映射，并在裁剪后自动清理无用 sources 和 names。

## 功能边界

当前版本专注普通单文件 Source Map v3。不实现 `sections` 索引型 Source Map，不读取外部源码文件，不做远程下载，不提供非 MoonBit 运行时绑定层。后续可以在不破坏现有 API 的前提下增加独立模块。

## 验证策略

测试覆盖 VLQ 正反向转换、非法字符、截断输入、mappings 解析生成、JSON 往返、字段缺失、位置查询、反向查询、校验错误、统计报告、builder、索引、span、coverage、line table、合成、裁剪、lint、fixture 数据和示例 smoke test。

验收命令：

```bash
moon check
moon build
moon test
moon run cmd/main
moon publish --dry-run
```
