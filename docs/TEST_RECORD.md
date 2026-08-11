# 测试记录

## 2026-08-11

测试环境：

- MoonBit：`moon 0.1.20260724`
- 包名：`Derk2006/sourcemap`
- 目标：`wasm`

执行命令：

```bash
moon check
moon build
moon test
moon run cmd/main
moon publish --dry-run
```

结果：

- `moon check`：通过。
- `moon build`：通过。
- `moon test`：94 个测试全部通过。
- `moon run cmd/main`：示例成功输出 SourceMap report 和位置解释。
- `moon publish --dry-run`：本地 check、打包、解包后 check 均通过；远程 API 访问在当前命令环境中连接关闭，需要在已登录 Mooncakes 环境中再次执行发布。

覆盖范围：

- Base64 VLQ 编码解码。
- Source Map `mappings` 解析和生成。
- Source Map JSON 读写。
- 生成位置查询和原始位置反查。
- 校验诊断、策略化校验和 lint。
- builder、索引、span、gap 和 coverage。
- 多阶段合成、范围裁剪、canonical 清理。
- line table、trace、diff、name 分析和 fixture 数据。
