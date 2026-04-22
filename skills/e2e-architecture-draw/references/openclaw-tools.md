# OpenClaw 运行时工具映射 · e2e-architecture-draw

## 依赖的底层 skill

- `feishu-cli-auth` —— 飞书认证前置
- `feishu-cli-board` —— 核心：创建/更新飞书白板
- `feishu-cli-msg` —— 可选：把白板链接发到话题

## feishu-cli-board 的能力

根据 `feishu-cli-board` skill 的文档（见本地 `~/.agents/skills/feishu-cli-board/`），它支持：

- 创建新白板
- 导入 Mermaid 源码 → 可视化组件
- 导入 PlantUML 源码 → 可视化组件
- 批量添加节点和连线
- 分享给用户或群

## 调用方式

```
让 feishu-cli-board skill 执行 import-mermaid 操作：
- mermaid_source: <本 skill 生成的 mermaid 代码>
- title: "用户分层项目-服务调用链"
- parent_folder: "端到端交付产出"（可选，默认根目录）
```

## 权限设置

新建的白板默认权限由 `feishu-cli-board` 决定。如果需要特定权限：

```
让 feishu-cli-perm skill 设置权限：
- resource: 白板 ID
- viewers: [相关人 email 列表]
- commenters: [PM、QA 的 email]
```

## 话题集成

白板创建后，OpenClaw 场景下自动把链接发到话题：

```
创建白板 → 拿到 URL → 
调 feishu-cli-msg 发到话题：
"📊 架构图已上传：[URL]"
```

## 失败降级

如果 `feishu-cli-board` 不支持 Mermaid 导入（罕见）：
- 先用公开 Mermaid 渲染器（如 mermaid.ink）生成 PNG
- 把 PNG 作为图片上传到白板
- 失去可编辑性但保留可视化

## 网络

`feishu-cli-board` 调用飞书 OpenAPI，需要公网。
