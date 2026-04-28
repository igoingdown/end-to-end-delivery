---
name: e2e-code-review-loop
description: "端到端交付的代码改造与 Review 循环 skill，以 specs/[简称]/task.md 为任务源，对其中每个任务条目派发 Sub-Agent 并行执行代码改动。每个 Sub-Agent 按四态协议（DONE/DONE_WITH_CONCERNS/BLOCKED/NEEDS_CONTEXT）返回，**主 Agent 在 Sub-Agent 返回 DONE 后集中回写 task.md 的 checkbox**（Sub-Agent 不直接修改 task.md，避免并发冲突）。当方案设计已完成、BITS task 已创建、需要按 task.md 并行改多仓代码、需要跑 code review 迭代到通过时必须调用此 skill。典型触发场景：'开始改代码'、'并行处理这些仓库'、'code review'、'跑 review 循环'、'按 task.md 执行'、'让 Agent 去写代码'、'派发任务'。本 skill 是循环型 skill（最多 3 轮修复），内部通过 OpenClaw 的 sessions_spawn 派发 Sub-Agent，调用 bytedance-codebase 查 MR/Diff/CI。"
---

# E2E Code Review Loop —— 代码改造与 Review 循环

## 定位

端到端交付主流程的**阶段 5 主体**：把 `task.md` 里的任务**并行**执行成"合入的代码"。

**本 skill 的核心**：

- 以 `task.md` 为**任务源**（不再自己拆解）
- **Sub-Agent 并行派发** + 四态协议 + Review 循环
- **主 Agent 回写 task.md checkbox**（关键：Sub-Agent 不直接改 task.md）

---

## 输入与输出

**输入**：

- `specs/[简称]/task.md`（方案设计阶段产出，任务源）
- `specs/[简称]/plan.md`（Sub-Agent 执行时参考的架构上下文）
- `specs/[简称]/verification.md`（Sub-Agent 执行时参考的验收标准）
- `e2e-dev-task-setup` 产出的 BITS task 链接（作为上下文引用）

**输出**：

- 每个仓库的 MR（Merge Request）链接
- 每个 MR 的 CI/CD 状态
- **更新后的 task.md**：checkbox 状态 + 进度汇总
- 汇总报告（哪些任务 DONE / DONE_WITH_CONCERNS / BLOCKED）

---

## 前置条件

- [x] `specs/[简称]/task.md` 已存在（`e2e-solution-design` 已产出）
- [x] `specs/[简称]/plan.md` 已存在（Sub-Agent 执行上下文）
- [x] `specs/[简称]/verification.md` 已存在（验收标准）
- [x] `e2e-dev-task-setup` 已创建 BITS task（拿到链接）
- [x] 所有涉及仓库的分支已创建（`feat/xxx`）
- [x] `bytedance-auth` 已登录

---

## 核心工作流

```
输入：task.md 中 N 个任务
   │
   ▼
┌────────────────────────────────────────┐
│ 步骤 1：读取 task.md                   │
│ 按任务编号（T1, T2, ...）提取任务       │
│ 构建依赖图（拓扑序）                    │
│ 每任务 = 1 个 Sub-Agent 任务包         │
└──────────────────┬─────────────────────┘
                   │
                   ▼
┌────────────────────────────────────────┐
│ 步骤 2：并行派发 Sub-Agent              │
│ 每个 Sub-Agent 独立 context            │
│ 四态返回协议                            │
└──────────────────┬─────────────────────┘
                   │
                   ▼
┌────────────────────────────────────────┐
│ 步骤 3：收集结果 + 回写 task.md         │
│ 主 Agent 按四态回写 checkbox            │
│ - DONE → [x]                           │
│ - DONE_WITH_CONCERNS / BLOCKED → [ ]   │
└──────────────────┬─────────────────────┘
                   │
                   ▼
┌────────────────────────────────────────┐
│ 步骤 4：Review 循环（最多 3 轮）         │
│ CI 失败 / Reviewer concern → 再派发    │
└──────────────────┬─────────────────────┘
                   │
                   ▼
┌────────────────────────────────────────┐
│ 步骤 5：HARD-GATE（MR 合入前确认）      │
└──────────────────┬─────────────────────┘
                   │
                   ▼
产出：更新后的 task.md + N 个 MR + 汇总报告
```

---

## 步骤详解

### 步骤 1：读取 task.md

**核心原则**：本 skill **不拆任务**（`e2e-solution-design` 已拆好）。

工作流程：

1. 读 `specs/[简称]/task.md`
2. 解析任务列表（T1, T2, ..., Tn）
3. 构建依赖图（基于每任务的 `依赖` 字段）
4. 按拓扑序产出"**派发轮次**"：
   - 第 1 轮：所有无依赖的任务（可并行）
   - 第 2 轮：依赖第 1 轮完成的任务
   - ...

**Sub-Agent 任务包**直接从 task.md 条目转换（**不再自己从 codebase-mapping 推导**）：

```markdown
# Sub-Agent 任务包

## 来源
specs/[简称]/task.md 的 T[N] 条目

## 目标
- PSM：user.segment.api（来自 task.md"仓库/PSM"字段）
- 分支：feat/user-segment
- BITS task：https://bits.bytedance.net/task/XXX（上下文引用）

## 任务详情（从 task.md T[N] 直接复制）
### 标题：[T[N] 的标题]
### 任务描述：[T[N] 的描述]
### 涉及文件：[T[N] 的文件清单]
### 关联 Plan：plan.md § [编号]（本任务依据的设计章节）
### 关联验收：verification.md § [编号]（完成后归属的验证章节）
### 验收标准：[T[N] 的验收条目]

## 执行上下文（Sub-Agent 读取但不修改）
- plan.md 完整内容（解读架构上下文）
- verification.md § [编号]（关联章节的验收标准）

## 返回协议
任务结束时返回四态之一：
- DONE：代码已写完，本地 lint/build 通过，MR 已创建
- DONE_WITH_CONCERNS：完成但有问题（CI 失败、单测挂、需 manual review）
- BLOCKED：遇到阻塞（缺信息、缺权限、技术难题）
- NEEDS_CONTEXT：task.md 条目上下文不足（主 Agent 需补充）

## 重要约束
**Sub-Agent 不允许修改 task.md**。回写 checkbox 由主 Agent 执行。
```

### 步骤 2：并行派发 Sub-Agent

**核心原则**：Sub-Agent **独立 context**，不共享主 Agent 的对话历史。

这样设计的理由：

- 每个 Sub-Agent 聚焦一个任务，context 不被其他任务污染
- 能真正并行执行（同一轮次的无依赖任务同时进行）
- 失败隔离（一个 Sub-Agent 失败不影响其他）

**派发顺序**：按 task.md 的**依赖拓扑排序轮次**：

- 轮次 1：无依赖的任务（如 T1、T2）→ 并行
- 轮次 2：依赖前一轮已完成的任务（如 T3 依赖 T1+T2）→ 并行
- 同一轮次内并行，轮次间串行

**派发时传递**：

- Sub-Agent 任务包（见步骤 1）
- 访问 `bytedance-codebase` 的能力
- 读 plan.md / verification.md 的权限（只读）
- **不传递**：task.md 的写权限、其他 Sub-Agent 的进度、主 Agent 对话历史

**Sub-Agent 内部工作**：

```
Sub-Agent 自己：
1. 读任务包 + plan.md 架构上下文
2. 克隆/读取仓库代码（通过 bytedance-codebase）
3. 理解代码结构
4. 按任务描述实现代码
5. 本地 lint 和单测
6. 创建 MR（通过 bytedance-codebase MR create）
7. 等 CI 结果
8. 按四态返回
9. **不更新 task.md**（主 Agent 处理）
```

### 步骤 3：收集结果 + 主 Agent 回写 task.md

**四态处理矩阵**（**关键**：主 Agent 必须回写 task.md）：

| Sub-Agent 状态 | 主 Agent 动作 | task.md 回写内容 |
|---|---|---|
| `DONE` | 记录 MR 链接，继续下一任务 | `[ ]` → `[x]`，Status 改 `done`，追加 MR 链接 |
| `DONE_WITH_CONCERNS` | 记录 concerns，展示给用户 | 保持 `[ ]`，Status 改 `concerns`，追加 concerns 说明 |
| `BLOCKED` | 立即停下来，告知用户 | 保持 `[ ]`，Status 改 `blocked`，追加阻塞原因 |
| `NEEDS_CONTEXT` | 补充上下文后**重新派发**（最多 2 次） | 保持 `[ ]`，Status 暂改 `needs-context`，重派成功后改回 `pending` |

**task.md 回写原则**：

- **只有主 Agent 能修改 task.md**（Sub-Agent 不触碰）
- 回写**立即**执行（Sub-Agent 返回后，下一个任务派发前）
- 原子写（写临时文件 + rename），避免部分写入
- 每次回写同步更新顶部"进度汇总"表格：

  ```markdown
  ## 进度汇总
  | 状态 | 数量 |
  |---|---|
  | ✅ 已完成 | 3 / 12 |
  | 🔄 进行中 | 2 |
  | ⏸️ 等待依赖 | 5 |
  | 📋 待开始 | 2 |
  ```

**等待策略**：

- 同一轮次的 Sub-Agent 并行执行，**全部完成**后再处理下一轮
- 超时策略：单个 Sub-Agent 超过 30 分钟无响应 → 视为 `BLOCKED`

**汇总展示**：

```markdown
# Sub-Agent 派发结果

| 仓库 | 状态 | MR 链接 | Concerns |
|---|---|---|---|
| user.segment.api | ✅ DONE | [MR-123](url) | 无 |
| segment.calculator.service | ⚠️ DONE_WITH_CONCERNS | [MR-124](url) | 有 1 个单测不稳定 |
| operation.platform.web | ❌ BLOCKED | - | 缺前端组件库 @1.5 版本 |

## 汇总
- 成功：1/3
- 有 concerns：1/3
- 阻塞：1/3

下一步建议：
1. 对 segment.calculator.service 的不稳定单测，是否跑重试？
2. 对 operation.platform.web，需要 @王五 升级组件库版本
```

### 步骤 4：Review 循环

**循环触发条件**：

- 某 Sub-Agent 返回 `DONE_WITH_CONCERNS` 且用户同意修复
- 某 Sub-Agent 返回 `BLOCKED` 后，用户补充信息
- CI 失败后需要修复

**循环实现**：

```
while (loop_count < 3 && 有需要修复的 Sub-Agent):
    1. 构造"修复任务包"（包含原任务 + 失败原因 + 用户补充）
    2. 重新派发 Sub-Agent（可以是同一个也可以新开）
    3. 收集结果
    4. loop_count += 1

if loop_count == 3 && 仍有失败:
    停止循环，返回 BLOCKED 给用户
    建议：人工介入
```

**循环上限**：3 轮。超过说明任务本身有问题，人工介入。

### 步骤 5：HARD-GATE MR 合入

所有 Sub-Agent 都 `DONE` 后，**不要自动合入 MR**。触发 HARD-GATE：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
<HARD-GATE> MR 合入前确认

3 个 MR 已全部 CI 通过，准备合入。

【MR 列表】
1. user.segment.api MR-123
   Diff: +450 / -30 lines
   Reviewer: @zhangsan ✅ approved
   CI: ✅ passed

2. segment.calculator.service MR-124
   Diff: +200 / -10 lines
   Reviewer: @lisi ✅ approved
   CI: ✅ passed

3. operation.platform.web MR-125
   Diff: +120 / -5 lines
   Reviewer: @wangwu ✅ approved
   CI: ✅ passed

⚠️ 一旦合入，代码进入 main/master，触发 CI 构建产物。
合入顺序建议：后端先（1、2），前端最后（3），避免前端短暂打不通。

请明确回复：
- ✅ "确认合入" + "按建议顺序" → 按 1、2、3 顺序合入
- 📝 "按 [自定义顺序] 合入" → 指定顺序
- ❌ "取消" → 暂不合入
</HARD-GATE>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

用户确认后，按顺序合入（通过 `bytedance-codebase`）。

---

## Sub-Agent 派发的关键细节

### 任务包精确度

任务包**必须**精确。Sub-Agent 的 context 有限，不能假设它能理解模糊的要求。

❌ **坏任务包**：

```
在 user.segment.api 仓库实现分层规则管理。
```

✅ **好任务包**：

```
在 user.segment.api 仓库：
1. 新增 handler/segment_rule_handler.go，实现 3 个 HTTP endpoint：
   - POST /api/v1/segment-rules （创建）
   - PUT /api/v1/segment-rules/:id （更新）
   - DELETE /api/v1/segment-rules/:id （删除）
2. 新增 service/segment_service.go 的 ValidateRule 方法
3. 修改 idl/segment.thrift，新增 struct RuleConfig { ... }

参考现有代码风格（见 handler/existing_handler.go）。
所有 endpoint 需要 admin 权限（参考 middleware/auth.go）。
```

### Reviewer 分配

Sub-Agent 创建 MR 时需要指定 Reviewer。**策略**：

- 优先指定 PRD 中提到的"研发负责人"
- 如果没有，调 `bytedance-codebase` 查该仓库的 code-owner
- 如果都不清楚，让用户指定

### CI 失败的处理

Sub-Agent 等 CI 时遇到失败：

1. 尝试解析失败日志
2. 能自动修复的（格式错、import 错）→ 自动修复并重推
3. 不能自动修复的 → 返回 `DONE_WITH_CONCERNS`，附带失败日志
4. **不要自行跑单测**（那是 e2e-remote-test 的事）

### Review 反馈的处理

如果 Reviewer 提 comment：

1. Sub-Agent 收到 comment（通过 `bytedance-codebase` 监听）
2. 如果是"必须改"的意见（blocker）→ 修改代码重推
3. 如果是"建议"的意见（nit）→ 展示给主 Agent，决定是否采纳

---

## 和其他 skill 的协同

### 输入来自

- `e2e-solution-design` —— **task.md**（任务源）+ **plan.md**（架构上下文）+ **verification.md § X**（验收标准）
- `e2e-dev-task-setup` —— BITS task 链接（上下文引用）

### 输出给

- `e2e-remote-test` —— 所有 MR 合入后触发远端测试
- `e2e-progress-notify` —— 进度通知（飞书）
- **回写** `task.md` —— checkbox 状态 + 进度汇总

### 循环关系

```
e2e-code-review-loop → e2e-remote-test (验证 verification § 1 § 2)
       ↑                       │
       │ 失败                    ▼
       └── 回退循环修复 ← 失败回写到 verification.md
```

---

## 失败处理

### 失败 A：Sub-Agent 集体超时

- 可能是网络问题或 Sub-Agent 基础设施故障
- 告知用户，建议检查 OpenClaw 状态
- 降级方案：单 Agent 串行处理

### 失败 B：某个仓库根本没有 Sub-Agent 能改的代码

- 可能是 codebase-mapping 的误判
- 返回 `NEEDS_CONTEXT`，让用户确认改动点

### 失败 C：CI 反复失败

- 超过 3 轮修复仍失败
- 停止循环
- 把所有失败原因汇总给用户，建议人工 debug

### 失败 D：Reviewer 不响应

- 30 分钟内无 Reviewer 响应 → Sub-Agent 返回 `DONE_WITH_CONCERNS`
- 主 Agent 通过 `feishu-cli-msg` 催一下 Reviewer
- 仍不响应 → 建议 @TL

---

## 反 AI-slop 规范

### 禁用模式

- ❌ Sub-Agent 任务包太模糊（"实现分层功能"）
- ❌ 主 Agent 假设 Sub-Agent 都会返回 `DONE`
- ❌ CI 失败被吞掉不报
- ❌ Review 意见被自动 dismiss

### 正确模式

- ✅ 任务包精确到文件、函数、endpoint
- ✅ 显式检查四态，不假设
- ✅ 每次失败都如实展示
- ✅ Review 意见都给用户看，让用户决定采纳

---

## 参考资料

- `references/openclaw-tools.md` —— OpenClaw sessions_spawn 机制
- `references/trae-tools.md` —— Trae 下的 agent 调用

---

## 自检清单（每个阶段）

**派发前**：

- [ ] 任务包是否精确到文件和函数？
- [ ] 每个 Sub-Agent 是否有独立 context？
- [ ] Reviewer 是否明确？

**收集后**：

- [ ] 是否显式检查了每个 Sub-Agent 的返回状态？
- [ ] 是否对 `DONE_WITH_CONCERNS` 展示了具体 concerns？
- [ ] 循环次数是否 ≤ 3？

**合入前**：

- [ ] 是否触发了 HARD-GATE？
- [ ] 用户是否明确确认合入顺序？

---

*本 skill 是端到端交付中最接近"agentic"的部分——利用多 Agent 并行把复杂的多仓改造并行化。但并行不代表自动化，每个关键节点仍需人工确认。*
