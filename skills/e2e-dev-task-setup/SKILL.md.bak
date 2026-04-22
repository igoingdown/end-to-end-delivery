---
name: e2e-dev-task-setup
description: "端到端交付的研发任务初始化 skill，基于跨仓代码映射的产出，通过字节 BITS 平台创建研发任务、绑定多仓分支、关联 Meego 需求单。本 skill 是写操作 skill，必须遵守 HARD-GATE：首次调用必须带 --dry-run 展示 payload，用户明确确认后才实际创建。当需要在 BITS 创建研发任务、多仓联动开发、关联需求到代码的场景必须调用此 skill。典型触发场景：'帮我创建研发任务'、'BITS 开个任务'、'绑定分支到 BITS'、'我们要开始开发'、'代码映射完了，创任务'、'把这几个仓库的改动串起来'。内部调用 bytedance-auth 确认登录 + bytedance-bits 创建任务。产出的 dev-id 会作为后续 e2e-code-review-loop 的输入。"
---

# E2E Dev Task Setup —— 研发任务初始化

## 定位

端到端交付主流程的**阶段 4a**：把 PRD + 代码映射正式转化为**研发任务**。

**输入**：`e2e-codebase-mapping` 的产出（涉及仓库清单）
**输出**：BITS 上的 dev-task ID，绑定了所有涉及仓库的开发分支

**本 skill 是写操作**。必须遵守 HARD-GATE。

---

## 前置条件

进入本 skill 前，必须：

- [x] `e2e-codebase-mapping` 已产出"涉及仓库清单"
- [x] 用户明确了每个仓库的**开发分支命名**（`feature/xxx`）
- [x] `bytedance-auth` 已登录
- [x] 用户提供了研发负责人、QA 人选（BITS 必填字段）
- [x] 用户提供了关联的 Meego 需求单 ID（如有）

缺失任一 → 先补齐，**不要猜测**。

---

## 核心工作流

```
输入：涉及仓库清单 + 元信息
   │
   ▼
┌────────────────────────────────────────┐
│ 步骤 1：收集 BITS 必填字段              │
│ - 任务名称（从 PRD 一句话说明提炼）    │
│ - 研发负责人                            │
│ - QA                                   │
│ - Meego 需求单 ID                       │
│ - 计划完成时间                          │
└──────────────────┬─────────────────────┘
                   │
                   ▼
┌────────────────────────────────────────┐
│ 步骤 2：构造 --change 参数              │
│ 每个涉及仓库一个 --change              │
│ 格式: service=PSM,branch=feat/xxx      │
└──────────────────┬─────────────────────┘
                   │
                   ▼
┌────────────────────────────────────────┐
│ 步骤 3：--dry-run 预览                  │
│ 调 bytedance-bits 创建任务但带 --dry-run│
│ 展示完整 payload                        │
└──────────────────┬─────────────────────┘
                   │
                   ▼
           【HARD-GATE】
   展示 payload + 等用户明确确认
                   │
                   │ 用户确认
                   ▼
┌────────────────────────────────────────┐
│ 步骤 4：去掉 --dry-run 实际创建          │
│ 收集返回的 dev-id                       │
└──────────────────┬─────────────────────┘
                   │
                   ▼
┌────────────────────────────────────────┐
│ 步骤 5：（可选）bind-branch             │
│ 如果某些仓库的分支还不存在，引导创建    │
└──────────────────┬─────────────────────┘
                   │
                   ▼
产出：dev-id + 初始化报告
```

---

## 步骤详解

### 步骤 1：收集必填字段

从对话上下文中**主动搜集**以下字段：

| 字段 | 来源 | 如何获得 |
|---|---|---|
| 任务名称 | PRD 一句话说明 | 自动提取 |
| 研发负责人 | 用户 | **必须**问用户 |
| QA | 用户 | **必须**问用户 |
| Meego 需求单 ID | 用户或飞书历史 | 问用户，如果有则提供 |
| 计划完成时间 | PRD 发布计划 | 从 PRD 提取；没有则问用户 |
| 关联业务线 | PRD / codebase-mapping | 自动判断，用户确认 |

**缺字段时**，用**结构化提问**（不要一次问全部）：

```
我需要补充 2 个 BITS 必填字段才能创建任务：

1. 研发负责人（RD）是谁？（写邮箱前缀，比如 zhangsan）
2. QA 同学是谁？

请提供后我生成 payload 预览。
```

### 步骤 2：构造 `--change` 参数

`bytedance-bits` 的 `--change` 格式：

```
--change "service=<PSM>,branch=<sourceBranch>[,target=<targetBranch>]"
```

**每个涉及仓库一个 `--change`**。从 `e2e-codebase-mapping` 的产出表格里自动填充：

```
涉及仓库清单（来自 codebase-mapping）:
| 仓库 | PSM | 改动级别 |
| xxx-api | user.segment.api | ★ |
| yyy-service | segment.calculator.service | ★ |
| zzz-frontend | operation.platform.web | ◇ |

生成：
--change "service=user.segment.api,branch=feat/user-segment"
--change "service=segment.calculator.service,branch=feat/user-segment"
--change "service=operation.platform.web,branch=feat/user-segment"
```

**注意**：
- 分支名建议统一（同一 feature 跨仓用同一个分支名），方便追踪
- `◇ 受影响` 的仓库是否加入 `--change`？**默认不加**，只加 `★ 核心改动`
- 例外：`◇ 受影响` 但需要前端同步联调的，也加入

**询问用户**确认分支命名约定：

```
我建议统一用分支名 `feat/user-segment` 跨所有 3 个仓库。你同意吗？
或者你有其他命名约定？
```

### 步骤 3：`--dry-run` 预览

**调用 `bytedance-bits`** 创建研发任务，但带 `--dry-run`。

让 `bytedance-bits` skill 自己处理命令细节，**不要**手工拼命令行。

期望得到的 payload 样例（来自 `bytedance-bits` 返回）：

```json
{
  "name": "用户分层规则自助配置",
  "description": "从 PRD 提炼的描述...",
  "rd_owner": "zhangsan",
  "qa_owner": "lisi",
  "meego_ticket": "DEMAND-12345",
  "target_date": "2026-05-15",
  "changes": [
    {
      "service": "user.segment.api",
      "branch": "feat/user-segment"
    },
    {
      "service": "segment.calculator.service",
      "branch": "feat/user-segment"
    },
    {
      "service": "operation.platform.web",
      "branch": "feat/user-segment"
    }
  ]
}
```

### 步骤 4：HARD-GATE 确认

**强制**展示完整 payload 给用户：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
<HARD-GATE>

即将在 BITS 创建研发任务：

【任务名称】用户分层规则自助配置
【研发负责人】zhangsan@bytedance.com
【QA】lisi@bytedance.com
【Meego 需求单】DEMAND-12345
【计划完成】2026-05-15

【关联仓库（3 个）】
1. user.segment.api         → 分支 feat/user-segment  [★ 核心]
2. segment.calculator.service → 分支 feat/user-segment  [★ 核心]
3. operation.platform.web    → 分支 feat/user-segment  [◇ 受影响]

⚠️ 这是一个写操作，会在 BITS 真实创建任务。

请明确回复：
- ✅ "确认创建" / "go" → 我会去掉 --dry-run 实际创建
- 📝 "改 XX" → 告诉我要改哪里
- ❌ "取消" → 终止
</HARD-GATE>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**严格等用户**明确说"确认创建"或"go"。其他一切回复（"差不多吧"、"可以吧"）都**继续等待**明确确认。

### 步骤 5：实际创建

用户确认后，调用 `bytedance-bits` **去掉 `--dry-run`** 实际创建。

**提取 dev-id**：从返回的 JSON 中提取任务 ID，这是后续所有操作的 key。

### 步骤 6：产出报告

生成初始化报告：

```markdown
# 研发任务初始化完成

**dev-id**: `2143012`
**BITS 链接**: https://bits.bytedance.net/task/2143012
**任务名称**: 用户分层规则自助配置
**创建时间**: 2026-04-19 14:30:22

## 关联仓库
1. ✅ user.segment.api (branch: feat/user-segment)
2. ✅ segment.calculator.service (branch: feat/user-segment)
3. ✅ operation.platform.web (branch: feat/user-segment)

## 下一步
- 进入 `e2e-code-review-loop` 开始代码改造
- Sub-Agent 将并行对 3 个仓库执行任务
- 每个 Sub-Agent 返回状态后，主 Agent 汇总

## 注意事项
- 所有分支都是 feat/user-segment，合入前请 review 跨仓冲突
- 如果某个仓库的分支尚未创建，会在 bind-branch 阶段引导创建
```

---

## 分支不存在的处理

`bytedance-bits` 的 `--change` 要求分支**已经存在**。

处理策略：

### 策略 A：用户已在目标仓库创建分支

**检测方式**：调用 `bytedance-codebase` 查询每个分支是否存在。

```
调 bytedance-codebase 查 user.segment.api 仓库的 feat/user-segment 分支：
- 存在 → 继续
- 不存在 → 引导用户创建
```

### 策略 B：引导用户创建分支

如果分支不存在：

```
❗ 以下 2 个仓库的 feat/user-segment 分支不存在：

1. user.segment.api
2. segment.calculator.service

请先在这些仓库从 main/master 创建分支：
git checkout main
git pull
git checkout -b feat/user-segment
git push origin feat/user-segment

或者让我帮你通过 bytedance-codebase 创建（如果 skill 支持）。

完成后回复"分支已创建"，我继续。
```

### 策略 C：用 bytedance-bits bind-branch

如果分支是后续才绑定，可以先创建空 dev-task，再 bind-branch：

```
# 步骤 1：先创建 dev-task（不带 --change）
bytedcli bits develop create --name "xxx" ...

# 步骤 2：每个仓库分支就绪后，bind-branch
bytedcli bits develop bind-branch --dev-id 2143012 \
  --service user.segment.api --branch feat/user-segment
```

**推荐策略**：优先 A + B（一次性搞定），次选 C（分步灵活）。

---

## 和其他 skill 的协同

### 输入来自

- `e2e-codebase-mapping` —— 涉及仓库清单
- `prd-generation` —— 任务名、计划时间

### 输出给

- `e2e-code-review-loop` —— dev-id 作为上下文
- `e2e-progress-notify` —— 通知研发任务已创建（发飞书）

### 协同调用示例

```
主 Agent 工作流：
1. 调用 e2e-dev-task-setup 创建任务
2. 任务创建成功，拿到 dev-id
3. 自动调用 e2e-progress-notify 发飞书："任务 #2143012 已创建"
4. 进入 e2e-code-review-loop，传入 dev-id
```

---

## 失败处理

### 失败 1：BITS 返回认证错误

- 调用 `bytedance-auth` 重新登录
- 重试创建
- 2 次失败 → `BLOCKED` 给用户

### 失败 2：BITS 返回参数错误

- 解析错误信息
- 对应字段向用户澄清（"QA 邮箱前缀格式不对？"）
- 重试

### 失败 3：BITS 服务超时

- 自动重试 1 次
- 仍超时 → 告知用户并提示检查内网连接
- 建议手动在 BITS 网页上创建，然后告知 Agent dev-id

### 失败 4：Meego 需求单 ID 不存在

- 向用户确认 ID 是否正确
- 可以**跳过**关联（BITS 支持不关联 Meego）
- 建议创建后手动在 BITS 补关联

---

## 反 AI-slop 规范

### 禁用模式

- ❌ 凭空猜测研发负责人、QA（**必须**问用户）
- ❌ 推测 Meego 单 ID（**必须**问用户）
- ❌ 跳过 `--dry-run` 步骤"节省时间"
- ❌ 用户说"差不多"就执行（**必须**等明确确认）
- ❌ 分支名自作主张（要和用户对齐）

### 正确模式

- ✅ 缺字段主动问，结构化问（一次一个维度）
- ✅ 所有字段都展示后再等确认
- ✅ 确认后才 commit，一分钟内 kick off 下一阶段

---

## 参考资料

- `references/openclaw-tools.md` —— OpenClaw 运行时工具映射
- `references/trae-tools.md` —— Trae 运行时工具映射

---

## 自检清单（每步执行前）

- [ ] 是否所有必填字段都已收集？
- [ ] 是否已调用 `--dry-run`？
- [ ] 是否完整展示了 payload？
- [ ] 用户的"确认"是否**明确**（不是"差不多"这种模糊词）？
- [ ] 返回的 dev-id 是否保存？
- [ ] 是否通知了 `e2e-progress-notify` 发飞书？

---

*本 skill 是端到端交付"工程层"的正式起点。所有后续工程化操作都以这里生成的 dev-id 为主 key。*
