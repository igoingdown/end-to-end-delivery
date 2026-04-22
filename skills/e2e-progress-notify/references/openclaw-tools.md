# OpenClaw 运行时工具映射 · e2e-progress-notify

## 依赖的底层 skill

- `feishu-cli-auth` —— 飞书登录前置
- `feishu-cli-msg` —— 实际发消息（卡片或文本）

## 调用方式

```
让 feishu-cli-msg skill 发送消息：
- to: 目标（话题 ID / 群 ID / 用户 email）
- type: interactive（卡片）或 text（文本）
- content: 卡片 JSON 或文本内容
```

## 卡片 vs 文本选择

`feishu-cli-msg` 支持多种消息类型：
- `interactive` —— 卡片，推荐
- `text` —— 纯文本，简单场景
- `post` —— 富文本（飞书私有格式）
- `image` —— 图片（本 skill 不用）
- `file` —— 文件（本 skill 不用）

**默认用 interactive**。如果卡片格式出错，fallback 到 text。

## OpenClaw 话题场景

OpenClaw 通过飞书机器人入口，Agent 正在对话的**话题**本身就是一个发消息目标。

**自动获取话题 ID**：
- OpenClaw 传入的 session context 里包含 `thread_id`
- 直接用 `thread_id` 作为 `to` 参数

不需要问用户"发到哪里"，默认发到当前话题。

## @人机制

飞书卡片的@人需要用户的 `open_id` 或 `email`。

**获取方式**：
- 从 PRD / BITS 元信息里直接有 email → 直接用
- 只有姓名没 email → 调 `feishu-cli-toolkit` 查用户

## 网络

`feishu-cli-msg` 调用飞书 OpenAPI，需要**公网**（飞书是 SaaS）。

**注意**：和 `bytedance-*` 不同，飞书调用在任何网络环境都可以（VPN 有无都行）。

## 失败降级

如果飞书完全不可用（极罕见）：
- Agent 在对话中文本提醒用户："通知本应发送给 @zhangsan，但飞书不可用，请手动通知"
- 不阻塞主流程
