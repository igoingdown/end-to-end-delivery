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

## 二、13 个 e2e-* Skill 职责速查

### 对话层（4 个）

| Skill | 职责 | 产出 |
|---|---|---|
| `adversarial-qa` | 对抗式问答（5/5 → 2/5）| 稳定的核心需求 |
| `requirement-clarification` | 结构化需求澄清 | MoSCoW 清单 + 边界 + 验收 |
| `prd-generation` | PRD 生成 | PRD.md |
| `e2e-web-search` | Web 调研 | 结构化调研报告 |

### 编排层（6 个）

| Skill | 职责 | 产出 |
|---|---|---|
| `e2e-codebase-mapping` | 跨仓代码映射（**仅 brownfield**）| CODEBASE-MAPPING.md |
| `e2e-solution-design` ★ 新增 | 方案设计（Plan/Task/Verification 三件套）| specs/[简称]/ 下三文档 |
| `e2e-dev-task-setup` | 创建 1 个 BITS 研发任务 | BITS task 链接 |
| `e2e-code-review-loop` | Sub-Agent 按 task.md 并行改代码 | N 个 MR + task.md checkbox 更新 |
| `e2e-remote-test` | SSH 远端测试 | verification.md § 1 § 2 填充 |
| `e2e-deploy-pipeline` | BOE/PPE 部署（3 HARD-GATE）| verification.md § 3 § 4 填充 |

### 飞书层（3 个）

| Skill | 职责 |
|---|---|
| `e2e-progress-notify` | 关键节点飞书通知 |
| `e2e-architecture-draw` | 画架构图到飞书白板（可选调用） |
| `e2e-prd-share` | 把 PRD / plan 等分享到话题 |

---

## 三、典型调用组合

| 任务 | 推荐组合 |
|---|---|
| 需求澄清→PRD | adversarial-qa → requirement-clarification → prd-generation |
| brownfield 现状理解 | e2e-codebase-mapping（内部调 bytedance-codebase + bytedance-bam）|
| greenfield 轻量调研 | e2e-web-search + bytedance-cloud-docs |
| 方案设计三件套 | **e2e-solution-design**（一次产出 plan/task/verification）|
| 创建研发任务 | e2e-dev-task-setup（基于 task.md 建 1 个 BITS task）|
| 并行代码改造 | e2e-code-review-loop（Sub-Agent 按 task.md 派发）|
| 远端测试 | e2e-remote-test（MVP 简化版，消费 verification.md § 1-2）|
| 部署 | e2e-deploy-pipeline（调 bytedance-env/tce/tcc + bits create-ticket）|
| 飞书通知 | e2e-progress-notify（调 feishu-cli-msg） |
| 画架构图 | e2e-architecture-draw（调 feishu-cli-board，可选）|

---

## 四、本地 46 个 skill 分类速查

- **字节 DevOps（`bytedance-*`）30+**：认证（auth）、代码（codebase、bam）、部署（env、tce、tcc、bits）、监控（log、apm、cache、rds）、数据（hive、dorado、aeolus）、配置（neptune、settings、dkms、kmsv2）、对象存储（tos）、IAM 等
- **飞书（`feishu-cli-*`）13+**：消息（msg）、文档（read、write、import、export）、白板（board）、搜索（search）、权限（perm）、认证（auth）、综合工具（toolkit）
- **其他**：`ai-coding-radar`（AI 领域情报）、`find-skills`（发现新 skill）、`argos-log`、`bytedance-cloud-docs`、`bytedance-cloud-ticket`

完整清单和引用模式见 `docs/existing-skills-inventory.md`。

---

## 五、三活文档的数据流

```
阶段 4 (e2e-solution-design)
    │
    ├─ 初始化 plan.md
    ├─ 初始化 task.md (所有任务 pending)
    └─ 初始化 verification.md (5 章节，Status 全 pending)
         │
         ▼
阶段 5 (e2e-code-review-loop)
    │
    └─ 读 task.md → 派发 Sub-Agent
         Sub-Agent DONE → 主 Agent 回写 [ ] → [x]
         │
         ▼
阶段 6 (e2e-remote-test)
    │
    ├─ 读 verification.md § 1 § 2 的 Acceptance Criteria
    ├─ 执行编译 + 单测
    └─ 回写 § 1 § 2 的 Status / Execution / Results / Issues
         │
         ▼
阶段 7 (e2e-deploy-pipeline)
    │
    ├─ 读 verification.md § 3 § 4 的 AC
    ├─ 部署 BOE + PPE（3 HARD-GATE）
    └─ 回写 § 3 § 4 的字段
         │
         ▼
（人工）填 § 5 UAT
```

**关键原则**：
- 创建文档的 skill 只有**1 个**（solution-design）
- 消费+更新已有字段的 skill 可以多个
- 每个章节的 Owner 固定，不越权

---

## 六、调用原则（不要越层操作）

**正确**：调用 `e2e-codebase-mapping` → 让它自己调 `bytedance-codebase`

**错误**：在主 Agent 层直接写 `bytedcli codebase search --query xxx`

原因：底层 skill 的命令和参数可能变化，但能力稳定。引用能力让编排层 skill 对底层变化免疫。
