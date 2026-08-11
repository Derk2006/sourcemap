# Mooncakes 调研记录

调研日期：2026-08-11

## 检查范围

通过 Mooncakes 公开包索引检查以下关键词：

- `sourcemap`
- `source-map`
- `source map`
- `source_map`
- `vlq`
- `base64 vlq`
- `mappings`

同时检查拟发布包名：

```text
Derk2006/sourcemap
```

## 结论

上述关键词在 Mooncakes 公开包索引中未发现同类 Source Map v3 工具库命中，拟发布包名未发现已存在 manifest。项目方向不是对现有 MoonBit 包做轻微差异化，而是补充 Source Map v3 这一编译器和构建工具常用格式的原生基础库能力。

## 功能边界

本项目聚焦 Source Map v3 的 VLQ、mappings、JSON、查询、校验、统计、合成、裁剪和 lint，不实现通用 JSON 库、通用编译器框架或文件监听工具，避免与其他基础能力发生功能重复。
