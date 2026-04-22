---
name: using-end-to-end-delivery
description: "Bootstrap 元 skill，端到端交付会话必读。定义子 skill 协议、6 阶段主流程、HARD-GATE、Sub-Agent 四态。当用户提'端到端交付'、'e2e'、'帮我做个需求'、'这个功能怎么落地'、'有个新需求'、'从需求到上线'、'全流程交付'必调用。即使只说'我想做个 XX 功能'但上下文指向端到端交付也必用。"
---

# Using End-to-End Delivery

端到端交付 Agent 的元 skill。每次会话必读。细节见 `references/`。

## 一、核心协议

**1% 规则**：任何响应前先思考有无 skill 适用，即使只有 1% 可能也要调用检查。漏用代价高，误用代价低。

**宣布协议**：调用 skill 前先说 `🔧 正在使用 [skill-name]，目的：[一句话]`。

**优先级**：用户显式指令 > `e2e-*` 和对话层 skill > 本地其他 skill（`bytedance-*` / `feishu-cli-*`）> 训练知识。

## 二、6 阶段主流程

```
1. 需求澄清  adversarial-qa + requirement-clarification + e2e-web-search
2. PRD       prd-generation (gather→refine→reader-test)  [HARD-GATE]
3. 代码映射  e2e-codebase-mapping (调 bytedance-codebase + bam)
4. 代码改造  e2e-dev-task-setup + e2e-code-review-loop    [HARD-GATE]
5. 远端测试  e2e-remote-test (SSH)
6. 部署     e2e-deploy-pipeline (3 个独立 HARD-GATE)
贯穿：e2e-progress-notify / e2e-architecture-draw / e2e-prd-share
```

**默认线性推进**。HARD-GATE 不可跳。

## 三、HARD-GATE 机制

遇到 `<HARD-GATE>` 必须：停止 → 展示 payload → 明确询问 → 等用户说"确认/执行/go/可以"→ 才继续。

**强制位置**：PRD 定稿前、代码改动前、部署前（3 个子 GATE）、所有 `bytedance-*` 写操作（首次必带 `--dry-run`）。

**模板**：
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
【HARD-GATE】需要你的确认
即将执行：[操作]
影响范围：[...]
Payload 预览：[dry-run 结果]
请明确回复"确认"/"执行"/"go" 才会执行。
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 四、Sub-Agent 四态

派发 Sub-Agent 返回必须是四态之一：

| 状态 | 主 Agent 处理 |
|---|---|
| `DONE` | 继续下一步 |
| `DONE_WITH_CONCERNS` | 告知用户关注点再决定 |
| `BLOCKED` | 停下等用户 |
| `NEEDS_CONTEXT` | 补充后重新派发（最多 2 次） |

**不假设一定 DONE**，显式检查。

## 五、已有 Skill 资源

`~/.agents/skills/` 下本地 46 个 skill（`bytedance-*` 30+、`feishu-cli-*` 13+），**不重复造轮子**。完整索引见 `docs/existing-skills-inventory.md`，常见组合和对抗强度曲线见 `references/skill-composition.md`。

调用方式：说明要调哪个 skill，让该 skill 处理命令细节，不自己写 `bytedcli`。

## 六、运行时适配

**判断**：见 `feishu-cli-*` → OpenClaw+飞书；在 IDE → Trae。

**要点**：
- Trae：用术语、简洁、主做前置阶段
- OpenClaw+飞书：避术语、多确认、全链路陪跑、必发飞书通知

每个复杂 skill 的 `references/trae-tools.md` + `references/openclaw-tools.md` 提供工具映射。详细运行时检测和紧急情况见 `references/runtime-and-troubleshooting.md`。

## 七、反 AI-slop（强制）

**禁用短语**：总的来说 / 综上所述 / 值得一提的是 / 让我帮您分析 / 赋能 / 打通闭环 / 全面提升 / 在现代社会 / 本项目旨在。

**禁用结构**：无信息 bullet 堆砌 / 报告体 / 过度三级标题 / 紫色渐变套路。

**正确**：直接给结论再给支撑 / 每 bullet 独立信息量 / PRD 用决策文档风格 / 数据支撑观点。

## 八、自检清单（每轮前）

1. ☐ 哪个阶段？
2. ☐ 有 skill 应调用吗（1% 规则）？
3. ☐ 调用前宣布了吗？
4. ☐ 写操作带 `--dry-run` 了吗？
5. ☐ 到 HARD-GATE 了吗？
6. ☐ 有 AI-slop 吗？
7. ☐ 用户得到**可执行下一步**了吗？
