# verification.md 模板与 Schema 规范

> `e2e-solution-design` 的验证策略模板。本文件提供：5 章节固定 Schema + 完整示例 + 活文档更新规则。

---

## 核心原则

verification.md 是**活文档**：
- 由 `e2e-solution-design` **初始化**（写 Acceptance Criteria）
- 由 `e2e-remote-test` 填充 § 1、§ 2 的 Execution/Results/Issues
- 由 `e2e-deploy-pipeline` 填充 § 3、§ 4 的 Execution/Results/Issues
- 由人工填充 § 5

**单一 Owner 原则**：每个章节只有一个 Owner skill 能写 Execution/Results/Issues。跨章节不越权。

**写入策略**：**最终结果 + 简短历史摘要**（见下文"写入规则"）。

---

## 中等严格 Schema

5 个章节，顺序固定。每章节字段固定。

### 固定章节列表（不可增减）

| § | 章节名 | Owner |
|---|---|---|
| § 1 | 编译验证 | `e2e-remote-test` |
| § 2 | 单测验证 | `e2e-remote-test` |
| § 3 | BOE 集成测试 | `e2e-deploy-pipeline` |
| § 4 | PPE 验证 | `e2e-deploy-pipeline` |
| § 5 | 人工 UAT | `human` |

**为什么固定 5 章节**：覆盖端到端主流程的全部验证节点。增加章节 = 增加复杂度；减少章节 = 验证不完整。

### 每章节字段（不可增减）

- **Owner**：本 skill 初始化时写死，之后不改
- **Status**：`pending` | `running` | `passed` | `failed`
- **Acceptance Criteria**：本 skill 初始化时写死，定稿后不允许改（改 = 方案变了，应回退到 solution-design）
- **Execution**：Owner skill 填充（何时/何地/何人执行）
- **Results**：Owner skill 填充（见"写入规则"）
- **Issues**：Owner skill 填充（如有）

---

## 写入规则

### Status 流转

```
pending ──start──▶ running ──ok──▶ passed
           │                │
           │                └──err─▶ failed
           └──────────────────▶ failed（跳过执行直接失败，少见）
```

- 只有 Owner skill 能改 Status
- 从 `failed` 回到 `pending`：下次执行重置时可以，记在 Results 历史里
- 不允许从 `passed` 回到其他状态（如果已通过又要重测，是新一轮执行，Results 追加历史）

### Results 写入策略（方案 C：最终结果 + 简短历史摘要）

```markdown
**Results**:
**最终**：2026-04-22 14:30 PASSED（3 次重试后成功）

**历史**：
- 2026-04-22 12:00 FAILED：3 个用例挂（详见 Issues）
- 2026-04-22 13:15 FAILED：1 个用例挂（fix：T6 性能问题）
- 2026-04-22 14:30 PASSED
```

**规则**：
- **最终**：只有 1 条，反映当前真实状态
- **历史**：append-only，不删除，时间倒序（最近的在上）
- 每条历史一行（时间 + 结果 + 一句话关键信息）

### Issues 写入策略

```markdown
**Issues**:
- [OPEN] 2026-04-22 12:00 单测 TestRuleValidate 间歇性 FAIL，疑似时序问题
- [RESOLVED] 2026-04-22 13:15 批量计算超时，原因：for 循环嵌套，fix 方案：改用 pipeline
```

- `[OPEN]` / `[RESOLVED]` 前缀明示状态
- 已解决的 issue **不删除**（保留审计痕迹）

---

## 完整模板

```markdown
# 验证策略 · [需求名称]

> **状态**：初始化 / 进行中 / 全部通过
> **来源 Plan**：./plan.md
> **关联任务**：./task.md
> **最后更新**：[日期]

---

## 概览

| § | 章节 | Status | Owner |
|---|---|---|---|
| 1 | 编译验证 | pending | e2e-remote-test |
| 2 | 单测验证 | pending | e2e-remote-test |
| 3 | BOE 集成测试 | pending | e2e-deploy-pipeline |
| 4 | PPE 验证 | pending | e2e-deploy-pipeline |
| 5 | 人工 UAT | pending | human |

通过条件：§ 1-4 全部 passed，§ 5 至少 1 个验收人确认 passed。

---

## § 1. 编译验证

- **Owner**：`e2e-remote-test`
- **Status**：pending
- **Acceptance Criteria**：
  - 所有涉及仓库 `go build ./...` 返回 exit code 0
  - 无 lint 错误（`golangci-lint run`）
  - 无循环依赖（`go mod tidy` 后文件无变化）
- **Execution**：_(e2e-remote-test 填充)_
- **Results**：_(e2e-remote-test 填充)_
- **Issues**：_(如有)_

---

## § 2. 单测验证

- **Owner**：`e2e-remote-test`
- **Status**：pending
- **Acceptance Criteria**：
  - [列出本次涉及的关键单测要求]
  - 整体覆盖率 ≥ 80%
  - 关键模块（如 RuleValidator）覆盖率 ≥ 90%
  - 所有单测 `go test ./...` 通过
  - 关键用例：
    - [ ] TestCreateRule 全路径
    - [ ] TestRuleValidate 5 个合法 + 5 个非法表达式
    - [ ] TestBatchCalculator 性能（10K 用户 ≤ 6s）
- **Execution**：_(e2e-remote-test 填充)_
- **Results**：_(e2e-remote-test 填充)_
- **Issues**：_(如有)_

---

## § 3. BOE 集成测试

- **Owner**：`e2e-deploy-pipeline`
- **Status**：pending
- **Acceptance Criteria**：
  - 服务在 BOE 环境成功启动（健康检查通过）
  - E2E 测试脚本在 BOE 执行全部通过
  - 关键验证点：
    - [ ] 运营能通过 UI 创建规则
    - [ ] BMQ 消息能正确流转
    - [ ] 分层计算在 BOE 数据集上正确
    - [ ] 查询 API 返回正确分层
  - 无 5xx 错误（观测期 30 分钟）
- **Execution**：_(e2e-deploy-pipeline 填充)_
- **Results**：_(e2e-deploy-pipeline 填充)_
- **Issues**：_(如有)_

---

## § 4. PPE 验证

- **Owner**：`e2e-deploy-pipeline`
- **Status**：pending
- **Acceptance Criteria**：
  - **灰度策略**：
    - Stage 1：1% → 观测 24 小时 → 无异常 → Stage 2
    - Stage 2：10% → 观测 48 小时 → 无异常 → Stage 3
    - Stage 3：50% → 观测 48 小时 → 无异常 → Stage 4
    - Stage 4：100% 全量
  - **每 Stage 的通过条件**：
    - 错误率 < 基线 × 1.2
    - P99 响应时间 ≤ 基线 × 1.3
    - 核心业务指标（分层错误率）≤ 1%
  - **回滚条件**（任一触发立即回滚）：
    - 错误率 > 2%，持续 5 分钟
    - P99 > 500ms，持续 10 分钟
    - 业务指标异常（分层错误率 > 3%）
- **Execution**：_(e2e-deploy-pipeline 填充)_
- **Results**：_(e2e-deploy-pipeline 填充)_
- **Issues**：_(如有)_

---

## § 5. 人工 UAT

- **Owner**：`human`
- **Status**：pending
- **Acceptance Criteria**：
  - **验收人**：[运营 Leader 邮箱]，[QA Leader 邮箱]
  - **验收清单**：
    - [ ] 运营能在 UI 完整走完"新建规则 → 查看影响用户数 → 保存生效"流程
    - [ ] 非法表达式的错误提示能让运营看懂（不用找 RD 翻译）
    - [ ] 规则保存后 5 分钟内生效（用户侧可见）
    - [ ] 运营配置时长 ≤ 15 分钟（对比基线 4 小时）
  - **验收时间**：PPE Stage 2（10%）期间完成
- **Execution**：_(由人填充：谁在什么时间验收)_
- **Results**：_(由人填充：通过/不通过 + 简短说明)_
- **Issues**：_(如有)_
```

---

## 完整示例（需求执行中）

以下展示**执行中**的 verification.md 状态（部分已填充）：

```markdown
# 验证策略 · 用户分层规则自助配置

> **状态**：进行中
> **来源 Plan**：./plan.md
> **关联任务**：./task.md
> **最后更新**：2026-04-25 16:00

---

## 概览

| § | 章节 | Status | Owner |
|---|---|---|---|
| 1 | 编译验证 | ✅ passed | e2e-remote-test |
| 2 | 单测验证 | ✅ passed | e2e-remote-test |
| 3 | BOE 集成测试 | 🔄 running | e2e-deploy-pipeline |
| 4 | PPE 验证 | ⏸️ pending | e2e-deploy-pipeline |
| 5 | 人工 UAT | ⏸️ pending | human |

---

## § 1. 编译验证

- **Owner**：`e2e-remote-test`
- **Status**：passed
- **Acceptance Criteria**：
  - 所有涉及仓库 go build ./... 返回 exit code 0
  - 无 lint 错误
  - 无循环依赖
- **Execution**：
  - 2026-04-24 10:00 在 dev01 (tiger@dev01.bytedance.net) 执行
  - 仓库：user.segment.api, segment.calculator.service, operation-platform-web
- **Results**：
  **最终**：2026-04-24 10:15 PASSED
  
  **历史**：
  - 2026-04-24 10:15 PASSED（3 仓库全部通过）
  - 2026-04-24 09:45 FAILED（user.segment.api 的 rpn_parser.go 缺少 import）
- **Issues**：
  - [RESOLVED] 2026-04-24 09:45 user.segment.api 缺 import "fmt"，T2 补上

---

## § 2. 单测验证

- **Owner**：`e2e-remote-test`
- **Status**：passed
- **Acceptance Criteria**：
  - 整体覆盖率 ≥ 80%
  - 关键模块 RuleValidator 覆盖率 ≥ 90%
  - 关键用例：
    - [x] TestCreateRule 全路径
    - [x] TestRuleValidate 5 个合法 + 5 个非法
    - [x] TestBatchCalculator 性能（10K 用户 ≤ 6s）
- **Execution**：
  - 2026-04-24 15:00 在 dev01 执行
  - 耗时：全部单测 8 分 32 秒
- **Results**：
  **最终**：2026-04-24 16:45 PASSED（2 次重试后成功）
  
  覆盖率：
  - user.segment.api: 87%
  - segment.calculator.service: 83%
  - RuleValidator 模块: 94%
  
  性能：
  - TestBatchCalculator 10K 用户：5.2 秒（目标 ≤ 6s）✅
  
  **历史**：
  - 2026-04-24 16:45 PASSED
  - 2026-04-24 16:00 FAILED：TestBatchCalculator 7.8s 超时
  - 2026-04-24 15:15 FAILED：TestRuleValidate 2 个非法表达式未被正确拒绝
- **Issues**：
  - [RESOLVED] 2026-04-24 15:15 RuleValidator 漏检 `user.age > >=`，T2 修复正则
  - [RESOLVED] 2026-04-24 16:00 BatchCalculator 循环嵌套导致超时，T6 改用 pipeline

---

## § 3. BOE 集成测试

- **Owner**：`e2e-deploy-pipeline`
- **Status**：running
- **Acceptance Criteria**：
  - 服务在 BOE 环境启动
  - E2E 脚本全部通过
  - 关键验证点：
    - [x] 运营能通过 UI 创建规则
    - [x] BMQ 消息流转正确
    - [ ] 分层计算在 BOE 数据集正确（进行中）
    - [ ] 查询 API 返回正确分层
  - 无 5xx 错误（观测期 30 分钟）
- **Execution**：
  - 2026-04-25 14:00 开始部署到 BOE 泳道 boe_user_segment
  - 部署版本：v1.2.3-feat-user-segment
  - 3 个服务：user.segment.api, segment.calculator.service, operation-platform-web
- **Results**：
  _(进行中，更新时追加)_
- **Issues**：
  _(暂无)_

---

## § 4. PPE 验证

- **Owner**：`e2e-deploy-pipeline`
- **Status**：pending
- **Acceptance Criteria**：
  - **灰度**：1% → 10% → 50% → 100%，每 Stage 24-48 小时
  - **通过**：错误率 < 基线 × 1.2, P99 ≤ 基线 × 1.3
  - **回滚**：错误率 > 2% 持续 5min / P99 > 500ms 持续 10min
- **Execution**：_(待 § 3 通过后触发)_
- **Results**：_(待填)_
- **Issues**：_(待填)_

---

## § 5. 人工 UAT

- **Owner**：`human`
- **Status**：pending
- **Acceptance Criteria**：
  - **验收人**：lilei@bytedance.com, wangwu@bytedance.com
  - **验收清单**：
    - [ ] 运营能在 UI 完整走完"新建规则 → 查看影响用户数 → 保存生效"流程
    - [ ] 非法表达式错误提示能让运营看懂
    - [ ] 规则保存后 5 分钟内生效
    - [ ] 运营配置时长 ≤ 15 分钟
  - **验收时间**：PPE Stage 2（10%）期间
- **Execution**：_(待)_
- **Results**：_(待)_
- **Issues**：_(待)_
```

---

## 常见问题

### Q1：Acceptance Criteria 定稿后能改吗？

**不能**（原则上）。

改 AC = 方案变了。应该：
1. 回到 `e2e-solution-design` 修改 plan.md
2. 重新触发 HARD-GATE
3. 同步更新 verification.md 的 AC

**特例**：如果只是 AC 字段描述模糊（不涉及实质变化），可以小改。改动需在本文件顶部的"最后更新"标注原因。

### Q2：如果某个章节不适用怎么办？

**标记为 `skipped`**（不是 `passed`）：

```markdown
- **Status**：skipped
- **Execution**：
  - 2026-04-25 人工评估：本次需求无配置变更，无需 § 3 的 TCC 配置同步验证
```

**谁能 skip**：
- Owner skill 判断不适用 → skip（比如纯前端改动，§ 1 的 `go build` 不相关）
- skip 需在 Execution 写明理由

### Q3：并发写入冲突怎么办？

**不会发生**。每章节只有 1 个 Owner skill，主 Agent 串行调度（不会两个 skill 同时写同一章节）。

### Q4：verification.md 和 CODEBASE-MAPPING.md 的"风险"章节重复吗？

**不重复**：
- CODEBASE-MAPPING.md 的风险：**改动层面**（兼容性、性能热点、团队依赖）
- plan.md 的风险：**方案层面**（技术选型失败、架构缺陷）
- verification.md 的 Issues：**执行层面**（测试挂了、编译错了）

三者递进：方案风险 → 改动风险 → 执行 issue。

---

## 初始化 Checklist（solution-design 产出前必过）

- [ ] 所有 5 个章节都存在（1-5 完整）
- [ ] 每章节的 Owner 都填了，且和固定 Schema 一致
- [ ] 每章节的 Acceptance Criteria 都**具体可测**（有数字、有清单）
- [ ] § 2 的"关键用例"列表和 task.md 中的单测任务对应
- [ ] § 3 的"关键验证点"涵盖 plan.md 的核心场景
- [ ] § 4 的灰度策略**明确 Stage 数量 + 时长 + 回滚条件**
- [ ] § 5 的验收人有**具体邮箱**

---

*本模板基于 BMAD QA gate YAML + Kiro testing strategy 综合，适配端到端交付的多节点验证特性。*
