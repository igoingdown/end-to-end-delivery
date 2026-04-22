# Trae 运行时工具映射 · e2e-deploy-pipeline

## Trae 下本 skill 的特殊性

**Trae 的主要用户是研发同学**，但**生产部署不是研发独立能做的事**——需要 TL 审批、需要 QA 信号。

因此在 Trae 下本 skill 的推荐流程：

```
研发在 Trae 里：
├─ 触发 e2e-deploy-pipeline
├─ BOE 部署在 Trae 里完成（研发熟悉 BOE）
├─ Trae 显示 PPE 工单 payload
└─ 引导研发切到飞书完成 PPE 工单（通知 TL 审批）
```

**关键**：Trae 不是 PPE 发布的理想入口。如果用户坚持在 Trae 里创建 PPE 工单，仍然支持，但要额外提醒"审批人会收到飞书通知，请确保 TA 已被告知"。

## Sensitive Operation 警告

Trae 里调用本 skill，**首次**就明确告知：

```
⚠️ e2e-deploy-pipeline 会产生真实的部署操作和工单。
在 Trae 里跑本 skill 等价于在 IDE 里动生产环境。
请确保你有权限，并已经和 TL 对齐。
```

避免研发在 Trae 里"顺手"触发部署。

## 依赖的底层 skill

同 OpenClaw（`bytedance-env` / `tce` / `tcc` / `bits`），前提是 Trae 已通过 MCP 挂载。

## Trae 优势：实时查看日志

Trae 是 IDE，可以：
- 实时 stream `bytedance-tce deploy` 的部署日志
- 在 terminal 里看到容器启动过程
- 方便 debug 失败

## 风险：Trae 的"自动化"诱惑

Trae 支持多 agent 编排，研发可能想写脚本"一键部署"。**本 skill 严格拒绝**：
- 每个 HARD-GATE 必须用户手动确认
- 不接受"批处理"式确认
- 不接受脚本绕过

任何试图绕过 HARD-GATE 的请求 → Agent 拒绝并警告。

## 结果呈现

Trae 下部署报告可以更详细：
- 完整的 tce deploy 日志
- 配置 diff 用代码块展示（IDE 高亮）
- 直接给出可点击的 BITS 工单链接
