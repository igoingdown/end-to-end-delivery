---
name: e2e-solution-design
description: "端到端交付的方案设计 skill，采用 Spec-Driven Development 方法论，一次性产出 plan.md（方案文档，含 Mermaid 架构图）+ task.md（中粒度实现任务清单）+ verification.md（QA 验证策略活文档）三个文件。当 PRD 已定稿、现状理解完成、需要进入技术方案阶段时必须调用此 skill。典型触发场景：'帮我做方案设计'、'写个技术方案'、'solution design'、'方案怎么做'、'技术选型怎么选'、'架构怎么画'、'拆一下任务'、'定一下验证策略'、'plan 一下'。本 skill 分三阶段执行（Plan → Task → Verification），每阶段内部有 HARD-GATE，三文档全部定稿后统一触发最终 HARD-GATE。产出的三文档存放在 specs/[需求简称]/ 目录，作为后续所有 skill（dev-task-setup、code-review-loop、remote-test、deploy-pipeline）的输入。"
---

# E2E Solution Design —— 方案设计

## 定位

端到端交付主流程的**阶段 4**：从"理解了什么"到"怎么做 + 怎么验证"。

**输入**：

- `PRD.md`（来自 `prd-generation`）
- `CODEBASE-MAPPING.md`（存量项目，来自 `e2e-codebase-mapping`）或轻量现状调研（新项目）

**输出**：specs/[需求简称]/ 目录下的三个 Markdown 文件

- `plan.md` —— 方案文档（含嵌入的 Mermaid 架构图）
- `task.md` —— 执行层任务清单（中等粒度，2-8 小时/任务）
- `verification.md` —— QA 验证策略（活文档，初始化后被多 skill 填充）

**关键原则**：三文档**同时产出**，不能分开。方案设计阶段**必须想清楚"怎么验证"**，否则说明方案不完整。

---

## 前置条件

- [x] PRD 已定稿（`prd-generation` 已触发 HARD-GATE）
- [x] 现状理解已完成：
  - 存量项目 → `CODEBASE-MAPPING.md` 已产出
  - 新项目 → 轻量调研完成或用户明确"无类似系统参考"

缺失任一 → **拒绝进入**，回退到前置 skill。

---

## 产出文件目录约定

```
<工作目录>/
├── PRD.md                         ← 已有
├── CODEBASE-MAPPING.md            ← 已有（存量项目）或轻量调研简报（新项目）
└── specs/
    └── [需求简称]/                ← 本 skill 创建
        ├── plan.md                ← Plan（方案设计）
        ├── task.md                ← Task（执行清单）
        └── verification.md        ← Verification（验证策略）
```

需求简称规则：从 PRD 的"一句话说明"提取 2-4 个英文或拼音词，连字符分隔。
例：`用户分层规则自助配置` → `user-segment-rules`

---

## 三阶段工作流

```
阶段 4.1: 生成 plan.md
  ├─ gather: 聚合 PRD + codebase-mapping 素材
  ├─ design: 方案综述 / 架构 / 选型 / 详细设计 / Trade-off / 风险
  ├─ (可选) 调用 e2e-architecture-draw 生成 Mermaid 源码并内嵌
  └─ HARD-GATE: plan.md 定稿确认
       ▼
阶段 4.2: 生成 task.md
  ├─ 按 plan.md 的模块拆分任务（中等粒度：2-8 小时/任务）
  ├─ 每个任务必须含：依赖、预估、仓库/文件、plan 章节引用、验收标准
  └─ HARD-GATE: task.md 定稿确认
       ▼
阶段 4.3: 生成 verification.md
  ├─ 按固定 Schema 初始化 5 个章节（编译/单测/BOE/PPE/UAT）
  ├─ 每章节明确 Owner（谁后续填充）
  └─ HARD-GATE: verification.md 定稿确认
       ▼
(可选) 同步画架构图到飞书白板：调 e2e-architecture-draw
       ▼
产出：3 个 Markdown 文件 + 可选的飞书白板链接
```

**三阶段分开做 HARD-GATE 而非合并**，原因：

- Plan 不对 → Task 和 Verification 都白写
- Plan 对 Task 错 → Verification 还能救
- 三合一 HARD-GATE 会让用户一次性看 3 个文件，认知负担大

---

## 阶段 4.1：生成 plan.md

### 工作流

**Step 1 - Gather（聚合）**：

- 读 PRD.md 的"做什么"和"不做什么"章节
- 读 CODEBASE-MAPPING.md 的"涉及仓库"和"调用链"（存量项目）
- 读轻量调研简报（新项目）
- 整合为"方案素材清单"

**Step 2 - Design（设计）**：

- 按 `references/plan-template.md` 填充各章节
- 决策点：
  - 至少列 2 个技术选型备选，说明为什么选 A 不选 B
  - 至少识别 3 个 trade-off
  - 至少列 3 个风险

**Step 3 - Architecture Diagram（架构图）**：

- 生成 Mermaid 源码内嵌到 plan.md 的"二、架构设计"章节
- Mermaid 源码由本 skill 生成（符合职责分离约定：本 skill 负责方案设计内在能力）
- 图类型根据方案性质选（见 `references/plan-template.md`）：
  - 服务级系统 → 服务调用图（`graph LR`）
  - 流程型 → 流程图（`flowchart TD`）
  - 时序重要 → 时序图（`sequenceDiagram`）
  - 状态机 → 状态图（`stateDiagram`）

**Step 4 - Self-Review（自审）**：

- Checklist（见 `references/plan-template.md` 末尾）
- 关注点：反 AI-slop、信息量、可证伪的假设

### HARD-GATE: plan.md 定稿

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
<HARD-GATE> plan.md 定稿确认

已生成 plan.md（路径：specs/[需求简称]/plan.md）

包含：
- 一、方案综述
- 二、架构设计（Mermaid 图）
- 三、关键技术选型（N 项）
- 四、详细设计（N 个模块）
- 五、Trade-off 分析（N 项）
- 六、风险与缓解（N 项）

请 review 后明确回复：
- ✅ "plan 确认" / "go" → 继续生成 task.md
- 📝 "修改 [...]" → 指出要改哪里
- ❌ "取消" → 终止
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 阶段 4.2：生成 task.md

### 粒度规则

**中等粒度**：每个任务 2-8 小时工作量，对应**一个自然的代码提交**。

判定：

- < 2 小时 → 合并相邻任务
- > 8 小时 → 拆分
- 边界模糊（6 小时左右）→ 接受

### 每个任务的必填字段

```markdown
### T[N]：[任务标题]
- [ ] **状态**：pending
- **依赖**：T[M] / 无
- **预估**：X 小时
- **仓库/文件**：[PSM] / [具体文件路径]
- **关联 Plan 章节**：plan.md § [章节号]
- **关联验收**：verification.md § [章节号]
- **任务描述**：
  [2-5 行，包含 Sub-Agent 执行所需的完整上下文]
- **验收**：
  [完成标准，可测]
```

**关键约束 C7**：任务描述必须含足够上下文（接口定义、参考代码路径、数据模型引用），不然 Sub-Agent 执行时会返回 `NEEDS_CONTEXT`。

### 任务排序规则

按**依赖关系拓扑排序**。无依赖的任务放前面。跨仓库任务尽量并行。

### HARD-GATE: task.md 定稿

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
<HARD-GATE> task.md 定稿确认

已生成 task.md（路径：specs/[需求简称]/task.md）

任务总数：N
├─ 依赖前置：X 个（无依赖）
├─ 可并行：Y 个
└─ 预估总工时：Z 小时

前 3 个任务概览：
  T1: [标题] (X 小时)
  T2: [标题] (Y 小时)
  T3: [标题] (Z 小时)

请明确回复：
- ✅ "task 确认" → 继续生成 verification.md
- 📝 "修改 [...]" → 指出要改哪里
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 阶段 4.3：生成 verification.md

### 固定 Schema（中等严格）

5 个章节，顺序固定：

1. **编译验证** —— Owner: `e2e-remote-test`
2. **单测验证** —— Owner: `e2e-remote-test`
3. **BOE 集成测试** —— Owner: `e2e-deploy-pipeline`
4. **PPE 验证** —— Owner: `e2e-deploy-pipeline`
5. **人工 UAT** —— Owner: `human`

每章节字段固定，见 `references/verification-template.md`：

- Owner（固定）
- Status（pending | running | passed | failed）
- Acceptance Criteria（本 skill 初始化，后续只更新不重写）
- Execution（后续 skill 填充）
- Results（后续 skill 填充，策略：最终结果 + 历史摘要）
- Issues（后续 skill 填充，如有）

### HARD-GATE: verification.md 定稿

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
<HARD-GATE> verification.md 定稿确认

已生成 verification.md（路径：specs/[需求简称]/verification.md）

5 个验证章节：
├─ 1. 编译验证   [Owner: e2e-remote-test]
├─ 2. 单测验证   [Owner: e2e-remote-test, 覆盖率要求 ≥ X%]
├─ 3. BOE 集成测试 [Owner: e2e-deploy-pipeline]
├─ 4. PPE 验证   [Owner: e2e-deploy-pipeline, 灰度 X% → Y% → ...]
└─ 5. 人工 UAT   [Owner: human]

每章节的 Acceptance Criteria 已初始化。
后续 skill 会填充 Execution / Results / Issues。

请明确回复：
- ✅ "verification 确认" → 方案设计阶段完成，进入代码改造
- 📝 "修改 [...]" → 指出要改哪里
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 最终产出

```markdown
# 方案设计完成

产出路径：specs/[需求简称]/

├── plan.md           ← 方案文档
├── task.md           ← N 个实现任务（总工时 X 小时）
└── verification.md   ← 5 章验证策略

下一步：
→ e2e-dev-task-setup：基于 task.md 创建 1 个 BITS 研发任务
→ e2e-code-review-loop：按 task.md 并行派发 Sub-Agent

(可选) 同步架构图到飞书白板？→ 调 e2e-architecture-draw
```

---

## 关于轻量 vs 完整模式

提供两种模式（Q5 方案 C），用户在进入 skill 时选择或由 Agent 推荐。

- **完整模式**（默认）：三文档全写，每文档结构完整
- **轻量模式**：适用改动量小的场景
  - plan.md 简化：只写"方案综述 + 架构图 + 关键选型"
  - task.md 简化：任务数 ≤ 5 个
  - verification.md 不简化（验证永远不能省）

详见 `references/design-modes.md`。

**Agent 的推荐策略**：

- 预估总工时 > 40 小时 → 推荐完整模式
- 预估总工时 ≤ 16 小时 → 推荐轻量模式
- 中间 → 询问用户

---

## 和其他 skill 的协同

### 输入来自

- `prd-generation` → PRD.md
- `e2e-codebase-mapping` → CODEBASE-MAPPING.md（存量）
- `e2e-web-search` + `bytedance-cloud-docs` → 轻量调研简报（新项目）

### 输出给

- `e2e-dev-task-setup` ← 消费 task.md 的任务数量，创建 1 个 BITS task
- `e2e-code-review-loop` ← 消费 task.md 的任务条目，Sub-Agent 派发
- `e2e-remote-test` ← 消费 verification.md 的章节 1-2，回写结果
- `e2e-deploy-pipeline` ← 消费 verification.md 的章节 3-4，回写结果

### 可选调用

- `e2e-architecture-draw` —— 三文档定稿后，若用户需要，同步画架构图到飞书白板

---

## 失败处理

### 失败 A：PRD 或 codebase-mapping 缺失

- 拒绝进入
- 告知用户需要回退到前置 skill

### 失败 B：用户在某 HARD-GATE 反复要求修改

- 前 3 次修改：正常响应
- 第 4 次：询问用户"是否需要回退到前置阶段（PRD / codebase-mapping）？"
- 可能是方案方向错了，而不是文档措辞问题

### 失败 C：Mermaid 源码生成错误（语法）

- 本 skill 自己生成 Mermaid，失败时降级为"文字描述架构"
- 不阻塞主流程

### 失败 D：task.md 的任务粒度反复不合适

- 用户反复说"这个拆太细了"或"太粗了"
- Agent 拿用户的 1 个任务作为粒度基准，重新拆一遍

---

## 反 AI-slop 规范

### 禁用模式

- ❌ plan.md 里"本方案旨在..."、"综合考虑..."
- ❌ 选型章节"各有优劣，建议综合评估"（没结论）
- ❌ task.md 任务描述"实现 XX 功能"（不具体）
- ❌ verification.md 的 Acceptance Criteria 写"测试通过"（不可测）

### 正确模式

- ✅ plan.md 的每个决策都有"为什么选这个"
- ✅ 选型给出**明确结论** + 理由
- ✅ task.md 任务描述有**文件路径 + 接口签名**
- ✅ verification 的 Acceptance 可量化（覆盖率、性能指标）

---

## 参考资料

- `references/plan-template.md` —— plan.md 模板 + 示例 + 自审 Checklist
- `references/task-template.md` —— task.md 模板 + 粒度判定规则
- `references/verification-template.md` —— verification.md 模板 + Schema 规范
- `references/design-modes.md` —— 轻量 vs 完整模式决策
- `references/openclaw-tools.md` —— OpenClaw 运行时
- `references/trae-tools.md` —— Trae 运行时

---

## 自检清单（每阶段 HARD-GATE 前）

- [ ] 当前在哪个子阶段（Plan / Task / Verification）？
- [ ] 前置文档是否都读过？
- [ ] 三文档之间的交叉引用是否正确（task 引用 plan 章节，verification 编号对应）？
- [ ] 反 AI-slop 检查通过？
- [ ] HARD-GATE 的标准提问模板用了吗？
- [ ] 产出文件路径正确？（specs/[需求简称]/）

---

*本 skill 是端到端交付从"需求域"进入"工程实施域"的转接点。三文档是后续所有 skill 的共享上下文，质量直接决定交付质量。*
