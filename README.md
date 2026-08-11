# Derk2006/sourcemap

`Derk2006/sourcemap` 是一个 MoonBit 原生 Source Map v3 工具库，提供 Base64 VLQ 编码解码、`mappings` 字段解析与生成、Source Map JSON 读写、位置查询、多阶段映射合成、范围裁剪、覆盖率统计、质量 lint 和可读报告。

Source Map 是编译器、代码生成器、打包器、压缩器和 WASM 工具链常用的调试映射格式。本项目把这类能力做成可测试、可复用、无外部运行时依赖的 MoonBit 基础库，便于 MoonBit 生态中的编译器实验、构建工具和调试工具直接复用。

## 安装

```bash
moon add Derk2006/sourcemap
```

Mooncakes 包名：

```text
Derk2006/sourcemap
```

## 快速示例

```mbt
test {
  let map = @sourcemap.SourceMap::SourceMap(
    ["src/main.mbt"],
    [@sourcemap.MappingSegment::mapped(0, 0, 0, 3, 2, name_index=0)],
    names=["main"],
  )
  inspect(
    map.explain_generated(0, 4),
    content="generated 0:4 -> src/main.mbt:3:2 name=main",
  )
}
```

## 本地运行

```bash
moon check
moon build
moon test
moon run cmd/main
moon publish --dry-run
```

## 核心能力

- Base64 VLQ：`encode_vlq`、`decode_vlq`、`encode_vlq_values`、`decode_vlq_values`
- mappings 编解码：`decode_mappings`、`encode_mappings`、`SourceMap::encoded_mappings`
- JSON 读写：`SourceMap::from_json_string`、`SourceMap::to_json_string`
- 位置查询：`find_original`、`find_generated`、`explain_generated`
- 校验诊断：`validate`、`errors`、`warnings`、`ValidationPolicy`
- 统计报告：`stats`、`source_summaries`、`report`
- Builder：`SourceMapBuilder` 自动维护 source/name 索引并支持合并片段
- 索引与 span：`index`、`spans`、`gaps_for_line`、`span_at`
- 范围裁剪：`GeneratedRange`、`OriginalRange`、`slice_generated_range`、`slice_original_range`
- 多阶段合成：`compose_with`、`compose_chain`、`compose_report`
- 质量门禁：`SourceMapLintOptions`、`lint`、`lint_summary`、`lint_report`
- 覆盖率：`coverage_for_lengths`、`coverage_for_text`、`coverage_text_report`
- 名称分析：`name_uses`、`name_frequency`、`name_report`
- 差异分析：`diff`、`SourceMapDiff::summary`
- 追踪调试：`trace_vlq`、`trace_mappings`、`trace_mappings_report`

## 适用场景

- MoonBit 编译器实验和代码生成器输出 Source Map
- 构建工具在 CI 中检查 `sources`、`names`、`ignoreList` 和 `mappings` 的一致性
- 打包器或压缩器把多阶段 Source Map 合成为最终调试映射
- 调试工具根据生成代码位置反查原始源码位置
- 发布前裁剪 Source Map，只保留某个 bundle 片段或某个源文件区间
- 构建报告统计每个源文件的映射覆盖情况

## 支持范围

- Source Map v3 普通单文件 map
- `version`、`file`、`sourceRoot`、`sources`、`sourcesContent`、`names`、`mappings`、`ignoreList`
- 1 字段、4 字段和 5 字段 mapping segment
- 生成位置到原始位置的最近段查询
- 原始位置到生成位置的同源同线最近段查询
- 多阶段 Source Map 合成
- 生成范围和原始范围裁剪
- CI lint、覆盖率报告和文本行表分析

## 暂不支持范围

- `sections` 索引型 Source Map
- 读取外部源码文件或远程 Source Map
- 字符集探测和文件系统路径规范化
- 与非 MoonBit 运行时的绑定层

## 开源与合规

本项目采用 MIT 许可证。项目为原创 MoonBit 实现，不移植第三方源代码，不包含来源不明素材或私有代码。实现依据 Source Map v3 公开格式描述完成，核心功能全部使用 MoonBit 编写。

## 工程记录

- 设计说明：`docs/DESIGN.md`
- Mooncakes 非重复调研：`docs/MOONCAKES_RESEARCH.md`
- 工单记录：`docs/WORKLOG.md`
- 测试记录：`docs/TEST_RECORD.md`
- 版本发布记录：`docs/RELEASE_NOTES.md`
- 更新日志：`CHANGELOG.md`
