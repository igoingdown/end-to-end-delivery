# Skill Orchestration Map —— 端到端交付流程编排图

> **用途**：给 Agent 和维护者看的"完整流程说明书"。每一步做什么、调哪些 skill、HARD-GATE 在哪、Sub-Agent 何时派发。
>
> **阅读方式**：先看顶层流程图建立整体认知，再按需深入具体阶段。

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
     │ (对抗式问答)              │     目的：砍掉不合理需求
     └──────────┬───────────────┘
                │ 同步进行
                ▼
     ┌──────────────────────────┐
     │ requirement-clarification│  ← 结构化追问，MoSCoW 优先级
     │ (需求澄清)                │
     └──────────┬───────────────┘
                │
                ▼
     ┌──────────────────────────┐
     │ e2e-web-search           │  ← 遇到不确定点时主动调研
     │ (可选：外部调研)          │     (竞品、技术方案、行业 benchmark)
     └──────────┬───────────────┘
                │
                │ 核心需求稳定后，对抗强度切换到 2/5
                ▼

  ┌───────────────────────────────────────────────────────────┐
  │  <HARD-GATE>                                              │
  │  需求理解是否正确？                                        │
  │  Agent 主动总结核心需求并请求用户确认。                    │
  │  用户明确说 "确认" / "可以" 才继续。                       │
  └──────────────────────┬────────────────────────────────────┘
                         │
                         ▼
  ═══════════════════════════════════════════════════════════════
  【阶段 2：PRD 生成】gather → refine → reader-test 三阶段
  ═══════════════════════════════════════════════════════════════
                         │
                         ▼
              ┌──────────────────┐
              │ prd-generation   │  ← 三阶段 Markdown 生成
              │                  │     阶段 1: gather（聚合素材）
              │                  │     阶段 2: refine（自我审查）
              │                  │     阶段 3: reader-test（让用户读）
              └─────────┬────────┘
                        │
                        ▼
  ┌───────────────────────────────────────────────────────────┐
  │  <HARD-GATE>                                              │
  │  PRD 是否定稿？                                            │
  │  Agent 展示完整 Markdown，请求 "确认" / "修改"            │
  └──────────────────────┬────────────────────────────────────┘
                         │
                         │ (可选) 发一份 PRD 到飞书话题
                         ├──► e2e-prd-share (调 feishu-cli-msg)
                         │
                         ▼
  ═══════════════════════════════════════════════════════════════
  【阶段 3：代码库映射】只读分析，无 HARD-GATE
  ═══════════════════════════════════════════════════════════════
                         │
                         ▼
              ┌──────────────────────┐
              │ e2e-codebase-mapping │
              │                      │  内部调用：
              │                      │  ├─► bytedance-codebase (搜仓库、读文件)
              │                      │  ├─► bytedance-bam (查 IDL、Method)
              │                      │  └─► bytedance-hive (可选，查数据血缘)
              └──────────┬───────────┘
                         │
                         │  输出：涉及仓库清单 + 改动点 + 调用链
                         │  (可选) 画一份架构图到飞书白板
                         ├──► e2e-architecture-draw (调 feishu-cli-board)
                         │
                         ▼
  ═══════════════════════════════════════════════════════════════
  【阶段 4：研发任务与代码改造】写操作，HARD-GATE 密集
  ═══════════════════════════════════════════════════════════════
                         │
                         ▼
              ┌──────────────────────┐
              │ e2e-dev-task-setup   │
              │                      │  内部调用：
              │                      │  ├─► bytedance-auth (前置认证)
              │                      │  └─► bytedance-bits (创建任务+绑分支)
              └──────────┬───────────┘
                         │
  ┌──────────────────────┴────────────────────────────────────┐
  │  <HARD-GATE>                                              │
  │  BITS 任务创建 --dry-run 结果展示                          │
  │  关联仓库：[repo1, repo2, repo3]                           │
  │  关联分支：[feat/xxx]                                      │
  │  研发负责人：[...]                                         │
  │  QA：[...]                                                 │
  │  用户 "确认" 后去掉 --dry-run 实际创建                     │
  └──────────────────────┬────────────────────────────────────┘
                         │
                         ▼
              ┌────────────────────────────────┐
              │ e2e-code-review-loop           │
              │                                │  派发 Sub-Agents：
              │  for each repo in 改动仓库列表: │   ├─► Agent-repo1
              │    Sub-Agent 实现代码改动      │   ├─► Agent-repo2
              │    Sub-Agent 返回 DONE/        │   └─► Agent-repo3
              │           DONE_WITH_CONCERNS/  │
              │           BLOCKED/             │
              │           NEEDS_CONTEXT        │
              │                                │
              │  Controller 根据状态处理：      │
              │  - DONE → 下一个任务           │
              │  - DONE_WITH_CONCERNS → 告知用户 │
              │  - BLOCKED → 停下等指示        │
              │  - NEEDS_CONTEXT → 补充重试    │
              │                                │
              │  内部调用：                     │
              │  ├─► bytedance-codebase (MR+Diff)│
              │  └─► bytedance-bits (任务状态)  │
              └──────────┬─────────────────────┘
                         │
  ┌──────────────────────┴────────────────────────────────────┐
  │  <HARD-GATE>                                              │
  │  所有 MR 创建前展示 Diff 摘要                              │
  │  用户 "确认" 后才 push + 创建 MR                           │
  └──────────────────────┬────────────────────────────────────┘
                         │
                         │  (并行) 进度通知
                         ├──► e2e-progress-notify (调 feishu-cli-msg)
                         │
                         ▼
  ═══════════════════════════════════════════════════════════════
  【阶段 5：远端测试】MVP 简化版：假设代码已就绪
  ═══════════════════════════════════════════════════════════════
                         │
                         ▼
              ┌──────────────────┐
              │ e2e-remote-test  │
              │                  │  内置 SSH 脚本：
              │                  │  1. SSH 连接 (用户的 Dev SSH 配置)
              │                  │  2. cd 到已就绪的代码目录
              │                  │  3. 执行 [编译命令]
              │                  │  4. 执行 [测试命令]
              │                  │  5. 收集测试结果
              └─────────┬────────┘
                        │
                        │  前置假设：用户已用 Dev SSH 工具
                        │  把最新代码同步到开发机
                        ▼
             ┌─────────────────────┐
             │  测试通过？          │
             └───┬─────────────┬───┘
                 │ 通过         │ 失败
                 │              │
                 ▼              ▼
              下一阶段    回到阶段 4（code-review-loop 修复）
                         │
                         ▼
  ═══════════════════════════════════════════════════════════════
  【阶段 6：部署】严重副作用，最强 HARD-GATE
  ═══════════════════════════════════════════════════════════════
                         │
                         ▼
              ┌──────────────────────┐
              │ e2e-deploy-pipeline  │
              │                      │  子阶段 6.1 - BOE 部署
              │                      │  ├─► bytedance-env (BOE 环境配置)
              │                      │  ├─► bytedance-tce (容器部署)
              │                      │  └─► bytedance-tcc (配置同步)
              └──────────┬───────────┘
                         │
  ┌──────────────────────┴────────────────────────────────────┐
  │  <HARD-GATE>                                              │
  │  BOE 部署 --dry-run 展示：                                 │
  │  服务：[...] 版本：[...] 配置变更：[...]                   │
  │  用户 "确认" 后部署                                        │
  └──────────────────────┬────────────────────────────────────┘
                         │
                         │  BOE 部署完成 → 自动跑联调测试？(未来扩展)
                         ▼
              ┌──────────────────────┐
              │ e2e-deploy-pipeline  │
              │  (继续)              │  子阶段 6.2 - PPE 工单
              │                      │  └─► bytedance-bits create-ticket
              └──────────┬───────────┘
                         │
  ┌──────────────────────┴────────────────────────────────────┐
  │  <HARD-GATE>                                              │
  │  PPE 发布工单 --dry-run 展示：                             │
  │  审批人：[...] 发布窗口：[...] 回滚方案：[...]              │
  │  用户 "确认" 后创建工单                                    │
  └──────────────────────┬────────────────────────────────────┘
                         │
                         │  工单创建成功 → 等待审批 → 发布
                         │  (实际发布由公司流程驱动，Agent 不直接操作)
                         ▼
  ═══════════════════════════════════════════════════════════════
  【结束 / 话题归档】
  ═══════════════════════════════════════════════════════════════
                         │
                         ▼
              ┌──────────────────────┐
              │ 话题归档时生成总结：  │
              │  - 需求摘要           │
              │  - 关键决策           │
              │  - 产出物（PRD/MR/工单）│
              │  - 未决问题           │
              │  - 后续建议           │
              │  通过 feishu-cli-msg  │
              │  发到话题作为最后消息 │
              └──────────────────────┘
```

---

## 每个阶段的详细编排

### 阶段 1：需求澄清

**输入**：用户的模糊需求描述

**核心 skill**：
- `adversarial-qa`（强度 5/5 → 2/5 动态切换）
- `requirement-clarification`（结构化追问）
- `e2e-web-search`（可选，遇到不确定点触发）

**Agent 的工作模式**：
1. 用户说"我想做 XX"，先调用 `adversarial-qa`
2. 对抗问答过程中，如果发现需要历史方案参考，调 `bytedance-cloud-docs`
3. 如果发现需要竞品或行业数据，调 `e2e-web-search`
4. 在对抗过程中同步收集 MoSCoW 需求（must/should/could/won't）
5. 核心需求稳定后，切换到 `requirement-clarification` 做细节澄清

**HARD-GATE 出口条件**：
- [ ] 核心需求一句话描述清楚
- [ ] 价值假设明确
- [ ] 范围边界明确（什么做什么不做）
- [ ] 验收标准初步形成

**典型对话长度**：10-30 轮

---

### 阶段 2：PRD 生成

**输入**：阶段 1 的澄清结果

**核心 skill**：`prd-generation`

**三阶段工作流**（抄 anthropics/doc-coauthoring）：

| 阶段 | 动作 | 输出 |
|---|---|---|
| **Gather** | 聚合阶段 1 的所有素材 | 结构化的原始信息集 |
| **Refine** | Agent 自我审查 + 组织为 PRD | PRD 草稿（Markdown） |
| **Reader-Test** | 请用户"扮演读者"通读并提问 | 最终 PRD |

**Markdown PRD 标准结构**：

```markdown
# [需求名称]

## 一句话说明
[一句话讲清楚做什么]

## 为什么做（Why）
- 业务价值
- 用户痛点
- 机会窗口

## 做什么（What）
### 核心能力
- [MoSCoW: Must-have]
- ...
### 不做什么
- [明确的 Out-of-Scope]

## 怎么做（How - 方案概要）
[技术方案初步描述，详细设计留到阶段 3 后]

## 验收标准
- [ ] ...

## 风险与依赖
- ...
```

**HARD-GATE 出口条件**：用户明确说"PRD OK" / "确认" / "可以进入下一步"。

---

### 阶段 3：代码库映射

**输入**：PRD 中的"怎么做"部分

**核心 skill**：`e2e-codebase-mapping`

**Agent 的工作模式**（纯只读，无 HARD-GATE）：

1. 根据 PRD 识别涉及的业务域
2. 调 `bytedance-codebase` 搜相关仓库
3. 调 `bytedance-bam` 查涉及的服务和 IDL
4. (可选) 调 `bytedance-hive` 查数据依赖
5. 综合产出"改动点清单"

**输出格式示例**：

```markdown
## 涉及仓库

1. `order-service` (PSM: ecommerce.order.api)
   - 改动文件：`handler/order.go`, `service/split.go`
   - 改动原因：增加订单分层字段

2. `user-profile-service` (PSM: user.profile.api)
   - 改动文件：`model/user_level.go`
   - 改动原因：新增用户分层读取接口

## 调用链

[调用顺序图或依赖图]

## 潜在风险点

- order-service 的 IDL 变更需同步通知 3 个下游服务
- user-profile-service 有缓存，需要清理策略
```

**可选延伸**：调 `e2e-architecture-draw`（底层 `feishu-cli-board`）画架构图发到飞书白板。

---

### 阶段 4：研发任务与代码改造

**两个核心 skill**：
- `e2e-dev-task-setup`（一次性操作）
- `e2e-code-review-loop`（循环操作 + Sub-Agent 派发）

#### 4.1 `e2e-dev-task-setup`

**主要调用**：`bytedance-bits` 的 `create-dev-task --change ...`

**关键参数**（来自 `bytedance-bits` SKILL 文档）：
- `--change "service=PSM1,branch=fix/feature1"` 多仓绑定（每个仓库一个 `--change`）
- `--dry-run` HARD-GATE（先展示 payload）

**HARD-GATE**：展示完整 payload（包含所有 `--change`、研发负责人、QA、关联 Meego 需求单），用户确认。

#### 4.2 `e2e-code-review-loop`

**Sub-Agent 派发模式**：

```
for each repo in 改动仓库列表:
    派发 Sub-Agent 到该仓库
    Sub-Agent 任务：
      1. 读仓库上下文
      2. 根据 PRD 实现代码改动
      3. 本地测试（lint + unit test）
      4. 返回四态：DONE / DONE_WITH_CONCERNS / BLOCKED / NEEDS_CONTEXT

主 Agent 收集所有 Sub-Agent 结果：
  - 全部 DONE → 进入 Code Review
  - 有 BLOCKED → 停下来告知用户
  - 有 NEEDS_CONTEXT → 补充上下文重试（最多 2 次）
  - 有 DONE_WITH_CONCERNS → 汇总关注点给用户决策
```

**Code Review 阶段**：

- 派发专门的 "Reviewer Sub-Agent" review 每个 MR
- 调 `bytedance-codebase` 查 MR Diff 和 Check Run
- CI 失败时 Sub-Agent 返回 `NEEDS_CONTEXT`，主 Agent 分析并指示修复

**HARD-GATE**：所有 MR 创建前展示 Diff 摘要 + 测试结果，用户确认后 push。

---

### 阶段 5：远端测试（MVP 简化版）

**核心 skill**：`e2e-remote-test`

**前置假设（MVP）**：用户已用自己的 Dev SSH 工具把最新代码同步到开发机。

**Skill 内部流程**：

```bash
#!/bin/bash
# e2e-remote-test/scripts/run.sh

set -e

DEV_HOST="$1"      # 用户配置的开发机 SSH alias
REMOTE_DIR="$2"    # 远端代码目录
BUILD_CMD="$3"     # 编译命令，e.g. "go build ./..."
TEST_CMD="$4"      # 测试命令，e.g. "go test ./..."

echo "[e2e-remote-test] SSH 连接 $DEV_HOST..."
ssh "$DEV_HOST" << EOF
set -e
cd "$REMOTE_DIR"
echo "[remote] 开始编译..."
$BUILD_CMD
echo "[remote] 编译完成，开始测试..."
$TEST_CMD
EOF

echo "[e2e-remote-test] 测试完成。"
```

**关键约束**：
- 不做本地测试（硬约束）
- 不做代码同步（MVP 简化）
- 单纯"SSH + 执行命令 + 收集结果"

**失败处理**：返回失败的测试用例和日志，让主 Agent 决定是否回到阶段 4。

---

### 阶段 6：部署

**核心 skill**：`e2e-deploy-pipeline`

**两个子阶段**：

#### 6.1 BOE 部署

- 调 `bytedance-env` 查目标 BOE 环境配置
- 调 `bytedance-tce` 触发容器部署
- 调 `bytedance-tcc` 同步配置

**HARD-GATE**：展示 `--dry-run` payload（服务名、版本、变更清单），用户确认。

#### 6.2 PPE 工单

- 调 `bytedance-bits create-ticket`（带 `--dry-run`）

**HARD-GATE**：展示工单信息（审批人、发布窗口、回滚方案），用户确认后创建。

**工单创建后**：Agent 的工作结束——实际发布由公司流程驱动（审批 → 发布 → 监控），Agent 不直接操作。

---

## Sub-Agent 派发详细规范

### 何时派发 Sub-Agent

**只在阶段 4 派发**（`e2e-code-review-loop`）。其他阶段主 Agent 独立完成。

### 派发规范

```
主 Agent 调用 OpenClaw 的 sessions_spawn 创建 Sub-Agent
Sub-Agent 继承：
  - 项目 context（PRD + 改动点清单）
  - 目标仓库信息
Sub-Agent 独立 context window
Sub-Agent 任务结束时返回四态之一
```

### 四态处理矩阵

| 返回状态 | 主 Agent 处理 | 给用户的反馈 |
|---|---|---|
| `DONE` | 继续下一个 repo 或下一阶段 | 无需反馈，进度条前进 |
| `DONE_WITH_CONCERNS` | 先告知用户关注点 | "repo1 完成，但 Sub-Agent 提醒：[关注点]" |
| `BLOCKED` | 停下来 | "repo1 遇到阻塞：[原因]，需要您的指示" |
| `NEEDS_CONTEXT` | 补充上下文重试（最多 2 次） | "repo1 需补充信息，我正在重试" |

---

## 主线失败处理

### 阶段 1 失败：需求始终不清晰

- 经过 30+ 轮对话仍未达成澄清
- **处理**：建议用户 offline 先想清楚，Agent 提供一份"待澄清清单"

### 阶段 4 失败：Sub-Agent 反复 BLOCKED

- 同一 repo 连续 2 次 BLOCKED
- **处理**：降级为"主 Agent 串行处理"，或建议用户手动介入

### 阶段 5 失败：测试反复不通过

- 同一测试连续失败 3 次
- **处理**：停止循环，告知用户失败日志，等待指示

### 阶段 6 失败：部署工具报错

- `bytedance-tce` 或 `bytedance-tcc` 执行失败
- **处理**：先调 `bytedance-auth` 确认登录状态，再看错误是否在 `troubleshooting.md` 覆盖范围。不在覆盖范围 → `BLOCKED` 给用户。

---

## 快速参考：每阶段调用的 skill 一览

| 阶段 | 新 Skill | 依赖的已有 Skill |
|---|---|---|
| 0. Bootstrap | `using-end-to-end-delivery` | 无 |
| 1. 需求澄清 | `adversarial-qa`、`requirement-clarification`、`e2e-web-search` | `bytedance-cloud-docs`、`feishu-cli-search`（可选） |
| 2. PRD 生成 | `prd-generation` | 无 |
| 2.5 PRD 分享 | `e2e-prd-share` | `feishu-cli-msg` |
| 3. 代码库映射 | `e2e-codebase-mapping` | `bytedance-codebase`、`bytedance-bam` |
| 3.5 画架构图 | `e2e-architecture-draw` | `feishu-cli-board` |
| 4a. 研发任务 | `e2e-dev-task-setup` | `bytedance-auth`、`bytedance-bits` |
| 4b. 代码改造 | `e2e-code-review-loop` | `bytedance-codebase`、`bytedance-bits` |
| 4c. 进度通知 | `e2e-progress-notify` | `feishu-cli-msg` |
| 5. 远端测试 | `e2e-remote-test` | 无（内置 SSH） |
| 6. 部署 | `e2e-deploy-pipeline` | `bytedance-env`、`bytedance-tce`、`bytedance-tcc`、`bytedance-bits` |

---

*本文档在 MVP 之后会随主流程变化持续更新。*
