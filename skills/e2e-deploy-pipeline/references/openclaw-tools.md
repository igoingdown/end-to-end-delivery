# OpenClaw 运行时工具映射 · e2e-deploy-pipeline

## 依赖的底层 skill

- `bytedance-auth` —— SSO 前置
- `bytedance-env` —— BOE/PPE 环境配置查询
- `bytedance-tce` —— 容器部署
- `bytedance-tcc` —— 配置中心
- `bytedance-bits` —— 发布工单 create-ticket

## 最关键的约束：不绕过 HARD-GATE

OpenClaw 下调用多个 skill 组合时，**务必**在每个 skill 之间停下等用户确认。

**禁止模式**：
```python
# ❌ 错误：连续调用，没有 HARD-GATE
bytedance-tce deploy
bytedance-tcc sync
bytedance-bits create-ticket
```

**正确模式**：
```python
# ✅ 每个操作独立 HARD-GATE
bytedance-tce deploy --dry-run  → HARD-GATE ①  → 用户确认  → 实际 deploy
bytedance-tcc sync --dry-run    → HARD-GATE ②  → 用户确认  → 实际 sync
# ... (用户在 BOE 验证) ...
bytedance-bits create-ticket --dry-run  → HARD-GATE ③  → 用户确认  → 实际 create
```

## 各 skill 的 dry-run 支持情况

| Skill | --dry-run 支持 | 说明 |
|---|---|---|
| `bytedance-tce` | ✅ 支持 | 返回部署计划的 JSON |
| `bytedance-tcc` | ✅ 支持 | 返回配置 diff |
| `bytedance-bits create-ticket` | ✅ 支持 | 返回工单 payload |

**如果某个 skill 不支持 `--dry-run`**（未来可能出现），本 skill 必须**主动提问用户**替代 dry-run，例如"以下操作将执行 XXX，是否继续？"。

## 工单创建的特殊性

`bytedance-bits create-ticket` 创建的工单会：
- 发送飞书通知给审批人
- 占用审批人的工单队列
- 系统认为这是"正式请求"，不可轻易撤销

因此 HARD-GATE ③ 的门槛**最高**，要求用户明确回复"确认创建工单"或"go"。

## 会话持久化

OpenClaw 下，部署流程可能跨多个对话轮次（BOE 验证可能持续数小时）。

本 skill 需要：
- 在每个 HARD-GATE 后**持久化状态**（已完成哪些步骤）
- 主 Agent 继续对话时，能恢复到正确的步骤
- 避免"用户回来后又从头开始"

状态存储建议：
- 写入话题归档文件（PRD 同目录）
- 或通过 `bytedance-cloud-docs` 存储

## 网络依赖

所有操作需要字节内网。公网环境：
- 明确告知"生产部署必须在内网"
- `BLOCKED` 给用户
