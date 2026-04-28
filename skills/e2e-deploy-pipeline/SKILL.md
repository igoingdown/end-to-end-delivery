---
name: e2e-deploy-pipeline
description: "端到端交付的部署流水线 skill，分两个子阶段（BOE 部署 → PPE 发布工单）将代码上线。本 skill 消费 specs/[简称]/verification.md 的 § 3（BOE 集成测试）和 § 4（PPE 验证）的 Acceptance Criteria，执行后**回写**对应章节的 Status / Execution / Results / Issues。本 skill 是最危险的写操作 skill，每个操作都必须 --dry-run + HARD-GATE 用户明确确认，3 个独立 HARD-GATE（BOE 容器部署 / BOE 配置同步 / PPE 工单）不可合并。硬约束：Agent 只触发 CI/CD 和发工单，不直接操作生产环境（实际发布由公司流程驱动）。当 verification.md § 1 § 2 已通过、需要部署到测试/预发/生产环境时必须调用此 skill。典型触发场景：'部署到 BOE'、'上线到 PPE'、'发布到生产'、'deploy'、'发个工单'、'上个灰度'、'推送到测试环境'、'申请发布'。内部依次调用 bytedance-env 查环境配置、bytedance-tce 触发容器部署、bytedance-tcc 同步配置、bytedance-bits create-ticket 创建发布工单。本 skill 的 Owner 章节是 verification.md § 3 和 § 4。"
---

# E2E Deploy Pipeline —— 部署流水线

## 定位

端到端交付主流程的**阶段 7**：代码上线的最后一公里。

**输入**：
- `specs/[简称]/verification.md` § 3（BOE 集成测试）、§ 4（PPE 验证）的 Acceptance Criteria
- `specs/[简称]/plan.md`（部署相关风险、回滚方案参考）
- `e2e-dev-task-setup` 产出的 BITS task ID（关联发布工单）

**输出**：
- **回写** `specs/[简称]/verification.md` § 3 § 4 的 Status / Execution / Results / Issues
- BITS PPE 发布工单（等公司流程审批）

**Owner 章节**：本 skill 只写 § 3 和 § 4，不越权写 § 1 § 2（remote-test 的）、§ 5（human 的）。

**本 skill 是最危险的写操作 skill**。每个操作都会产生**线上副作用**。因此 HARD-GATE 最严格：
- 每个子阶段单独 HARD-GATE（3 个独立 GATE）
- 任何一次用户不明确确认就**立即停止**
- 不存在"连续操作"的快捷路径

---

## 硬约束（不可违反）

1. **不直接操作生产发布**：Agent 只触发 CI/CD 和发工单，实际发布由公司审批流程驱动
2. **每个子阶段独立 HARD-GATE**：不能一次性确认"全部执行"
3. **所有写操作先 `--dry-run`**
4. **禁止 Sub-Agent 派发到本 skill**：部署必须在主 Agent 的直接控制下
5. **回滚方案必须先展示再部署**
6. **回写 verification.md 遵循写入规则**：最终 + 历史摘要，不覆盖历史
7. **不越权写其他章节**（§ 1 § 2 由 remote-test 维护，§ 5 由 human 维护）

---

## 前置条件

进入本 skill 前，必须：

- [x] `verification.md` § 1 § 2 Status 均为 `passed`（不接受"大部分通过"）
- [x] 代码已推送到对应分支（通过 `e2e-code-review-loop` 的 MR 合入）
- [x] `e2e-dev-task-setup` 已创建 BITS task（拿到链接）
- [x] `bytedance-auth` 已登录

---

## 两个子阶段

```
┌──────────────────────────────────────────────┐
│  子阶段 7.1: BOE 部署                         │
│  (测试环境，失败影响小，但仍需 HARD-GATE)     │
│                                              │
│  step A: 环境信息查询 (bytedance-env)        │
│  step B: 容器部署 (bytedance-tce)            │
│  step C: 配置同步 (bytedance-tcc)            │
│       ↓                                      │
│  等待：用户确认 BOE 验证通过                  │
│       ↓                                      │
│  回写 verification.md § 3                    │
└──────────────────────┬───────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────┐
│  子阶段 7.2: PPE 发布工单                     │
│  (生产环境，严重影响，HARD-GATE 最严)         │
│                                              │
│  step A: 构造工单信息                         │
│  step B: 回滚方案确认                         │
│  step C: --dry-run 预览                       │
│  step D: 用户明确确认                         │
│  step E: 实际创建 (bytedance-bits ticket)    │
│       ↓                                      │
│  回写 verification.md § 4                    │
└──────────────────────────────────────────────┘
```

---

## 子阶段 7.1：BOE 部署

### Step A：查询环境配置

**调用 `bytedance-env`**：

```
让 bytedance-env skill 查询目标 BOE 环境的配置：
- 环境名（通常是 boe 或 boe-xxx 泳道）
- 当前版本
- 配置文件位置
- 相关的 TCE 集群信息
```

产出：BOE 环境快照，作为部署决策依据。

### Step B：容器部署（HARD-GATE ①）

**调用 `bytedance-tce`**，带 `--dry-run`：

```
让 bytedance-tce skill 触发部署，目标：
- 服务：[PSM 列表，来自 codebase-mapping]
- 环境：BOE
- 版本：[本次 feature 对应的构建产物版本]
- 泳道：[从环境查询结果获得]
```

展示 dry-run 的 payload：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
<HARD-GATE ①> BOE 容器部署

即将部署到 BOE 环境：

【服务】
- user.segment.api    → 版本 v1.2.3-feat-user-segment
- segment.calculator.service → 版本 v0.5.1-feat-user-segment

【泳道】boe_xxx
【集群】tce-boe-01
【影响实例数】6 个 pod

⚠️ 这是 BOE 部署操作。虽然不影响生产，但可能影响 BOE 联调的其他同学。

请明确回复：
- ✅ "确认部署 BOE" → 实际部署
- 📝 "改 XX"
- ❌ "取消"
</HARD-GATE>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

等用户**明确**说"确认部署 BOE"或"go"后，让 `bytedance-tce` 实际执行。

### Step C：配置同步（HARD-GATE ②）

如果本次改动涉及配置变更（`e2e-codebase-mapping` 已识别），调 `bytedance-tcc`：

```
让 bytedance-tcc skill 同步配置到 BOE：
- 命名空间：[PSM]
- 配置项：[key 列表]
- 目标环境：BOE
```

`--dry-run` 展示 **diff**：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
<HARD-GATE ②> BOE 配置同步

配置变更 diff：

命名空间：user.segment.api

  + segment_rule_config_key = "xxx"
  + segment_cache_ttl = 300
  ~ existing_key: "old_value" → "new_value"

请明确回复："确认同步配置"？
</HARD-GATE>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

配置变更尤其危险（配置立即生效，没有灰度），**确认门槛更高**。

### Step D：BOE 验证等待

部署和配置同步完成后，**主动引导用户去验证**：

```
✅ BOE 部署完成。

请现在去以下 URL 验证功能：
- 运营后台 BOE：https://xxx.boe.bytedance.net/segment

验证通过后，回复 "BOE 验证通过" 我会进入 PPE 阶段。
验证失败？告诉我哪里有问题，我协助回滚或修复。

⚠️ 注意：PPE 发布工单一旦创建，会通知发布审批人，请确保 BOE 充分验证。
```

**主 Agent 在这里停下**，等用户验证。不要自动推进到 PPE。

### Step E：回写 verification.md § 3

用户确认"BOE 验证通过"后，**回写** `specs/[简称]/verification.md § 3. BOE 集成测试`：

```markdown
## § 3. BOE 集成测试
- **Owner**：`e2e-deploy-pipeline`
- **Status**：passed
- **Acceptance Criteria**：
  - 服务在 BOE 环境成功启动
  - E2E 测试脚本全部通过
  - [具体关键验证点...]
- **Execution**：
  - 2026-04-25 14:00 开始部署到 BOE 泳道 boe_xxx
  - 部署版本：v1.2.3-feat-user-segment
  - 3 个服务部署成功 + 配置同步成功
  - 用户于 2026-04-25 17:30 确认 BOE 验证通过
- **Results**：
  **最终**：2026-04-25 17:30 PASSED（用户手工验证通过）
  
  **历史**：
  - 2026-04-25 17:30 PASSED
- **Issues**：
  _(无)_
```

**回写原则**：遵循 verification-template 的"最终 + 历史"策略，不覆盖历史。

---

## 子阶段 7.2：PPE 发布工单

### Step A：构造工单信息

PPE 发布通过 **BITS 工单**（`bytedance-bits create-ticket`），不是直接部署。

工单必填字段：

```
- dev-id：[之前创建的 dev-task ID]
- release_type：PPE
- target_version：[构建产物版本]
- scheduled_time：[发布窗口]
- approver：[审批人邮箱]
- rollback_plan：[回滚方案]
- risk_description：[风险描述]
```

主动问用户收集：

```
PPE 发布工单需要补充几个字段：

1. 发布窗口（什么时候发？如 "明天上午 10 点" / "本周五 22:00"）
2. 审批人（邮箱前缀，通常是 TL）
3. 发布方式：
   - A. 一次性全量（小改动）
   - B. 分批灰度（推荐：1% → 10% → 50% → 100%）
4. 风险等级：低 / 中 / 高

请依次提供。
```

### Step B：回滚方案展示（HARD-GATE ③的前置）

基于 `codebase-mapping` 的"风险点"章节，生成**初始回滚方案**，展示给用户：

```markdown
# 回滚方案草案

## 触发条件
- 错误率 > 2%，持续 5 分钟
- P99 响应时间 > 500ms，持续 10 分钟
- 业务指标异常（订单转化率下降 > 5%）

## 回滚步骤
1. **配置回滚**（最先执行，2 分钟内生效）
   - 通过 bytedance-tcc 将配置切回旧版本
   - 命令：`bytedcli tcc rollback --namespace xxx --to-version N-1`

2. **代码回滚**（5-15 分钟）
   - 通过 bytedance-tce 部署旧版本镜像
   - 命令：`bytedcli tce deploy --psm xxx --version v1.2.2`

3. **数据回滚**（如有 schema 变更）
   - 本次涉及新增 DB 表 `segment_rules`
   - 回滚时保留表（不 drop），清除关联代码即可避免影响

## 责任人
- 一线值班：@zhangsan
- 升级：@leader
- 应急群：segment-p0-war-room
```

**展示**后问用户：

```
以上是回滚方案草案，是否还需要补充或调整？

特别注意：
- 本次有 DB schema 变更（新增表），回滚时的处理方式是否正确？
- 审批人和值班人是否正确？
```

用户确认回滚方案后，才能进入 Step C。

### Step C：工单 `--dry-run` 预览（HARD-GATE ③）

**调用 `bytedance-bits create-ticket`，带 `--dry-run`**：

展示完整工单 payload：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
<HARD-GATE ③> PPE 发布工单（最严级别）

即将创建 PPE 发布工单。这个工单会：
1. 通知审批人（@lilei）
2. 阻塞审批人其他事务（需要 TA 响应）
3. 一旦审批通过，系统会按计划发布到生产

【工单信息】
- 关联 dev-task：2143012
- 标题：用户分层规则自助配置 v1.0
- 目标版本：v1.2.3-feat-user-segment
- 发布窗口：2026-04-22 10:00:00 (UTC+8)
- 审批人：lilei@bytedance.com
- 发布方式：分批灰度（1% → 10% → 50% → 100%）

【涉及服务（2 个）】
- user.segment.api
- segment.calculator.service

【配置变更】
- 是（3 个 config key，见 BOE 同步的 diff）

【回滚方案】
（已经确认过的回滚方案摘要）

【风险等级】中

⚠️ 这是生产发布工单。一旦创建，需要审批人介入，无法轻易撤销。
用户明确确认前，**绝不**执行。

请明确回复：
- ✅ "确认创建工单" / "go" → 实际创建
- 📝 "改 XX" → 说明要改哪里
- ❌ "取消" → 终止
</HARD-GATE>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step E：实际创建 + 回写 verification.md § 4

用户明确确认后，让 `bytedance-bits` 去掉 `--dry-run` 实际创建。

**收集返回的工单 ID**。

**回写** `specs/[简称]/verification.md § 4. PPE 验证`：

```markdown
## § 4. PPE 验证
- **Owner**：`e2e-deploy-pipeline`
- **Status**：running（工单已创建，等公司审批+灰度）
- **Acceptance Criteria**：
  - 灰度：1% → 10% → 50% → 100%
  - 每 Stage 通过：错误率 < 基线 × 1.2, P99 ≤ 基线 × 1.3
  - 回滚条件：错误率 > 2% 持续 5min / P99 > 500ms 持续 10min
- **Execution**：
  - 2026-04-25 20:00 BITS 工单已创建
  - 工单 ID：TICKET-45678
  - 工单链接：https://bits.bytedance.net/ticket/45678
  - 审批人：lilei@bytedance.com
  - 预期发布时间：2026-04-22 10:00
- **Results**：
  **最终**：等审批中
  
  **历史**：
  - 2026-04-25 20:00 工单已创建
- **Issues**：
  _(待实际灰度后填充)_
```

**说明**：本 skill 到此结束。后续灰度进度由用户手动更新 § 4 的 Status / Results（或后续版本的 `post-deploy-monitor` 自动化）。

### Step F：给用户的交付摘要

工单创建和 § 4 回写完成后，给用户展示摘要：

```markdown
# PPE 发布工单创建完成 ✅

**工单 ID**: TICKET-45678
**工单链接**: https://bits.bytedance.net/ticket/45678
**审批人**: @lilei
**预期发布时间**: 2026-04-22 10:00
**verification.md § 4 已回写**

## 后续流程
1. 审批人收到通知，review 工单
2. 审批通过后，系统按计划发布
3. 你需要在发布期间**盯着指标**：
   - 业务：[Dashboard 链接]
   - 稳定性：[APM 链接]
4. 异常时立即触发回滚（回滚方案见工单）
5. 灰度进度手动更新 verification.md § 4 的 Status / Results

## Agent 能做的后续
**本 skill 到这里结束**。Agent 不直接操作生产。

- 发布进度查询：调用 `e2e-progress-notify` 发周期性状态
- 发布后排障：（MVP 不包含，后续 `post-deploy-monitor` 提供）
- 人工 UAT：由 user 填 verification.md § 5
```

---

## 和其他 skill 的协同

### 输入来自

- `e2e-remote-test` —— verification.md § 1 § 2 Status 为 passed（前置条件）
- `e2e-solution-design` —— **verification.md § 3 § 4 的 AC**（执行依据）+ **plan.md § 六 风险**（回滚方案输入）
- `e2e-dev-task-setup` —— BITS task 链接（关联发布工单）

### 输出给

- **回写** verification.md § 3 § 4 —— Status / Execution / Results / Issues
- `e2e-progress-notify` —— 通知 BOE 部署完成、工单创建
- 人工（§ 5 UAT 由 user 在 PPE 灰度期间填写）
- （未来）`post-deploy-monitor` —— 上线后监控

---

## 失败处理

### 失败 1：BOE 部署失败

- 解析 `bytedance-tce` 报错
- 展示错误给用户
- **不自动重试**（生产环境问题需要人工判断）
- 返回 `BLOCKED` 给主 Agent

### 失败 2：配置同步失败

- 配置失败比代码部署更危险（可能导致服务启动失败）
- 立即告警用户
- 建议回滚已部署的容器

### 失败 3：工单创建失败

- 常见原因：审批人账号错、DevOps 必填字段缺失
- 解析 `bytedance-bits` 报错
- 补字段后重试

### 失败 4：用户在 BOE 验证失败

- 询问用户："需要回滚 BOE 并修复，还是继续在 BOE debug？"
- 如果回滚：调 `bytedance-tce` 部署旧版本 + `bytedance-tcc` 恢复配置
- 如果 debug：本 skill 返回 `DONE_WITH_CONCERNS`，主 Agent 回退到 `e2e-code-review-loop`

---

## 反 AI-slop 规范

### 禁用模式

- ❌ 跳过任何一个 HARD-GATE
- ❌ 把 3 个 HARD-GATE 合并成"一次确认"
- ❌ 猜测审批人/发布窗口（必须问用户）
- ❌ 凭印象生成回滚方案（必须基于实际风险点）
- ❌ 发布成功后编造"一切正常"（Agent 根本不知道生产状况）

### 正确模式

- ✅ 每个 HARD-GATE 独立
- ✅ 所有字段明确展示
- ✅ 用户"差不多"/"嗯"都不算确认
- ✅ 失败时如实报告，不隐瞒

---

## 参考资料

- `references/openclaw-tools.md` —— OpenClaw 运行时工具
- `references/trae-tools.md` —— Trae 运行时工具

---

## 自检清单（每个 HARD-GATE 前）

- [ ] 是否调用了 `--dry-run`？
- [ ] 是否完整展示了 payload？
- [ ] 是否说明了影响范围和风险？
- [ ] 是否说明了回滚方式？
- [ ] 用户是否**明确**说"确认"（不是"差不多"、"嗯"）？
- [ ] 每个 HARD-GATE 是否独立（而非合并）？

---

*本 skill 是端到端交付的"收官之战"。**严谨比速度更重要**。任何质疑都要停下来问用户。*
