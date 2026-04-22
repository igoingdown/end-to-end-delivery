# Trae 运行时工具映射 · e2e-architecture-draw

## Trae 下的选择

Trae 是 IDE，有两种绘图路径：

### 路径 A：直接用 Markdown Mermaid（推荐）

Trae 的 Markdown 预览器原生支持 Mermaid 渲染。

```
本 skill 在 Trae 下默认生成 Markdown 文件，内嵌 Mermaid：

# 用户分层项目-服务调用链

\`\`\`mermaid
graph LR
    ...
\`\`\`

用户在 Trae 里直接打开预览即可看到图。
```

**优势**：
- 不需要外部服务
- 本地可编辑
- 和代码仓库一起 Git 管理

### 路径 B：上传到飞书白板（协作场景）

当研发需要让**非 Trae 用户**（PM、QA）看图时，仍然调 `feishu-cli-board`。

前提：`~/.agents/skills/feishu-cli-board/` 已通过 MCP 挂载。

## 推荐流程

Trae 用户：
```
1. 默认生成 Markdown + Mermaid（路径 A）
2. 问用户："需要也发到飞书白板吗？"
3. 如果需要 → 调 feishu-cli-board（路径 B）
4. 如果不需要 → 只保留 Markdown
```

## 工具差异

| 操作 | OpenClaw | Trae |
|---|---|---|
| 预览图 | 无（只能上传后在飞书看） | IDE 内 Markdown 预览 |
| 编辑图 | 飞书白板 | IDE + Markdown |
| 协作 | 飞书白板原生 | 需要上传到飞书 |

## 网络

- 路径 A（Markdown）：完全离线
- 路径 B（飞书）：需要公网
