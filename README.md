# End-to-End Delivery

一个端到端的软件交付 Agent，帮助**非研发同学**和**研发同学**在飞书话题或 Trae IDE 里完成从"模糊想法"到"BOE/PPE 部署"的全链路交付。

> **MVP 版本**：聚焦"需求澄清 → Markdown PRD → 代码改造 → SSH 远端测试 → 部署"主链路。
> **暂不包含**：飞书文档 PRD、上线后排障、开源化（后续版本逐步加入）。

---

## 核心理念：编织而非建造

本项目**不重造轮子**。本机 `~/.agents/skills/` 下已安装 46 个 skill（字节 DevOps、飞书、认证等），本项目只新增 14 个**黏合层 skill**，把它们编织成端到端交付的完整流程。

```
本项目 14 个新 skill          ←→          本地已有 46 个 skill
   (编排层/对话层)                           (底层能力)
  e2e-codebase-mapping  ────调用────►  bytedance-codebase + bam
  e2e-dev-task-setup    ────调用────►  bytedance-bits
  e2e-deploy-pipeline   ────调用────►  bytedance-env / tce / tcc
  e2e-progress-notify   ────调用────►  feishu-cli-msg
  ...
```

---

## 运行时支持

| 运行时 | 入口 | Skill 目录 | 主要用户 | 场景 |
|---|---|---|---|---|
| **Claude Code CLI** | 直接 `claude` | `~/.claude/skills/` | 研发同学 | 本机终端 / CI |
| **Trae IDE（内建 Claude Code）** | Trae 对话面板 | `~/.claude/skills/`（共用） | 研发同学 | 前置阶段（需求澄清、PRD、代码分析） |
| **OpenClaw + 飞书话题** | `@端到端交付` 开新话题 | `~/.agents/skills/` | 非研发同学为主 | 全链路陪跑 |

同一套 skill 通过 `install.sh --target all`（默认）一次拷到两个目录：Claude Code / Trae 内建 Claude Code 读 `~/.claude/skills/`，OpenClaw / 龙虾读 `~/.agents/skills/`。Skill 内部通过 `references/trae-tools.md` 和 `references/openclaw-tools.md` 做跨平台适配。

---

## 项目结构

```
end-to-end-delivery/
├── AGENTS.md                          # 中文主 Prompt（Agent 人格）
├── README.md                          # 你正在看的这个文件
├── LICENSE
├── .gitignore
│
├── skills/                            # 14 个新 skill（MVP 范围）
│   ├── using-end-to-end-delivery/     # [1] Bootstrap 元 skill
│   │   └── SKILL.md
│   │
│   ├── adversarial-qa/                # [2] 对话层：对抗式问答
│   ├── requirement-clarification/     # [3] 对话层：需求澄清
│   ├── prd-generation/                # [4] 对话层：PRD 生成（Markdown）
│   ├── e2e-web-search/                # [5] 对话层：Web 调研
│   │
│   ├── e2e-codebase-mapping/          # [6] 编排层：跨仓分析（仅 brownfield）
│   ├── e2e-solution-design/           # [7] 编排层：方案设计（plan/task/verification 三件套）
│   ├── e2e-dev-task-setup/            # [8] 编排层：研发任务初始化（BITS）
│   ├── e2e-remote-test/               # [9] 编排层：SSH 远端测试（内置 scripts/run-remote-test.sh）
│   ├── e2e-deploy-pipeline/           # [10] 编排层：部署
│   ├── e2e-code-review-loop/          # [11] 编排层：代码 review 循环
│   │
│   ├── e2e-progress-notify/           # [12] 飞书层：进度通知
│   ├── e2e-architecture-draw/         # [13] 飞书层：架构图绘制
│   └── e2e-prd-share/                 # [14] 飞书层：PRD 分享
│
├── docs/
│   ├── skill-orchestration-map.md     # 完整流程图 + skill 地图
│   ├── existing-skills-inventory.md   # 本地 46 个 skill 索引
│   ├── architecture.md                # 架构设计
│   ├── integration-trae.md            # Trae 集成说明
│   ├── integration-openclaw.md        # OpenClaw 集成说明
│   └── integration-testing.md         # 集成 smoke test 清单
│
├── configs/
│   └── openclaw-snippet.jsonc         # OpenClaw 配置片段（JSON5/JSONC）
│
├── .planning/codebase/                # 代码库画像（ARCHITECTURE / STACK / ...）
├── .claude/                           # Claude Code 本地 settings
└── install.sh                         # 同步到 ~/.claude/skills/ 和/或 ~/.agents/skills/ 的安装脚本
```

---

## Skill 复杂度判定矩阵

> 本矩阵来自对话中对齐的三维度标准。
> 用于**判断新 skill 到底该做简单还是复杂**，避免过度设计或欠设计。

### 三维度

| 维度 | 简单 Skill（纯 SKILL.md） | 复杂 Skill（SKILL.md + scripts/） |
|---|---|---|
| **步骤数** | 1-3 步，单轮完成 | 4 步及以上，或需循环/分支 |
| **人工卡点** | 无需批准，一次跑完 | 需要 1 个及以上 HARD-GATE |
| **副作用** | 只读 / 只查 / 纯对话 | 有写操作（发消息、部署、push 代码、改数据） |
| **失败代价** | 错了重跑即可 | 错了产生外部后果 |
| **状态** | 无状态 | 有中间状态，需要恢复能力 |

### 判定规则（命中即停）

1. 只要有**写操作或部署动作** → **复杂 Skill**（哪怕 2 步）
2. 只要需要**循环**（code → test → fix 直到通过）→ **复杂 Skill**
3. 只要**中途需等待人工确认** → **复杂 Skill**
4. 只要**跨 3 个以上 skill 组合调用** → **复杂 Skill**
5. 以上都不是 → **简单 Skill**

### 本项目 14 个 Skill 的落位

| Skill | 类型 | 原因 |
|---|---|---|
| `using-end-to-end-delivery` | 简单 | 纯文档参考 |
| `adversarial-qa` | 简单 | 纯对话 |
| `requirement-clarification` | 简单 | 纯对话 |
| `prd-generation` | 简单 | 写 Markdown 文件，副作用极小 |
| `e2e-web-search` | 简单 | 只读 |
| `e2e-codebase-mapping` | 简单 | 只读多仓（仅 brownfield） |
| `e2e-solution-design` | **复杂** | 三阶段产出 3 文档 + 3 个 HARD-GATE |
| `e2e-dev-task-setup` | **复杂** | 有写操作（创建 BITS 研发任务） |
| `e2e-remote-test` | **复杂** | 有 SSH 连接 + 测试执行 + 回写 verification |
| `e2e-deploy-pipeline` | **复杂** | 严重副作用（部署）+ 3 HARD-GATE + 回写 verification |
| `e2e-code-review-loop` | **复杂** | 有循环 + Sub-Agent 派发 + 主 Agent 回写 task.md |
| `e2e-progress-notify` | 简单 | 单次发消息 |
| `e2e-architecture-draw` | 简单 | 单次生成图 |
| `e2e-prd-share` | 简单 | 单次发消息 |

### 灰色案例说明

- **调 `bytedance-tcc` 查配置** → 简单（只读）
- **调 `bytedance-tcc` 改配置** → 复杂（写操作 + 强 HARD-GATE）
- **生成本地 Markdown 文件** → 简单（可覆盖，代价低）
- **在飞书发消息给话题外的人** → 复杂（外部通知副作用）

---

## 引用已有 Skill 的地图

本项目的核心设计是**"引用而非重写"**。新 skill 的 SKILL.md 里会明确说明"这个 skill 内部调用 X skill + Y skill"。

### 引用依赖图（MVP 范围）

```
阶段 1：需求澄清
├── adversarial-qa              (独立，无依赖)
├── requirement-clarification   (独立，无依赖)
└── e2e-web-search              → 可选调用 bytedance-cloud-docs

阶段 2：PRD 生成
└── prd-generation              (独立，产出 PRD.md)

阶段 3：现状理解（分支）★ 项目类型判断
├── brownfield → e2e-codebase-mapping → CODEBASE-MAPPING.md
│   ├── → bytedance-codebase    (搜代码仓库、读文件、Diff)
│   └── → bytedance-bam         (查服务 IDL、Method)
└── greenfield → e2e-web-search + bytedance-cloud-docs (轻量调研)

阶段 4：方案设计 ★ 新增（SDD 三件套）
└── e2e-solution-design         → specs/[简称]/plan.md + task.md + verification.md
    └── (Agent 自己生成 Mermaid，不调底层 skill)

阶段 5：研发任务与代码改造
├── e2e-dev-task-setup          → 基于 task.md 建 1 个 BITS task
│   ├── → bytedance-auth        (前置认证)
│   └── → bytedance-bits        (create --dry-run → confirm → 实际创建)
└── e2e-code-review-loop        → 按 task.md 派发 Sub-Agent
    ├── 主 Agent 回写 task.md checkbox
    ├── → bytedance-codebase    (MR、Diff、Check Run)
    └── → (Sub-Agent 独立 context，只读 plan.md/verification.md)

阶段 6：远端测试
└── e2e-remote-test             → 回写 verification.md § 1 § 2
    └── (MVP 简化版，内置 SSH 脚本)

阶段 7：部署
└── e2e-deploy-pipeline         → 回写 verification.md § 3 § 4
    ├── → bytedance-env         (环境配置)
    ├── → bytedance-tce         (容器部署)
    ├── → bytedance-tcc         (配置变更)
    └── → bytedance-bits        (发布工单 create-ticket)

通知与协作（跨阶段）
├── e2e-progress-notify         → feishu-cli-msg
├── e2e-architecture-draw       → feishu-cli-board (可选同步)
└── e2e-prd-share               → feishu-cli-msg
```

完整的本地 skill 索引见 `docs/existing-skills-inventory.md`。

---

## 安全审查 Checklist（强制）

### 第三方 Skill 安装前

从 ClawHub 或任何外部源安装新 skill，**必须**按以下清单审查：

- [ ] `cat SKILL.md` 通读全文，确认没有可疑指令
- [ ] `ls scripts/` 检查是否有脚本，有的话逐个审查
- [ ] 搜索是否有向外部 URL 发送数据的逻辑（`curl`、`wget`、`fetch` 等）
- [ ] 搜索是否有读取敏感文件的逻辑（`~/.ssh/`、`~/.aws/`、环境变量 dump）
- [ ] 检查 `--allow-network`、`--sudo` 等危险参数
- [ ] 确认 skill 作者可信（优先官方源：`anthropics/skills`、`openclaw/skills`、`obra/superpowers`）

### 写操作 Skill 调用前（HARD-GATE）

本项目 Agent 调用任何**写操作 skill** 时，必须：

1. 首次调用带 `--dry-run`
2. 把 payload 完整展示给用户
3. 用户明确回复"确认"/"执行"/"go"后才去掉 `--dry-run` 实操
4. 每次新的写操作都要重新走这个流程，不能"一次确认走天下"

### 敏感数据保护

- 绝不在 Prompt / 日志中输出真实的 API Key、Token、密码
- 用户信息（email、工号）在 skill 内部处理，不要回显给群聊
- 调用 `bytedance-rds` 查业务数据时，结果不转发给话题外的用户

---

## 部署位置

| 阶段 | 位置 | 读取方 |
|---|---|---|
| **开发期** | `~/github/end-to-end-delivery/` (Git 管理) | — |
| **生产期（Claude Code）** | `~/.claude/skills/` | Claude Code CLI / Trae 内建 Claude Code |
| **生产期（OpenClaw）** | `~/.agents/skills/` | OpenClaw / 龙虾（Gateway 加载顺序第 3 优先级） |

通过 `install.sh` 同步。默认 `--target all` 两处都装；`--target claude` 只装 Claude Code 目录，`--target openclaw` 只装 OpenClaw 目录。每个 skill 装好后会在目录下留一个 `.installed-by-e2e-delivery` 标记文件，`--uninstall` 只删带标记的目录，从不误伤本地自有 skill。

### 命名冲突规则

两个生产期目录（`~/.claude/skills/` 和 `~/.agents/skills/`）都可能已经有其他来源的 skill（前者有 GSD 的 85 个 + 用户自有；后者有本地字节 `bytedance-*` / 飞书 `feishu-cli-*` 共 46 个）。新增 14 个 skill 的命名原则：

- **对话层 4 个**：保留原语义名（`adversarial-qa`、`requirement-clarification`、`prd-generation`），全局唯一无冲突
- **编排层 6 个**：统一加 `e2e-` 前缀（`e2e-codebase-mapping`、`e2e-solution-design`、`e2e-dev-task-setup` 等）
- **飞书层 3 个**：统一加 `e2e-` 前缀
- **Bootstrap 1 个**：`using-end-to-end-delivery`，长名不冲突

### 已验证无重名冲突

全部 14 个新 skill 名和两个目录现有清单对比，零冲突。`install.sh` 在每个目标独立判冲突：带 `.installed-by-e2e-delivery` 标记的视为本项目装的（更新），无标记的视为用户自有（报错停止，需 `--force` 才覆盖）。

---

## 参考项目

本项目设计借鉴了以下开源项目：

- **[obra/superpowers](https://github.com/obra/superpowers)** —— Skill 使用协议、1% 规则、HARD-GATE、Sub-Agent 四态协议、多平台工具映射层
- **[anthropics/skills](https://github.com/anthropics/skills)** —— SKILL.md 规范、progressive disclosure、reference files 组织、反 AI-slop
- **[openclaw/openclaw](https://github.com/openclaw/openclaw)** —— Agent Skills 标准运行时、飞书 channel 原生支持

---

## 硬约束清单

本项目的硬约束（不可违反）：

1. 单元测试只能在公司远端 Docker 开发机跑（SSH）
2. Facade 层屏蔽内部 MCP 实现细节
3. 部署走 Git push → CI/CD + 发布工单
4. 对抗强度：前期硬核 → 后期温和
5. PRD 采用 Markdown（MVP）
6. 千问 3.6 Plus 首选，GLM-5.1 备选
7. 单一触发词 + LLM 路由
8. PRD 定稿走 Agent 主动提议 + 用户确认
9. 非研发同学可用是 UX 核心
10. Skill 按运行时分别安装：Claude Code / Trae 内建 Claude Code 共用 `~/.claude/skills/`；OpenClaw / 龙虾 用 `~/.agents/skills/`。通过 `install.sh --target claude|openclaw|all` 统一同步
11. 开发期 `~/github/end-to-end-delivery/`
12. Skill 复杂度判定见本 README
13. 话题归档 Agent 产出总结
14. 双运行时兼容
15. 采用 Agent Skills 开放标准
16. 每 session 必读 `using-end-to-end-delivery`
17. 关键节点用 HARD-GATE
18. Sub-Agent 四态协议
19. 复杂 skill 必带工具映射层
20. PRD 三阶段（gather → refine → reader-test）
21. 所有 skill 含反 AI-slop 规范
22. 外部 skill 安装前人工审查
23. 新 skill 用 `e2e-` 或明确前缀避冲突
24. `bytedance-*` 写操作默认 `--dry-run`
25. MVP 不做 BITS quick-run，只用 SSH
26. MVP 不做上线后排障
27. MVP 阶段不做主动开源推广（仓库已附 MIT LICENSE，文件级开源，但不对外宣发）
28. 主流程 7 阶段（需求澄清→PRD→现状→方案→代码→测试→部署），引入 Spec-Driven Development
29. 方案设计阶段产出 3 文档：plan.md + task.md + verification.md（Kiro/Spec Kit 对齐命名）
30. 产物目录约定 `specs/[需求简称]/`（下设 plan/task/verification）
31. 单一创建原则：3 活文档只由 `e2e-solution-design` 创建，其他 skill 只消费或更新已有字段
32. verification.md 章节 Owner 固定：§1/§2 = remote-test，§3/§4 = deploy-pipeline，§5 = human

---

## 快速开始

```bash
# 1. 克隆项目到本地
cd ~/github
git clone <this-repo>
cd end-to-end-delivery

# 2. 安装到运行时 skill 目录
./install.sh                        # 默认两处都装（Claude Code + OpenClaw）
# 或按需选择：
# ./install.sh --target claude      # 只装 ~/.claude/skills/（Claude Code / Trae 内建 Claude Code）
# ./install.sh --target openclaw    # 只装 ~/.agents/skills/（OpenClaw / 龙虾）
# ./install.sh --dry-run            # 预览不实际拷贝

# 3a. Claude Code / Trae 用户：重启 Claude Code 会话即可生效
#     在新对话里 /context 应能看到 using-end-to-end-delivery 等 skill

# 3b. OpenClaw 用户：重启 gateway 以加载新 skill
openclaw config set skills.load.extraDirs '["~/.agents/skills"]'
openclaw gateway restart

# 4. 在飞书话题或 Claude Code CLI 里测试
#    @端到端交付 帮我做个用户积分体系的需求
```

---

## 版本

- **版本**：MVP v0.1
- **状态**：开发中

---

*最后更新：2026-04-28*
