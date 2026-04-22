# Trae 运行时工具映射 · e2e-progress-notify

## Trae 下本 skill 的适用性

**Trae 下默认少用**。原因：
- Trae 是 IDE，研发同学的本地环境，通知没有直接目标（不像飞书话题有明确对象）
- 研发自己在 IDE 里，不需要通知自己

**何时用**：
- 研发用 Trae 做前置工作（需求澄清、PRD、代码分析）后，需要通知**别人**（PM、QA）
- 研发想在完成一个阶段后主动 broadcast 到团队群

## 依赖

同 OpenClaw：
- `feishu-cli-auth`
- `feishu-cli-msg`

前提：Trae 已通过 MCP 挂载这些 skill。

## 目标选择

Trae 下没有"当前话题"的概念，需要用户明确指定：
- 目标群名 / 话题 ID / 个人 email

**主动询问**：

```
Agent 在 Trae 下要发通知时：

"我注意到项目已经到了 [阶段]，是否需要通知飞书？
如果需要，请告诉我：
  - 目标（群名/话题 ID/@人的 email）
  - 通知内容摘要（我会自动扩展为卡片）"
```

## 避免打扰研发

Trae 主要是研发工具，Agent **不要主动**频繁发通知。

默认：
- 本 skill 在 Trae 下**不自动触发**
- 只在用户明确说"发个通知"时触发

## 网络

和 OpenClaw 一样，飞书 API 在公网可用。
