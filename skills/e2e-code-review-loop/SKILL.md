---
name: e2e-code-review-loop
description: "端到端交付的代码改造与 Review 循环 skill，对多个涉及仓库并行派发 Sub-Agent 执行代码改动，每个 Sub-Agent 按四态协议（DONE/DONE_WITH_CONCERNS/BLOCKED/NEEDS_CONTEXT）返回，主 Agent 汇总结果并在必要时循环修复。当研发任务已创建、需要并行改多个仓库代码、需要跑 code review 迭代到通过时必须调用此 skill。典型触发场景：'开始改代码'、'并行处理这些仓库'、'code review'、'跑 review 循环'、'这些改动分别在各仓库实现'、'让 Agent 去写代码'。本 skill 是循环型 skill（最多 3 轮修复），内部通过 OpenClaw 的 sessions_spawn 派发 Sub-Agent，调用 bytedance-codebase 查 MR/Diff/CI，bytedance-bits 更新研发任务状态。"
---

# E2E Code Review Loop —— 代码改造与 Review 循环

## 定位

端到端交付主流程的**阶段 4b**：把"改动点清单"变成"合入的代码"。

**本 skill 的核心**：通过 **Sub-Agent 并行派发** + **Review 循环**完成多仓代码改造。

---

## 输入与输出

**输入**：
- `e2e-codebase-mapping` 的改动点清单（含每仓改动文件、原因）
- `e2e-dev-task-setup` 的 dev-id
- PRD 的功能要求

**输出**：
- 每个仓库的 MR（Merge Request）链接
- 每个 MR 的 CI/CD 状态
- 汇总报告（哪些成功、哪些有 concerns、哪些 blocked）

---

## 前置条件

- [x] `e2e-dev-task-setup` 已完成（拿到 dev-id）
- [x] `e2e-codebase-mapping` 有完整的改动点清单
- [x] 所有涉及仓库的分支已创建（`feat/xxx`）
- [x] `bytedance-auth` 已登录

---

## 核心工作流

```
输入：改动点清单 + dev-id
   │
   ▼
┌────────────────────────────────────────┐
│ 步骤 1：任务拆解                         │
│ 每个涉及仓库 = 1 个 Sub-Agent 任务      │
│ 任务粒度以"改动级别"为准：              │
│ - ★ 核心改动 → 必须派发                 │
│ - ◇ 受影响 → 默认不派发（可选）         │
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
│ 步骤 3：收集结果                         │
│ 按四态分类处理                          │
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
产出：汇总报告 + MR 链接
```

---

## 步骤详解

### 步骤 1：任务拆解

从 `e2e-codebase-mapping` 的产出表格，按仓库拆分 Sub-Agent 任务。

每个 Sub-Agent 任务包要包含：

```markdown
# Sub-Agent 任务包

## 任务 ID
TASK-[repo-name]-001

## 目标仓库
- 仓库：user.segment.api
- PSM：user.segment.api
- 分支：feat/user-segment
- dev-id：2143012（主 Agent 关联用）

## 改动要求
### 需要新增的文件
- `handler/segment_rule_handler.go` - 规则 CRUD Handler

### 需要修改的文件
- `service/segment_service.go` - 新增规则校验逻辑
- `idl/segment.thrift` - 新增 RuleConfig 结构

## 业务上下文（从 PRD 提炼）
[PRD 相关章节的片段]

## 验收标准
- [ ] 所有 Must 功能点实现
- [ ] 单元测试覆盖主流程
- [ ] 本地 lint 通过
- [ ] 不引入新的依赖（除非必要）

## 返回协议
任务结束时返回四态之一：
- DONE：完成，PR 已创建，CI 通过
- DONE_WITH_CONCERNS：完成但有问题（单测失败、需要 manual review）
- BLOCKED：遇到阻塞（缺信息、缺权限、技术难题）
- NEEDS_CONTEXT：需要主 Agent 补充信息
```

### 步骤 2：并行派发 Sub-Agent

**核心原则**：Sub-Agent **独立 context**，不共享主 Agent 的对话历史。

这样设计的理由：
- 每个 Sub-Agent 聚焦一个仓库，context 不被其他仓库污染
- 能真正并行执行（3 个仓库改动同时进行）
- 失败隔离（一个 Sub-Agent 失败不影响其他）

**派发时传递**：
- 上面的"任务包"
- 访问 `bytedance-codebase` 和 `bytedance-bits` 的能力
- 不传递：PRD 全文、对话历史（过度膨胀 context）

**Sub-Agent 内部工作**：

```
Sub-Agent 自己：
1. 读任务包
2. 克隆/读取仓库代码（通过 bytedance-codebase）
3. 理解代码结构
4. 按"改动要求"实现代码
5. 本地 lint 和单测
6. 创建 MR（通过 bytedance-codebase MR create）
7. 等 CI 结果
8. 按四态返回
```

### 步骤 3：收集结果

**四态处理矩阵**：

| Sub-Agent 状态 | 主 Agent 动作 |
|---|---|
| `DONE` | 记录 MR 链接，继续其他 Sub-Agent |
| `DONE_WITH_CONCERNS` | 记录 concerns，展示给用户，决定下一步 |
| `BLOCKED` | 立即停下来，告知用户具体阻塞 |
| `NEEDS_CONTEXT` | 补充上下文后**重新派发**（最多 2 次） |

**等待策略**：
- 所有 Sub-Agent 并行执行，**全部完成**后再处理
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

- `e2e-codebase-mapping` —— 改动点清单（决定 Sub-Agent 任务粒度）
- `e2e-dev-task-setup` —— dev-id（关联任务）
- `prd-generation` —— PRD 业务上下文

### 输出给

- `e2e-remote-test` —— MR 合入后触发远端测试
- `e2e-progress-notify` —— 进度通知（飞书）

### 循环关系

```
e2e-code-review-loop → e2e-remote-test (验证)
       ↑                       │
       │ 失败                    ▼
       └── 回退循环修复 ← 失败报告
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
