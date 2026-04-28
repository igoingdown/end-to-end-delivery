# Skill Orchestration Map —— 端到端交付流程编排图

> **用途**：给 Agent 和维护者看的"完整流程说明书"。每一步做什么、调哪些 skill、HARD-GATE 在哪、Sub-Agent 何时派发。
>
> **阅读方式**：先看顶层流程图建立整体认知，再按需深入具体阶段。
>
> **版本**：v2.0（7 阶段版，引入 Spec-Driven Development）

---

## 顶层流程图

```
┌─────────────────────────────────────────────────────────────────┐
│  用户在飞书话题或 Trae 里：                                       │
│  @端到端交付 我们想做个用户分层运营的能力                         │
└─────────────┬───────────────────────────────────────────────────┘
              │
              ▼
     ┌────────────────────┐
     │  Session Bootstrap │  ← 读 using-end-to-end-delivery/SKILL.md
     │  加载元 skill        │
     └────────┬───────────┘
              │
              ▼
  ═══════════════════════════════════════════════════════════════
  【阶段 1：需求澄清】前期硬核反方 PM + 后期温和评审
  ═══════════════════════════════════════════════════════════════
              │
              ▼
     ┌──────────────────────────┐
     │ adversarial-qa           │  ← 强度 5/5：挑战必要性、边界
     │ (对抗式问答)              │  ← 强度 2/5：温和完善（核心需求稳定后）
     └──────────┬───────────────┘
                │
                ▼
     ┌──────────────────────────┐
     │ requirement-clarification │  ← MoSCoW + 边界定义 + 验收标准
     └──────────┬───────────────┘
                │
     (可选) e2e-web-search：调研竞品/行业方案
                │
                ▼
  ═══════════════════════════════════════════════════════════════
  【阶段 2：PRD 生成】
  ═══════════════════════════════════════════════════════════════
              │
              ▼
     ┌──────────────────────────┐
     │ prd-generation           │  ← gather → refine → reader-test 三阶段
     └──────────┬───────────────┘
                ▼
              📄 PRD.md（Markdown 文件）
                │
          【HARD-GATE】PRD 定稿需用户明确确认
                │
                ▼
  ═══════════════════════════════════════════════════════════════
  【阶段 3：现状理解】★ 项目类型判断 → 分支
  ═══════════════════════════════════════════════════════════════
              │
              ▼
     ┌──────────────────────────┐
     │ 项目类型识别              │
     │ Agent 推断 PRD 类型        │
     └──┬───────────┬──────┬────┘
        │           │      │
  明显存量     明显新项目   模糊
        ▼           ▼      ▼
   ┌─────────┐ ┌─────────┐ 【HARD-GATE】
   │codebase │ │web-search│ 问用户
   │mapping  │ │+cloud-   │
   │         │ │docs 轻量 │
   └────┬────┘ └────┬─────┘
        │           │
        ▼           ▼
   📄 CODEBASE-    📄 现状调研简报
   MAPPING.md     （放入 plan.md 前置素材）
        │           │
        └─────┬─────┘
              │
              ▼
  ═══════════════════════════════════════════════════════════════
  【阶段 4：方案设计】★ 核心新增 ★ Spec-Driven Development
  ═══════════════════════════════════════════════════════════════
              │
              ▼
     ┌─────────────────────────────────────┐
     │ e2e-solution-design                 │
     │ 三阶段产出：                          │
     │   4.1 plan.md（方案文档+Mermaid）    │
     │   4.2 task.md（中粒度任务，2-8h/个）│
     │   4.3 verification.md（验证策略）   │
     └──────┬──────────────────────────────┘
            │
            ▼
      📁 specs/[需求简称]/
          ├─ plan.md          ← 【HARD-GATE ①】plan 定稿
          ├─ task.md          ← 【HARD-GATE ②】task 定稿
          └─ verification.md  ← 【HARD-GATE ③】verification 定稿
            │
    (可选) 同步画架构图到飞书白板 → e2e-architecture-draw
            │
            ▼
  ═══════════════════════════════════════════════════════════════
  【阶段 5：代码改造】基于 task.md 并行执行
  ═══════════════════════════════════════════════════════════════
            │
            ▼
     ┌──────────────────────────┐
     │ e2e-dev-task-setup        │  ← 基于 task.md 创建 1 个 BITS task
     └──────────┬───────────────┘     （不再拆任务！）
                │                      🔗 BITS task 链接
                ▼
     ┌───────────────────────────────┐
     │ e2e-code-review-loop          │
     │ Sub-Agent 并行派发             │
     │   ├─ Sub-A: 读 T1 → 改代码    │
     │   ├─ Sub-B: 读 T2 → 改代码    │
     │   └─ Sub-N: 读 Tn → 改代码    │
     │                                │
     │ 主 Agent 在 DONE 后            │
     │ 回写 task.md 的 [ ] → [x]     │
     └──────────┬────────────────────┘
                │
                ▼
        📄 task.md（checkbox 持续更新）
        🔀 N 个 MR
                │
     【HARD-GATE】代码合入前，逐个确认 MR
                │
                ▼
  ═══════════════════════════════════════════════════════════════
  【阶段 6：远端测试】消费 verification.md § 1 § 2
  ═══════════════════════════════════════════════════════════════
                │
                ▼
     ┌──────────────────────────┐
     │ e2e-remote-test           │
     │ 读 verification.md:      │
     │   § 1 编译验证 AC         │
     │   § 2 单测验证 AC         │
     │ 执行（SSH 开发机）         │
     │ 回写 Execution/Results   │
     └──────────┬───────────────┘
                │
                ▼
        📄 verification.md § 1 § 2（Status 更新为 passed/failed）
                │
           通过？
          ┌──┴──┐
         No    Yes
          │     │
          ▼     ▼
      回退阶段 5  进入阶段 7
                │
                ▼
  ═══════════════════════════════════════════════════════════════
  【阶段 7：部署】消费 verification.md § 3 § 4，填写 § 5 人工 UAT 验证
  ═══════════════════════════════════════════════════════════════
                │
                ▼
     ┌──────────────────────────────┐
     │ e2e-deploy-pipeline           │
     │                               │
     │ 子阶段 7.1: BOE 部署           │
     │  → 调 bytedance-tce            │
     │     【HARD-GATE ①】dry-run    │
     │  → 调 bytedance-tcc 配置       │
     │     【HARD-GATE ②】diff 确认  │
     │                               │
     │ (用户在 BOE 做 QA 验证)        │
     │                               │
     │ 子阶段 7.2: PPE 工单           │
     │  → 调 bits create-ticket      │
     │     【HARD-GATE ③】工单确认   │
     │                               │
     │ 回写 verification.md § 3 § 4 │
     └──────────┬────────────────────┘
                │
                ▼
        📄 verification.md § 3 § 4（Status 更新）
        🎫 PPE 发布工单（等审批）
                │
                ▼
         (人工) 填 verification.md § 5 UAT
                │
                ▼
   ┌──────────────────────────────┐
   │ e2e-progress-notify          │  ← 贯穿所有阶段的节点通知
   │ 在每个关键节点发飞书卡片      │
   └──────────────────────────────┘
                │
                ▼
            🎉 交付完成
```

---

## 阶段详解

### 阶段 1：需求澄清

**目标**：从"模糊想法"到"清晰需求"。

**参与 skill**：

- `adversarial-qa` —— 对抗式问答（5/5 强度 → 2/5 强度动态切换）
- `requirement-clarification` —— 结构化需求澄清（MoSCoW）
- `e2e-web-search` —— 可选，调研竞品和行业方案

**关键决策点**：

- 对抗强度切换：核心需求稳定 → 从 5/5 切到 2/5
- 条件：用户能说出"不做的代价" + "用户画像/量级" + "边界（out-of-scope）"

**产出**：对话达成的"核心需求共识"（不落成文件，作为 PRD 生成的输入）。

---

### 阶段 2：PRD 生成

**目标**：把澄清后的需求写成 Markdown PRD。

**参与 skill**：

- `prd-generation` —— 核心 skill，3 阶段内部工作流（gather → refine → reader-test）

**产出**：`PRD.md`（工作目录根）

**HARD-GATE**：PRD 定稿。用户明确回复"确认"/"定稿"/"go"。

---

### 阶段 3：现状理解（分支）

**目标**：理解改动的上下文环境（存量项目）或参考资源（新项目）。

**核心机制**：项目类型识别。

#### 分支 A：明显存量项目

**信号**：PRD 提到"给 X 加功能"、"改 Y 逻辑"、"优化 Z 性能"等。

**调用**：

- `e2e-codebase-mapping` → 内部调 `bytedance-codebase` + `bytedance-bam`

**产出**：`CODEBASE-MAPPING.md`（涉及仓库、改动点、调用链、风险）

#### 分支 B：明显新项目

**信号**：PRD 提到"新做一个 X"、"从 0 建 Y"等。

**调用**（A + C 组合）：

- `e2e-web-search` —— 调研行业类似方案
- `bytedance-cloud-docs` —— 查公司内部是否有可复用基建
- 若调研结果为空 → Agent 询问用户"有没有类似系统/基建要参考"

**产出**：现状调研简报（作为 plan.md 的前置素材，不强制独立文件）

#### 分支 C：模糊情况

**触发条件**：Agent 无法明确判断类型。

**HARD-GATE**：询问用户：

```
这个需求看起来既可能是新建也可能是扩展现有系统。请明确：
- 是全新项目（无已有代码）→ 做轻量现状调研
- 是给现有系统加功能 → 做代码库映射
- 还是混合？→ 我会先做映射，同时调研类似已有系统
```

---

### 阶段 4：方案设计 ★ 核心新增

**目标**：产出 Spec-Driven Development 三件套。

**参与 skill**：`e2e-solution-design`（唯一）

**内部三个子阶段**：

#### 子阶段 4.1：生成 plan.md

- gather 素材（PRD + 现状理解产出）
- 按 `references/plan-template.md` 填充 7 章节（完整模式）或 3 章节（轻量模式）
- **Agent 自己生成 Mermaid 源码**嵌入 § 2 架构设计
- 自审 15 项 Checklist

**【HARD-GATE ①】plan.md 定稿**

#### 子阶段 4.2：生成 task.md

- 按 plan.md 的模块拆任务
- 中等粒度（2-8 小时/任务）
- 每任务 6 个必填字段（依赖/预估/仓库/文件/Plan 章节/验收）
- 自审粒度 Checklist

**【HARD-GATE ②】task.md 定稿**

#### 子阶段 4.3：生成 verification.md

- 5 章节固定 Schema 初始化（编译/单测/BOE/PPE/UAT）
- 每章节 Acceptance Criteria **必须可测**
- Owner 固定（§1/§2 = remote-test，§3/§4 = deploy-pipeline，§5 = human）

**【HARD-GATE ③】verification.md 定稿**

**产出目录**：

```
specs/[需求简称]/
├── plan.md
├── task.md
└── verification.md
```

**可选后续**：询问用户是否调 `e2e-architecture-draw` 同步架构图到飞书白板。

---

### 阶段 5：代码改造

**目标**：执行 task.md 里的任务，产出多个 MR。

**参与 skill**：

- `e2e-dev-task-setup` —— 职责简化：只创建 **1 个** BITS 研发任务，返回链接
- `e2e-code-review-loop` —— Sub-Agent 按 task.md 条目并行派发

**关键机制**：

#### task.md 作为活文档

- **Sub-Agent** 拿到任务包（task.md 的一个条目）→ 执行 → 返回四态
- **主 Agent**（code-review-loop）在 Sub-Agent `DONE` 后回写 task.md 的 `[ ]` → `[x]`
- **Sub-Agent 不改 task.md**（避免并发冲突）

#### 任务包内容

每个 task.md 条目的 6 个字段 + plan.md 中引用章节 = Sub-Agent 的完整执行上下文。

**上下文不足** → Sub-Agent 返回 `NEEDS_CONTEXT` → 主 Agent 补充后重派（最多 2 次）。

#### BITS task 和 task.md 的关系

- 1 个需求 = 1 个 BITS task（包含 N 个 MR）
- task.md 是 N 个 MR 背后的细粒度任务清单
- 两者不重叠，`e2e-dev-task-setup` 不再自行拆解

**【HARD-GATE】代码合入前**

逐个 MR 展示 Diff，让用户确认合入。

---

### 阶段 6：远端测试

**目标**：SSH 到开发机跑编译和单测。

**参与 skill**：`e2e-remote-test`

**输入**：`verification.md § 1` 和 `§ 2` 的 Acceptance Criteria

**执行**：

1. 读取 § 1、§ 2 的 AC
2. 执行 `scripts/run-remote-test.sh`
3. **回写** § 1、§ 2 的：
   - `Status`: running → passed/failed
   - `Execution`: 何时/何机器
   - `Results`: 最终结果 + 历史摘要
   - `Issues`: 如有

**通过** → 进阶段 7
**失败** → 回退阶段 5（通过 `e2e-code-review-loop` 重新派发失败任务）

---

### 阶段 7：部署

**目标**：BOE 验证 + PPE 工单。

**参与 skill**：`e2e-deploy-pipeline`

**3 个独立 HARD-GATE**（不可合并）：

- **HARD-GATE ①**：BOE 容器部署（调 `bytedance-tce` dry-run → 确认 → 实际部署）
- **HARD-GATE ②**：BOE 配置同步（调 `bytedance-tcc` dry-run 看 diff → 确认 → 应用）
- **HARD-GATE ③**：PPE 发布工单（调 `bytedance-bits create-ticket`）

**回写 verification.md**：

- § 3 BOE 集成测试：Status / Results
- § 4 PPE 验证：Status / 灰度进度 / Results

**最后人工填 § 5 UAT**。

---

## 贯穿性 Skill（不在主流程线性位置）

### e2e-progress-notify

**何时触发**：

- PRD 定稿 → 通知 PM
- BITS task 创建成功 → 通知研发、QA
- 阶段 5 所有 MR 合入 → 通知研发 Leader
- 阶段 6 测试失败 → 通知研发负责人
- 阶段 7 BOE 部署完成 → 通知 QA 验证
- 阶段 7 PPE 工单创建 → 通知审批人
- 任一阶段 BLOCKED → 通知项目发起人

### e2e-architecture-draw

**何时触发**：

- 阶段 4 方案设计完成后，用户要求同步画到飞书白板
- 跨团队讨论时，需要可视化方案
- 阶段 8 话题归档总结时

### e2e-prd-share

**何时触发**：

- 阶段 2 PRD 定稿后，分享到飞书话题供 review

---

## 三活文档的数据流（重点）

```
阶段 4 (solution-design)
    │
    ├─ plan.md          ← 初始化（静态文档，定稿后不改）
    ├─ task.md          ← 初始化（活：Sub-Agent 执行后主 Agent 回写 checkbox）
    └─ verification.md  ← 初始化（活：多 skill 持续填充字段）
         │
         ▼
阶段 5 (code-review-loop)
    │
    ├─ 读 task.md 条目 → Sub-Agent 执行
    └─ 主 Agent 回写 task.md checkbox
         │
         ▼
阶段 6 (remote-test)
    │
    └─ 读 verification § 1 § 2 AC → 执行 → 回写 Status/Results/Issues
         │
         ▼
阶段 7 (deploy-pipeline)
    │
    └─ 读 verification § 3 § 4 AC → 执行 → 回写
         │
         ▼
人工填 § 5 UAT
         │
         ▼
  交付完成
```

**关键约束**：

- 只有 solution-design 能**创建**这 3 个文档
- 其他 skill 只能**消费**或**更新已有字段**
- 不越权写其他 skill 的 Owner 章节

---

## 触发词和路由规则

| 用户说 | 主 Agent 决策 |
|---|---|
| "我想做个 X" / "有个新需求" | 进入阶段 1，调 adversarial-qa |
| "帮我写个 PRD" | 进入阶段 2（前提：阶段 1 已充分）|
| "这个需求涉及哪些代码" | 进入阶段 3，调 e2e-codebase-mapping（前提：brownfield）|
| "帮我做方案设计" | 进入阶段 4，调 e2e-solution-design |
| "开始改代码" / "开始开发" | 进入阶段 5，调 e2e-dev-task-setup |
| "跑一下单测" | 进入阶段 6，调 e2e-remote-test |
| "部署到 BOE" | 进入阶段 7.1 |
| "发 PPE 工单" | 进入阶段 7.2 |

---

*本流程图随 Skill 职责演进持续更新。当前版本：v2.0（2026-04-22，引入 SDD 方案设计阶段）。*
