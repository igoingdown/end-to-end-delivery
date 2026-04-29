# Architecture —— 端到端交付 Agent 整体架构

> 本文档说明端到端交付 Agent 的整体架构、组件分层、数据流、以及部署拓扑。
> 受众：第一次接触本项目的开发者 / 维护者。

---

## 一、定位与非目标

### 本项目是什么

一个**端到端交付的 AI Agent**，由一组 Skill 组成，可以在 **Trae IDE** 和 **OpenClaw + 飞书话题**两个运行时下运行，帮用户完成"模糊想法 → BOE/PPE 部署"的全链路。

### 本项目不是什么

- ❌ 不是一个 AI 模型 —— 模型由 OpenClaw / Trae 运行时提供（千问 3.6 Plus / GLM-5.1）
- ❌ 不是一个 CLI —— 所有操作通过自然语言对话
- ❌ 不是一个完整的 DevOps 平台 —— 它**复用**字节现有平台（BITS、TCE、TCC 等）
- ❌ 不是一个通用 Agent 框架 —— 只解决端到端交付这一个垂直问题

---

## 二、核心设计理念

### 理念 1：编织而非建造

本项目的"新"代码不做任何底层能力。它只是**把已有的 46 个 skill 编织**成端到端流程。

```
┌─────────────────────────────────────────────┐
│  本项目 14 个编织层 skill                     │
│  ─ 对话层（4）: 澄清/对抗/PRD/调研             │
│  ─ 编排层（6）: 代码映射/方案设计/任务/测试/部署/review │
│  ─ 飞书层（3）: 通知/画图/分享                 │
│  ─ Bootstrap（1）: using-end-to-end-delivery  │
└─────────────────────┬───────────────────────┘
                      │ 调用
                      ▼
┌─────────────────────────────────────────────┐
│  本地已有 46 个 skill（不修改，只引用）        │
│  ─ bytedance-* 30+（代码、部署、监控、...）    │
│  ─ feishu-cli-* 13+（消息、文档、白板、...）   │
│  ─ 其他（ai-coding-radar、find-skills...）    │
└─────────────────────┬───────────────────────┘
                      │ 调用
                      ▼
┌─────────────────────────────────────────────┐
│  字节内部平台 / 飞书 OpenAPI                   │
│  ─ BITS / TCE / TCC / BAM / ...               │
│  ─ Feishu messaging / docs / board API        │
└─────────────────────────────────────────────┘
```

### 理念 2：安全优先

多个 HARD-GATE（强制人工确认）覆盖所有写操作和关键决策：

- PRD 定稿
- 项目类型模糊时询问
- plan.md 定稿
- task.md 定稿
- verification.md 定稿
- 代码合入前
- BOE 部署前
- BOE 配置同步前
- PPE 发布工单前

**宁可啰嗦，不要误操作**。

### 理念 3：双运行时平等

同一套 Skill 在 Trae 和 OpenClaw 都能工作。Skill 内部通过 `references/trae-tools.md` 和 `references/openclaw-tools.md` 做工具映射。

---

## 三、分层架构

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Layer 6: 用户入口（Entry Points）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ┌───────────────┐         ┌───────────────────┐
  │ Trae IDE      │         │ OpenClaw + 飞书话题 │
  │ (研发同学)     │         │ (非研发 & 研发)     │
  └───────┬───────┘         └──────────┬────────┘
          │                            │
━━━━━━━━━━▼━━━━━━━━━━━━━━━━━━━━━━━━━━━━▼━━━━━━━━
Layer 5: Agent 运行时（Runtime）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ┌───────────────┐         ┌───────────────────┐
  │ Trae Runtime  │         │ OpenClaw Gateway  │
  │ (LLM + Tools) │         │ (LLM + Tools)     │
  └───────┬───────┘         └──────────┬────────┘
          │                            │
━━━━━━━━━━▼━━━━━━━━━━━━━━━━━━━━━━━━━━━━▼━━━━━━━━
Layer 4: Agent 人格（AGENTS.md）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  加载 AGENTS.md → 主 Prompt 生效
          │
━━━━━━━━━━▼━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Layer 3: Bootstrap Skill
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  using-end-to-end-delivery
  ├─ 1% 规则
  ├─ Skill 宣布协议
  ├─ HARD-GATE 机制
  ├─ Sub-Agent 四态协议
  └─ 主流程图 & 硬约束
          │
━━━━━━━━━━▼━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Layer 2: 编织层 Skill（13 个，本项目新建）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ┌─ 对话层 ──────────────────────────────────┐
  │ adversarial-qa / requirement-clarification │
  │ prd-generation / e2e-web-search            │
  └────────────────────────────────────────────┘
  ┌─ 编排层 ──────────────────────────────────┐
  │ e2e-codebase-mapping / e2e-solution-design │
  │ e2e-dev-task-setup / e2e-code-review-loop  │
  │ e2e-remote-test / e2e-deploy-pipeline      │
  └────────────────────────────────────────────┘
  ┌─ 飞书层 ──────────────────────────────────┐
  │ e2e-progress-notify / e2e-architecture-draw│
  │ e2e-prd-share                              │
  └────────────────────────────────────────────┘
          │
━━━━━━━━━━▼━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Layer 1: 底层能力 Skill（本地已有 46 个）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  bytedance-auth / codebase / bits / env / tce / tcc / ...
  feishu-cli-msg / board / import / search / ...
          │
━━━━━━━━━━▼━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Layer 0: 底层平台（字节内网 + 飞书 OpenAPI）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  BITS / TCE / TCC / BAM / Hive / ...
  Feishu API
```

---

## 四、文件系统布局

### 开发期（~/github/end-to-end-delivery/）

```
~/github/end-to-end-delivery/
├── AGENTS.md                        # 主 Prompt（Agent 人格）
├── README.md                        # 项目总览
├── LICENSE                          # 占位（MVP 不开源）
├── .gitignore
│
├── skills/                          # 14 个新 skill
│   ├── using-end-to-end-delivery/
│   │   ├── SKILL.md
│   │   └── references/
│   ├── adversarial-qa/
│   │   ├── SKILL.md
│   │   └── references/question-banks.md
│   ├── requirement-clarification/
│   ├── prd-generation/
│   ├── e2e-web-search/
│   ├── e2e-codebase-mapping/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── openclaw-tools.md
│   │       └── trae-tools.md
│   ├── e2e-solution-design/         ← ★ 新增（SDD 方案设计）
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── plan-template.md
│   │       ├── task-template.md
│   │       ├── verification-template.md
│   │       ├── design-modes.md
│   │       ├── openclaw-tools.md
│   │       └── trae-tools.md
│   ├── e2e-dev-task-setup/
│   ├── e2e-remote-test/
│   │   ├── SKILL.md
│   │   ├── references/
│   │   └── scripts/
│   │       └── run-remote-test.sh  ← SSH 执行脚本
│   ├── e2e-deploy-pipeline/
│   ├── e2e-code-review-loop/
│   ├── e2e-progress-notify/
│   ├── e2e-architecture-draw/
│   └── e2e-prd-share/
│
├── docs/                            # 文档
│   ├── skill-orchestration-map.md
│   ├── existing-skills-inventory.md
│   ├── architecture.md              ← 本文件
│   ├── integration-trae.md
│   ├── integration-openclaw.md
│   └── integration-testing.md
│
├── configs/                         # 配置片段
│   └── openclaw-snippet.jsonc
│
└── install.sh                       # 部署脚本
```

### 生产期（两个运行时目录）

`install.sh` 默认把 14 个 skill 同时拷到两个目录；也可以用 `--target claude|openclaw` 按需单装。

```
~/.claude/skills/                 ← Claude Code CLI / Trae 内建 Claude Code
├── using-end-to-end-delivery/       ← 带 .installed-by-e2e-delivery 标记
├── adversarial-qa/
├── requirement-clarification/
├── prd-generation/
├── e2e-web-search/
├── e2e-codebase-mapping/
├── e2e-solution-design/              ← ★ 新增
├── e2e-dev-task-setup/
├── e2e-remote-test/
├── e2e-deploy-pipeline/
├── e2e-code-review-loop/
├── e2e-progress-notify/
├── e2e-architecture-draw/
├── e2e-prd-share/
│
├── <GSD 85 个 skill>                ← 本地已有（不动）
└── <用户自有若干>                    ← 本地已有（不动）

~/.agents/skills/                 ← OpenClaw / 龙虾
├── using-end-to-end-delivery/       ← 带 .installed-by-e2e-delivery 标记
├── adversarial-qa/
├── ... (同上 14 个)
│
├── bytedance-auth/                  ← 本地已有（不动）
├── bytedance-bits/
├── bytedance-codebase/
├── ... (另外 43 个)
```

**关键点**：

- 本项目 14 个 skill 和两个目录里的其他 skill **共处同目录**，靠命名（`e2e-` 前缀）和安装标记文件区分归属
- `install.sh --uninstall` 只删带 `.installed-by-e2e-delivery` 标记的目录，不误伤 GSD / `bytedance-*` / 用户自有 skill

---

## 五、端到端数据流

### 典型场景：非研发同学在飞书话题发起需求

```
1. 用户在飞书发消息：
   "@端到端交付 我们想做个用户分层运营的能力"
           │
           ▼
2. 飞书 Bot 收到消息 → OpenClaw Gateway
           │
           ▼
3. OpenClaw Gateway 路由到 "端到端交付" Agent：
   - 加载 AGENTS.md
   - 加载 ~/.agents/skills/ 下所有 skill（包括本项目 14 个 + 本地 46 个）
   - 组合成 LLM context 发给模型（千问 3.6 Plus）
           │
           ▼
4. LLM 判断：这是新需求 → 触发 using-end-to-end-delivery（1% 规则）
   → 继续触发 adversarial-qa（对抗式问答）
           │
           ▼
5. Agent 开始对抗式问答，通过飞书话题多轮对话
   (途中可能调 e2e-web-search, bytedance-cloud-docs 等)
           │
           ▼
6. 核心需求稳定 → HARD-GATE 确认 → 触发 prd-generation
           │
           ▼
7. PRD 定稿 → HARD-GATE 确认 → 进入阶段 3 现状理解
   ├─ Agent 推断项目类型（新 vs 存量）
   ├─ 明显存量 → 触发 e2e-codebase-mapping
   │  (内部调 bytedance-codebase + bytedance-bam → CODEBASE-MAPPING.md)
   ├─ 明显新项目 → 触发 e2e-web-search + bytedance-cloud-docs 轻量调研
   └─ 模糊 → HARD-GATE 询问用户
           │
           ▼
8. 现状理解完成 → 触发 e2e-solution-design ★ 新增阶段
   ├─ 子阶段 4.1: 生成 plan.md (含 Mermaid 架构图) → HARD-GATE
   ├─ 子阶段 4.2: 生成 task.md (中粒度 2-8h/任务)  → HARD-GATE
   └─ 子阶段 4.3: 生成 verification.md (5 章节 Schema) → HARD-GATE
   产出：specs/[简称]/ 下 3 个活文档
           │
           ▼
9. 方案定稿 → 触发 e2e-dev-task-setup
   (基于 task.md 汇总涉及仓库，创建 1 个 BITS task)
   (HARD-GATE --dry-run → 用户确认 → 实际创建 → 拿到链接)
           │
           ▼
10. BITS task 就绪 → 触发 e2e-code-review-loop
    (按 task.md 依赖拓扑轮次派发 Sub-Agent，并行改多仓代码)
    (Sub-Agent DONE 后，主 Agent 回写 task.md checkbox)
           │
           ▼
11. 所有 MR CI 通过 → HARD-GATE 合入确认 → 代码进 main
           │
           ▼
12. 触发 e2e-remote-test
    (读 verification.md § 1 § 2 AC → SSH 执行 → 回写结果)
           │
           ▼
13. § 1 § 2 Status 均 passed → 触发 e2e-deploy-pipeline
    (读 verification § 3 § 4 AC → BOE + PPE → 回写结果)
    (3 个独立 HARD-GATE：BOE 部署 / BOE 配置 / PPE 工单)
           │
           ▼
14. PPE 工单创建 → Agent 任务结束
    (verification § 5 人工 UAT 由用户填写)
    后续发布由公司审批流程驱动
           │
           ▼
15. (全流程贯穿) e2e-progress-notify 在每个关键节点
    通过 feishu-cli-msg 向话题/相关人发通知
```

---

## 六、关键机制详解

### 6.1 HARD-GATE（硬卡点）

**位置**：

1. PRD 定稿前（需求理解确认）
2. 研发任务创建前（BITS 任务信息确认）
3. 代码合入前（每个 MR 的 Diff 确认）
4. BOE 部署前（部署 payload 确认）
5. BOE 配置同步前（配置 diff 确认）
6. PPE 发布工单前（工单信息 + 回滚方案确认）

**实现**：

- 在 SKILL.md 中用 `<HARD-GATE>...</HARD-GATE>` 标记
- 底层依赖 `bytedance-*` 的 `--dry-run` 参数
- 等用户明确回复"确认"/"执行"/"go"

**禁止绕过**：即使用户说"一次性全部确认"，也要每个 HARD-GATE 独立询问。

### 6.2 Sub-Agent 四态协议

```
主 Agent 派发 Sub-Agent 时：
sessions_spawn(
    task_package=<精确的任务包>,
    tools=<白名单授权>,  # 不给部署类、通知类权限
    timeout_minutes=30
)
           │
           ▼
Sub-Agent 独立 context 执行任务
           │
           ▼
返回四态之一：
  ├─ DONE                  → 主 Agent 继续下一步
  ├─ DONE_WITH_CONCERNS    → 主 Agent 告知用户，让用户决定
  ├─ BLOCKED               → 主 Agent 停下等用户
  └─ NEEDS_CONTEXT         → 补充上下文重试（最多 2 次）
```

**仅在 `e2e-code-review-loop` 中使用**。其他 skill 由主 Agent 直接执行。

### 6.3 Skill 触发机制

LLM 根据每个 Skill 的 `description`（Frontmatter）判断是否调用。

**本项目的触发策略**：

- Bootstrap skill（`using-end-to-end-delivery`）在每个 session 必读
- 所有 skill 的 description 都是"推销式"——包含多个触发词变体
- 对话层 skill 倾向主动触发（对抗强度 5/5 的精神）

### 6.4 双运行时适配

**判断当前运行时**：

- 能看到 `feishu-cli-*` skill 可用 → 大概率是 OpenClaw + 飞书
- 在 IDE 上下文里 → Trae

**适配策略**：

- Trae：可用术语、简洁、直接操作本地文件
- OpenClaw + 飞书：避免术语、多确认、用飞书卡片通知

**Skill 内部**：每个复杂 skill 都有 `references/trae-tools.md` + `references/openclaw-tools.md` 说明运行时差异。

---

## 七、部署拓扑

### 方案 A：本地开发机（推荐给研发个人使用）

```
用户 Mac/Linux 本机
├── Trae IDE (研发用)
├── OpenClaw Gateway (service mode，后台常驻)
│   └── listens on localhost:18789
├── 飞书 PC 客户端（连本地 OpenClaw 作为机器人）
└── 公司 VPN（已连）→ 字节内网
```

**特点**：单用户、私人助手。

### 方案 B：共享机器（推荐给小团队使用）

```
共享服务器（Linux VM，公司内网）
├── OpenClaw Gateway (systemd service)
│   └── listens on internal-ip:18789
├── 飞书机器人 Webhook 配置到服务器
└── 多个用户的飞书话题都到这台服务器
```

**注意**：OpenClaw 官方**单用户设计**，多用户场景需要 workspace 隔离或走 profile 机制。

### 方案 C：Trae 单机（最轻量）

```
用户 IDE 内
├── Trae IDE（内建 Claude Code 模式）
├── ~/.claude/skills/ （Claude Code 标准路径，无需挂载）
└── 无飞书集成
```

**特点**：只做前置阶段（需求澄清、PRD、代码分析），不做部署。

---

## 八、安全模型

### 8.1 凭证管理

- 字节认证：`bytedance-auth` 管理（OAuth token 存 `~/.bytedance/`）
- 飞书认证：`feishu-cli-auth` 管理（存 `~/.feishu-cli/`）
- OpenClaw 自身：API keys 存 `~/.openclaw/`
- **不在 Agent Prompt / 对话记录中暴露 token**

### 8.2 HARD-GATE 作为安全屏障

每个写操作前的 HARD-GATE 是**核心安全控制**。它保证：

- 任何实际副作用操作都需要用户明确确认
- LLM 的"幻觉"不会直接变成线上操作

### 8.3 第三方 Skill 安全

- **本项目 14 个 skill**：由本团队维护，可信
- **本地 46 个已有 skill**：由 bytedance 内部维护，可信
- **ClawHub 第三方 skill**：⚠️ 不推荐安装，审查成本高

详见 `README.md` 的"安全审查 Checklist"。

### 8.4 SSH 安全

`e2e-remote-test` 使用的 SSH 连接依赖用户本地的 `~/.ssh/config` 和私钥：

- Agent 不存 SSH 凭证
- Agent 不转发 SSH key
- 只执行用户明确允许的命令（build + test）

---

## 九、限制与未来扩展

### 9.1 MVP 明确不做

- ❌ 上线后排障陪跑
- ❌ 开源化优化
- ❌ BITS quick-run 云端自测
- ❌ 飞书文档 PRD 输出

### 9.2 未来扩展方向

- **post-deploy-monitor skill**：上线后监控 + 快速回滚
- **e2e-prd-share-v2**：Markdown → 飞书文档的原生转换
- **e2e-cloud-test**：BITS quick-run 集成
- **e2e-smoke-test**：BOE 部署后的自动 smoke 测试
- **多语言 PRD 模板**：国际化团队使用

### 9.3 已知限制

- OpenClaw 目前**单用户设计**，多人协作需要改造
- `bytedance-*` 需要字节内网，公网场景受限
- LLM 路由 skill 偶尔会选错，需要通过 description 优化持续迭代
- Sub-Agent 并行度受 OpenClaw 资源限制

---

## 十、组件版本要求

| 组件 | 最低版本 | 推荐版本 |
|---|---|---|
| Node.js | 22.16+ | 24.x |
| OpenClaw | 最新稳定版 | 2026+ |
| Trae IDE | 支持 Agent Skills 的版本 | 最新 |
| 模型：千问 | 3.6 Plus | - |
| 模型：GLM（备选） | 5.1 | - |

---

## 附录：进一步阅读

- `README.md` —— 项目总览和硬约束清单
- `AGENTS.md` —— Agent 人格（主 Prompt）
- `docs/skill-orchestration-map.md` —— 完整的 Skill 编排流程图
- `docs/existing-skills-inventory.md` —— 46 个本地 skill 索引
- `docs/integration-trae.md` —— Trae 集成指引
- `docs/integration-openclaw.md` —— OpenClaw 集成指引
- `docs/integration-testing.md` —— 集成测试指引

---

*本架构文档随 MVP 迭代持续更新。*
