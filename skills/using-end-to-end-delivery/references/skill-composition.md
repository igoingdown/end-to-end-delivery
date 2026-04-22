# Skill 组合与对抗强度曲线

> 主 SKILL.md 的补充细节。Bootstrap 阶段不需要读；需要深入某个机制时再查这里。

---

## 一、对抗强度曲线（adversarial-qa 的关键状态）

`adversarial-qa` 的强度随需求澄清进度动态切换。

### 强度 5/5：反方 PM 模式（前期）

- 质疑需求的必要性（"不做会怎样？"）
- 挑战边界假设（"哪些场景不覆盖？"）
- 挖掘真实诉求（"不是想要 X，是想要 Y 吧？"）
- **目的**：砍掉不合理需求

### 强度 2/5：温和同行评审（后期）

- 在合理需求上做完善
- 补充被忽略的细节（异常场景、管理端、监控）
- 不再质疑存在必要
- **目的**：把方案打磨完整

### 切换条件（三条全满足）

1. ✅ 用户能用一句话准确说出"不做的代价"
2. ✅ 用户明确了用户画像和量级
3. ✅ 用户接受了明确的边界（列出了 out-of-scope 清单）

满足后主 Agent 要配合——**在强度 5/5 时不要急着写 PRD**，哪怕用户催促也要让对抗充分进行。切换时 `adversarial-qa` 会明确宣布。

---

## 二、已有 Skill 常见组合模式

| 任务 | 推荐组合 |
|---|---|
| 跨仓库分析 | `e2e-codebase-mapping` → 内部调 `bytedance-codebase` + `bytedance-bam` |
| 创建多仓研发任务 | `e2e-dev-task-setup` → 内部调 `bytedance-bits --change ... --change ...` |
| 远端测试 | `e2e-remote-test`（MVP 简化版，假设代码已就绪） |
| 部署 | `e2e-deploy-pipeline` → 内部调 `bytedance-env` / `bytedance-tce` / `bytedance-tcc` |
| 飞书通知 | `e2e-progress-notify` → 内部调 `feishu-cli-msg` |
| 画架构图 | `e2e-architecture-draw` → 内部调 `feishu-cli-board` |
| PRD 分享到话题 | `e2e-prd-share` → 内部调 `feishu-cli-msg` 发 Markdown 附件 |

---

## 三、本地 46 个 skill 分类速查

- **字节 DevOps（`bytedance-*`）30+**：认证（auth）、代码（codebase、bam）、部署（env、tce、tcc、bits）、监控（log、apm、cache、rds）、数据（hive、dorado、aeolus）、配置（neptune、settings、dkms、kmsv2）、对象存储（tos）、IAM 等
- **飞书（`feishu-cli-*`）13+**：消息（msg）、文档（read、write、import、export）、白板（board）、搜索（search）、权限（perm）、认证（auth）、综合工具（toolkit）
- **其他**：`ai-coding-radar`（AI 领域情报）、`find-skills`（发现新 skill）、`argos-log`、`bytedance-cloud-docs`、`bytedance-cloud-ticket`

完整清单和引用模式见 `docs/existing-skills-inventory.md`。

---

## 四、调用原则（不要越层操作）

**正确**：调用 `e2e-codebase-mapping` → 让它自己调 `bytedance-codebase`

**错误**：在主 Agent 层直接写 `bytedcli codebase search --query xxx`

原因：底层 skill 的命令和参数可能变化，但能力稳定。引用能力让你的编排层 skill 对底层变化免疫。
