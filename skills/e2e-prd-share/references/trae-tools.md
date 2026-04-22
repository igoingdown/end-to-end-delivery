# Trae 运行时工具映射 · e2e-prd-share

## Trae 下的适用性

**Trae 下默认不触发**。原因：
- Trae 是 IDE，PRD 是本地 Markdown 文件，研发同学直接打开看就行
- 只有当研发需要**通知别人**时，才需要本 skill

## 使用场景

Trae 下研发同学可能用本 skill 的时机：
- PRD 写完，需要发给 PM review
- 需要把 PRD 同步到飞书话题作为立档
- 跨团队协作，需要让非 Trae 用户看到 PRD

## 依赖

同 OpenClaw：
- `feishu-cli-auth`
- `feishu-cli-msg`

前提：Trae 已 MCP 挂载 feishu 相关 skill。

## 目标确定

Trae 下**必须**问用户目标（没有"当前话题"的概念）：

```
Agent: "要把 PRD 分享到哪里？
  - 话题 ID / 话题链接
  - 群名 / 群 ID
  - @某人的 email"
```

## 本地文件访问优势

Trae 直接读本地 Markdown 文件，不需要中间步骤：

```
PRD 路径：/Users/xxx/projects/user-segment/PRD-v1.0-20260419.md
Trae 直接读 → feishu-cli-msg 发送
```

OpenClaw 可能需要 workspace 路径，Trae 直接用用户的文件系统路径。

## 失败

- Markdown 路径错 → 让用户确认路径
- 飞书 API 失败 → 同 OpenClaw 处理

## 网络

飞书 API 公网可用。
