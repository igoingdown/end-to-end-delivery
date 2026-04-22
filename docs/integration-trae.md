# Trae IDE 集成指引

> 本文档说明如何在 Trae IDE 下部署和运行"端到端交付" Agent。
> Trae 是字节内部的 AI IDE，本指引基于 Agent Skills 开放标准。
> 具体 Trae 版本的 API 可能有差异，以 Trae 最新文档为准。

---

## 前置条件

- Trae IDE 已安装（支持 Agent Skills 的版本）
- Trae 已配置你偏好的模型（千问 3.6 Plus 首选）
- 本地 `~/.agents/skills/` 已通过 `install.sh` 安装本项目 13 个 skill
- （如果需要调用 `bytedance-*` skill）字节 SSO 已登录

---

## 一、Trae 与 OpenClaw 的核心差异

| 维度 | Trae IDE | OpenClaw |
|---|---|---|
| **定位** | AI IDE（代码编辑为主） | Agent Gateway（消息通道为主） |
| **主要用户** | 研发同学 | 非研发 + 研发 |
| **对话位置** | IDE 内对话面板 | 飞书话题 |
| **文件访问** | 直接访问 IDE workspace | 通过 `/workspace` |
| **Skill 加载** | 通过 MCP 或 Trae skill 加载机制 | `skills.load.extraDirs` |
| **Sub-Agent** | Trae 的子 agent 机制 | `sessions_spawn` |

---

## 二、安装步骤

### Step 1：运行 `install.sh`（如果还没跑）

```bash
cd ~/github/end-to-end-delivery
./install.sh
```

安装完后：
- `~/.agents/skills/` 下有本项目 13 个 skill
- 所有 `scripts/*.sh` 已经有执行权限

### Step 2：在 Trae 里挂载 `~/.agents/skills/`

**Trae 支持 Agent Skills 标准**，但具体加载路径由 Trae 设置决定。

**方式 A：Trae 设置里添加 Skill 目录**

（具体 UI 路径以 Trae 版本为准，下面是示意）

1. 打开 Trae 设置 → Skills / Agent 设置
2. 找到 "Skill 搜索路径" 或类似选项
3. 添加：`~/.agents/skills`
4. 保存并重启 Trae

**方式 B：通过 MCP 挂载**

Trae 支持 MCP（Model Context Protocol）。如果本地 `~/.agents/skills/` 通过 MCP server 暴露，Trae 可以自动发现。

具体 MCP server 配置参考 Trae 的 MCP 文档。

**方式 C：用软链接挂到 Trae 预期路径**

如果 Trae 期望 skill 在某个固定路径（比如 `~/.trae/skills/`），用软链接：

```bash
mkdir -p ~/.trae
ln -sf ~/.agents/skills ~/.trae/skills
```

### Step 3：加载 AGENTS.md

Trae 通常会加载项目根目录的 `AGENTS.md`。有两种方式：

**方式 A：在具体项目目录用软链接**

```bash
cd ~/github/my-current-project
ln -sf ~/github/end-to-end-delivery/AGENTS.md AGENTS.md
```

这样在这个项目里打开 Trae 就会加载本项目的 AGENTS.md。

**方式 B：Trae 的全局 Custom Agent**

Trae 支持创建 Custom Agent（类似你在 Trae 里之前那个"端到端交付" Agent）。

1. Trae 设置 → Custom Agents → 新建
2. 名称："端到端交付"
3. 主 Prompt：粘贴 `AGENTS.md` 的内容（或通过 Trae 的"导入 AGENTS.md"功能）
4. "何时调用"：从 `using-end-to-end-delivery/SKILL.md` 的 description 复制
5. 保存

---

## 三、Trae 下的典型使用场景

### 场景 1：研发同学做前置需求澄清

```
研发在 Trae 里：
1. 打开某个项目
2. Trae 对话栏 @端到端交付
3. "我们 team 想做个 XX 功能，帮我梳理一下"
4. Agent 触发 adversarial-qa / requirement-clarification
5. 对话完后 Agent 触发 prd-generation
6. PRD Markdown 直接保存到项目 docs/ 目录
```

**和飞书场景的区别**：
- 不需要发飞书通知（研发自己在用）
- PRD 直接在 IDE 里打开编辑

### 场景 2：研发同学基于已有 PRD 做代码分析

```
研发在 Trae 里：
1. Trae 打开项目，PRD 文件在 docs/PRD-xxx.md
2. 对话："帮我分析这个 PRD 涉及哪些代码"
3. Agent 触发 e2e-codebase-mapping
4. Agent 用 IDE 内置的 view 工具读本地代码（比 bytedance-codebase 远程调用快）
5. 产出 CODEBASE-MAPPING-xxx.md 到项目 docs/
```

**Trae 特有优势**：直接读本地代码，不用走远端 API。

### 场景 3：研发同学在 IDE 内跑远端测试

```
研发在 Trae 里：
1. 代码改完
2. 对话："帮我在开发机跑一下单测"
3. Agent 触发 e2e-remote-test
4. 执行 run-remote-test.sh
5. 实时输出在 IDE 内置 terminal 里显示
```

**Trae 特有优势**：terminal 集成，日志实时可见。

---

## 四、Trae 下建议不做的事

虽然技术上可以，但**不建议**在 Trae 里做：

### ❌ BOE/PPE 部署

理由：
- 生产部署需要 TL 审批、QA 信号，不是研发单独能决定
- Trae 里跑部署等于在 IDE 里动生产环境，心理安全感低
- 飞书话题更适合多人协作审批

**替代**：在 Trae 完成代码改动 + 本地/远端测试后，**切换到飞书**调起 `e2e-deploy-pipeline`。

### ❌ 团队协作类

- `e2e-progress-notify` 发飞书通知：Trae 下默认不触发
- `e2e-prd-share` 把 PRD 发到飞书：Trae 下需用户主动指令

**理由**：Trae 是个人 IDE，不是协作工具。

### ❌ Sub-Agent 大规模派发

Trae 对多 Agent 并行的支持可能不如 OpenClaw 成熟。`e2e-code-review-loop` 在 Trae 下建议**降级为串行**（每个仓库单独处理）。

详见 `skills/e2e-code-review-loop/references/trae-tools.md`。

---

## 五、推荐 Trae 使用模式：混合运行时

**最佳实践**：Trae 做前置，OpenClaw + 飞书做全链路。

```
阶段 1-3（需求澄清 → PRD → 代码分析）
  ↓ 在 Trae 里做（研发熟悉 IDE）
  ↓
阶段 4-6（代码改造 → 测试 → 部署）
  ↓ 切到 OpenClaw + 飞书（多人协作 + 审批）
```

切换方式：
- 研发在 Trae 里完成 PRD 和代码映射
- 把产出物（PRD.md、CODEBASE-MAPPING.md）发到飞书话题
- 在话题 @端到端交付 继续后续阶段

---

## 六、常见问题

### Q1：Trae 里 skill 没触发？

检查：
1. Trae 里 `~/.agents/skills/` 是否已配置为 skill 路径
2. `using-end-to-end-delivery/SKILL.md` 的 description 是否被 Trae 读到
3. 当前对话是否真的命中 skill 的触发词

### Q2：Trae 里调 `bytedance-*` skill 失败？

- 确认 Trae 能访问字节内网（VPN 已连）
- 确认 `bytedance-auth` 登录有效
- Trae 的 MCP 挂载是否包含 bytedance-tools（看 Trae MCP 配置）

### Q3：Trae 里 Agent 想改我的代码，但我还没准备好？

用 Trae 的"Ask before edit"设置（具体名称可能不同），让每次代码修改都要用户确认。

本项目的 Skill 内部已有 HARD-GATE，但 IDE 级别加一层保险更稳。

### Q4：Trae 的 Custom Agent 和 OpenClaw 的 Agent 不同步？

两者是**独立的 Agent 定义**，本项目提供同一套 skill 在两个运行时都能用。

同步策略：
- 核心人格：都读 `AGENTS.md`（通过软链接）
- Skill 定义：都读 `~/.agents/skills/`（统一位置）
- 运行时差异：各自的 `references/trae-tools.md` / `openclaw-tools.md`

---

## 七、Trae vs OpenClaw 切换 checklist

从 Trae 切换到 OpenClaw 使用同一个功能时，核对：

- [ ] PRD 文件已经在项目目录（或已 commit）
- [ ] 如果 PRD 需要飞书话题讨论 → 调 `e2e-prd-share` 发到话题
- [ ] 如果需要团队通知 → 切换到飞书话题后触发 `e2e-progress-notify`
- [ ] 部署类操作（`e2e-deploy-pipeline`）→ **必须**切到飞书话题做（有多人审批）

---

## 八、进阶：Trae 的 Skill 开发体验

Trae 是 IDE，所以可以用来**开发新 skill**：

1. 在 Trae 里打开 `~/github/end-to-end-delivery`
2. 修改 `skills/*/SKILL.md`
3. 保存后 `install.sh update` 同步到 `~/.agents/skills/`
4. 在 Trae 自己的对话里测试新 skill

**Hot reload**：如果 Trae 支持 skill 热重载（像 OpenClaw 的 `skills.load.watch`），省去重启 IDE 的麻烦。

---

## 九、Trae 文档索引

（Trae 是字节内部工具，具体文档路径以你获取到的为准）

- Trae Agent Skills 规范
- Trae MCP 集成
- Trae Custom Agent

如果 Trae 文档不清晰，参考 Agent Skills 开放标准：https://agentskills.io

---

*本指引面向字节内部 Trae 用户，同时考虑了 Trae 与开放 Agent Skills 标准的一致性。*
