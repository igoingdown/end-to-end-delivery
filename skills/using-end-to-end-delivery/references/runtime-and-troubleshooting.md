# 运行时检测 & 紧急情况处理

> 主 SKILL.md 的补充细节。当主 Agent 遇到特殊情况时查阅。

---

## 一、运行时详细检测

### 1.1 判断当前运行时

- 见到飞书相关 skill（`feishu-cli-*`）可用 → 大概率是 **OpenClaw + 飞书话题**
- 在 IDE 上下文（能看到代码树、能编辑文件）→ 是 **Trae IDE**
- 检查环境变量或上下文线索辅助判断

### 1.2 适配策略

| 维度 | Trae IDE | OpenClaw + 飞书 |
|---|---|---|
| 主要用户 | 研发同学 | 非研发同学为主 |
| 沟通风格 | 可用术语、简洁 | 避免术语、多确认 |
| 主要场景 | 前置阶段（需求/PRD/代码分析） | 全链路陪跑 |
| 飞书通知 | 可选 | 必做（用 `feishu-cli-msg` 通知关键节点） |
| 画图 | 用 Markdown mermaid | 用 `feishu-cli-board`（视觉友好） |
| Sub-Agent | Trae 子 agent 机制（可能降级串行） | OpenClaw `sessions_spawn` 原生 |

### 1.3 Skill 跨运行时映射

每个复杂 skill 的 `references/` 下有：
- `references/trae-tools.md` —— Trae 下的工具名和调用方式
- `references/openclaw-tools.md` —— OpenClaw 下的工具名和调用方式

阅读当前运行时对应的文件来调用底层能力。

---

## 二、紧急情况处理

### 2.1 用户明显不满

用户不耐烦、挫败、或说"别再问了直接做"时：

- **不要屈服**于对 HARD-GATE 的让步 —— 安全规则保护的是用户
- **可以**调整对话节奏：一次性问多个问题而不是一个一个问
- **可以**跳过非必要的澄清，直奔核心
- **必须**保留所有写操作的 `--dry-run` 和用户明确确认

### 2.2 Skill 调用失败

Skill 执行报错时按顺序排查：

1. **认证问题**（`Not authenticated`）→ 调 `bytedance-auth login` 或 `feishu-cli-auth login`
2. **参数错误** → 读对应 skill 的 `references/troubleshooting.md`
3. **网络问题** → 询问用户是否在内网（字节内网 / VPN）
4. **仍不能解决** → `BLOCKED` 状态返回，告知用户具体原因和已排查步骤

### 2.3 跨 session 延续

OpenClaw 下每个飞书话题是独立 session。用户说"继续上周那个需求"时：

- 主动搜话题历史（`feishu-cli-search`）
- 调用 `bytedance-cloud-docs` 找相关方案/PRD
- 调用 `bytedance-bits` 按关键词找研发任务
- **不要**凭空假设上下文

### 2.4 用户切换运行时

用户在 Trae 完成前置阶段（需求/PRD/代码分析），切到飞书继续做部署：

- 在 Trae 完成时把产出物（PRD.md、CODEBASE-MAPPING.md）git commit
- 告知用户把文件发到飞书话题
- 在飞书话题调 `e2e-prd-share` 或直接读取产出物继续
