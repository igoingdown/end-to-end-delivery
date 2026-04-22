# OpenClaw 运行时工具映射 · e2e-prd-share

## 依赖的底层 skill

- `feishu-cli-auth` —— 飞书认证
- `feishu-cli-msg` —— 发消息 + 发文件（核心依赖）

## 核心调用：feishu-cli-msg 的文件发送能力

根据 `feishu-cli-msg` skill 的文档，它支持发送多种消息类型：
- text
- interactive（卡片）
- **file（文件附件）** —— 本 skill 重点使用
- image
- post

### 文件发送调用

```
让 feishu-cli-msg 发送文件：
- target: <话题 ID / 群 ID>
- file_path: <本地 Markdown 路径>
- file_name: <展示给用户的文件名>  # 可选，默认用原文件名
```

### 卡片 + 文件的组合

OpenClaw 下 `feishu-cli-msg` 可能支持**单次消息组合发送**：
```
让 feishu-cli-msg 发送组合消息：
- parts:
    - { type: interactive, content: <卡片 JSON> }
    - { type: file, file_path: <PRD.md> }
```

如果不支持组合，就**先后发两条**：
```
1. 先发卡片
2. 再发文件（作为对卡片的回复 reply_to）
```

## 话题上下文

OpenClaw 场景下，Agent 在某个话题内运行，**目标话题**默认就是当前话题。

从 session context 拿 `thread_id`，不需要问用户。

## 权限

发文件到话题：发起话题的 Agent 和话题成员都有权限。

发文件到其他群：需要 Agent 用户本身是群成员。如果不是，`feishu-cli-msg` 会返回 "Not a group member"，本 skill `BLOCKED` 并让用户手工操作。

## 文件保留策略

飞书文件上传后**永久保留**（除非发送人删除）。所以：
- PRD 发到话题 → 可作为永久参考
- 不需要额外上传到云盘

## 网络

飞书 API 公网可用。
