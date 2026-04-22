---
name: using-end-to-end-delivery
description: "Bootstrap 元 skill，端到端交付会话必读。定义子 skill 协议、7 阶段主流程（需求澄清→PRD→现状→方案→代码→测试→部署）、HARD-GATE、Sub-Agent 四态。当用户提'端到端交付'、'e2e'、'帮我做个需求'、'这个功能怎么落地'、'有个新需求'、'从需求到上线'、'全流程交付'必调用。即使只说'我想做个 XX 功能'但上下文指向端到端交付也必用。"
---

# Using End-to-End Delivery

端到端交付 Agent 元 skill。每次会话必读。细节见 `references/`。

## 一、核心协议

**1% 规则**：响应前先思考有无 skill 适用，1% 可能也要调用检查。

**宣布协议**：调用 skill 前先说 `🔧 正在使用 [skill-name]，目的：[一句话]`。

**优先级**：用户显式指令 > `e2e-*` 和对话层 skill > 本地其他 skill > 训练知识。

## 二、7 阶段主流程

```
1. 需求澄清   adversarial-qa + requirement-clarification + e2e-web-search
2. PRD       prd-generation → PRD.md                       [HARD-GATE]
3. 现状理解   项目类型判断（见三）
4. 方案设计   e2e-solution-design
             → specs/[简称]/ 下 plan.md + task.md + verification.md
                                                           [HARD-GATE ×3]
5. 代码改造   e2e-dev-task-setup (1 BITS task)
             + e2e-code-review-loop (Sub-Agent 按 task.md 派发)
                                                           [HARD-GATE]
6. 远端测试   e2e-remote-test → 填 verification.md § 1 § 2
7. 部署      e2e-deploy-pipeline → 填 § 3 § 4
                                           [HARD-GATE ×3: BOE/配置/PPE]

贯穿：e2e-progress-notify / e2e-architecture-draw / e2e-prd-share
```

**默认线性推进**。HARD-GATE 不可跳。

## 三、项目类型识别（阶段 3）

- **明显存量**（PRD 提"给 X 加功能"）→ 自动进 `e2e-codebase-mapping`
- **明显新项目**（"新做一个 X"）→ 调 `e2e-web-search` + `bytedance-cloud-docs` 轻量调研；空则问用户
- **模糊** → HARD-GATE 询问用户

两分支都产出"现状素材"供阶段 4。

## 四、HARD-GATE 机制

遇到 `<HARD-GATE>`：停止 → 展示 payload → 询问 → 等用户"确认/go/可以"→ 才继续。

**位置**：PRD 定稿 / 项目类型模糊询问 / plan 定稿 / task 定稿 / verification 定稿 / 代码合入前 / 部署 3 子 GATE / 所有 `bytedance-*` 写操作首次 `--dry-run`。

## 五、三活文档约束

- `plan.md` / `task.md` / `verification.md` 由 `e2e-solution-design` 一次性初始化
- **单一创建原则**：其他 skill 只**消费**或**更新已有字段**
- `task.md` checkbox 由 `e2e-code-review-loop` **主 Agent** 回写（非 Sub-Agent）
- `verification.md` 章节 Owner 固定：§1/§2 = remote-test，§3/§4 = deploy-pipeline，§5 = human

## 六、Sub-Agent 四态

| 状态 | 主 Agent 处理 |
|---|---|
| `DONE` | 继续 |
| `DONE_WITH_CONCERNS` | 告知用户再决定 |
| `BLOCKED` | 停下等用户 |
| `NEEDS_CONTEXT` | 补充后重派（≤ 2 次） |

**不假设一定 DONE**，显式检查。

## 七、已有 Skill 资源

`~/.agents/skills/` 下本地 46 个（`bytedance-*` 30+、`feishu-cli-*` 13+），**不重复造轮子**。索引见 `docs/existing-skills-inventory.md`，组合和对抗强度见 `references/skill-composition.md`。

调用：说要调哪个 skill，让该 skill 处理命令细节，不拼 `bytedcli`。

## 八、运行时适配

见 `feishu-cli-*` → OpenClaw+飞书；在 IDE → Trae。

- Trae：术语 OK、简洁、前置阶段+方案设计
- OpenClaw+飞书：避术语、多确认、全链路、发飞书通知

每 skill 的 `references/trae-tools.md` + `openclaw-tools.md` 有工具映射。详见 `references/runtime-and-troubleshooting.md`。

## 九、反 AI-slop

**禁用**：总的来说/综上所述/值得一提/让我帮您分析/赋能/打通闭环/全面提升/本项目旨在。

**禁用结构**：无信息 bullet / 报告体 / 过度三级标题。

**正确**：直接结论+支撑 / bullet 独立信息量 / 决策文档风格 / 数据支撑。

## 十、自检（每轮前）

1. ☐ 哪个阶段？
2. ☐ 有 skill 应调用（1% 规则）？
3. ☐ 调用前宣布了？
4. ☐ 写操作 `--dry-run`？
5. ☐ 到 HARD-GATE？
6. ☐ 三活文档遵守"单一创建"？
7. ☐ 用户得到**可执行下一步**？
