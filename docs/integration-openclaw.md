# OpenClaw 集成指引

> 本文档说明如何在 OpenClaw 运行时下部署和运行"端到端交付" Agent。
> 基于 OpenClaw 官方文档（截至 2026-04）。如果 OpenClaw 版本变更，以官方文档为准。

---

## 前置条件

- Node.js 22.16+（推荐 24.x）
- OpenClaw 已安装且 Gateway 能正常启动
- 本地 `~/.agents/skills/` 已经存在本地 46 个 skill（字节 `bytedance-*` + 飞书 `feishu-cli-*`）
- 飞书机器人已创建且和 OpenClaw Gateway 对接好（见 OpenClaw 飞书 channel 文档）
- 字节 SSO 和飞书认证已登录（通过对应 skill）

---

## 一、部署步骤（一次性）

### Step 1：克隆项目到开发期目录

```bash
cd ~/github
git clone <this-repo> end-to-end-delivery
cd end-to-end-delivery
```

### Step 2：运行安装脚本，同步到生产期目录

```bash
./install.sh --target openclaw       # 只装 ~/.agents/skills/（OpenClaw 专用）
# 或默认两处都装（Claude Code + OpenClaw）：
# ./install.sh
```

`install.sh` 做的事：

- 把 `skills/` 下的 14 个新 skill 同步到 `~/.agents/skills/`（以及 `~/.claude/skills/` 如果用了 `--target all`）
- 每个 skill 目录下留一个 `.installed-by-e2e-delivery` 标记文件，用于后续更新 / 卸载识别
- 给 `scripts/*.sh` 加执行权限
- 检查命名冲突：带标记的视为本项目装的（更新），无标记的视为用户自有 skill（报错停止，需 `--force` 才覆盖）
- 默认不覆盖已有 skill（安全）

详细参数见 `./install.sh --help`；具体实现见 `install.sh`。

### Step 3：配置 OpenClaw 识别 `~/.agents/skills/` 目录

OpenClaw 默认 skill 加载路径优先级（从高到低）：

1. `<workspace>/skills/`（per-agent，workspace 级别）
2. `~/.openclaw/skills/`（全局 managed 级别）
3. `skills.load.extraDirs`（配置的额外目录，最低优先级）

**用户选择的 `~/.agents/skills/`** 不是 OpenClaw 默认路径，需要在配置里加到 `skills.load.extraDirs`。

#### 方式 A：直接编辑 `~/.openclaw/openclaw.json`（JSON5 格式）

手工追加：

```json5
{
  // ... 现有配置保留不动 ...

  "skills": {
    "load": {
      "watch": true,                 // 文件变化自动热重载
      "watchDebounceMs": 250,
      "extraDirs": [
        "~/.agents/skills"           // 用户指定的 skill 目录
      ]
    }
  }
}
```

**完整的配置片段**见 `configs/openclaw-snippet.jsonc`，可以直接 merge 进你现有的 `openclaw.json`。

#### 方式 B：用 `openclaw config set` 命令（推荐）

比直接改文件更安全——会走 schema 校验：

```bash
openclaw config set skills.load.watch true
openclaw config set skills.load.watchDebounceMs 250
openclaw config set skills.load.extraDirs '["~/.agents/skills"]'
```

### Step 4：（可选）配置 Agent 默认使用千问模型

根据项目硬约束 #6（千问 3.6 Plus 首选），如果还没配置，加：

```json5
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "qwen/qwen-3.6-plus",       // 千问作为主模型
        "fallbacks": ["zhipu/glm-5.1"]         // GLM 备选
      }
    }
  }
}
```

具体 model ID 参考你的模型 provider 配置，上面是示意。

### Step 5：重启 Gateway 使配置生效

```bash
openclaw gateway restart
```

或如果以 daemon 跑：

```bash
openclaw daemon restart
```

### Step 6：验证 skill 已加载

```bash
openclaw skills list
```

应该能看到本项目 14 个 skill 出现在列表里：

- `using-end-to-end-delivery`
- `adversarial-qa`
- `requirement-clarification`
- `prd-generation`
- `e2e-web-search`
- `e2e-codebase-mapping`
- `e2e-solution-design`
- `e2e-dev-task-setup`
- `e2e-remote-test`
- `e2e-deploy-pipeline`
- `e2e-code-review-loop`
- `e2e-progress-notify`
- `e2e-architecture-draw`
- `e2e-prd-share`

同时应该看到本地原有的 46 个 skill。

### Step 7：（推荐）配置 AGENTS.md 自动加载

OpenClaw 的 agent 会加载 workspace 下的 `AGENTS.md`。但本项目的 `AGENTS.md` 在 `~/github/end-to-end-delivery/`，不在 workspace。

**两种处理方式**：

**方式 A：复制 AGENTS.md 到 workspace**

```bash
cp ~/github/end-to-end-delivery/AGENTS.md ~/.openclaw/workspace/AGENTS.md
```

**方式 B：用软链接（推荐，方便更新）**

```bash
ln -sf ~/github/end-to-end-delivery/AGENTS.md ~/.openclaw/workspace/AGENTS.md
```

> ⚠️ **注意**：如果你已有 `AGENTS.md`（OpenClaw `openclaw setup` 生成的默认版本），备份后再覆盖：
>
> ```bash
> mv ~/.openclaw/workspace/AGENTS.md ~/.openclaw/workspace/AGENTS.md.backup
> ln -sf ~/github/end-to-end-delivery/AGENTS.md ~/.openclaw/workspace/AGENTS.md
> ```

---

## 二、多 Agent 支持（可选）

OpenClaw 是单用户设计，但支持多 Agent。你可以为"端到端交付" Agent 创建专属 agent：

```bash
openclaw agents add e2e-delivery \
  --identity ~/github/end-to-end-delivery/AGENTS.md \
  --model qwen/qwen-3.6-plus \
  --workspace ~/.openclaw/workspace-e2e \
  --description "端到端交付 Agent"
```

这样做的好处：

- `e2e-delivery` agent 有独立 workspace，和你其他 agent 不冲突
- 专属的 skill 目录和 session 历史
- 在飞书话题触发时可以明确路由到这个 agent

---

## 三、飞书话题触发

### 3.1 一般触发模式

用户在飞书话题里 @ 机器人：

```
@端到端交付 我们想做个用户分层运营的能力
```

OpenClaw Gateway → 识别话题对应的 agent → 加载 skills → 进入对话。

### 3.2 保证触发率

如果发现机器人不触发，检查：

1. **飞书机器人配置**：
   - 机器人是否在话题里
   - Gateway 的飞书 channel 配置是否正确
   - `openclaw config get channels.feishu` 验证

2. **Agent 路由**：
   - 默认 agent 是否正确：`openclaw config get agents.default`
   - 如果用了专属 agent（方式二），路由规则是否对

3. **Skill 是否已加载**：
   - `openclaw skills list` 看 using-end-to-end-delivery 是否在
   - `openclaw doctor` 诊断问题

### 3.3 对话流程

Agent 在飞书话题里的对话遵循 `using-end-to-end-delivery` 定义的主流程：

1. 对抗式问答澄清需求
2. 结构化需求梳理
3. 生成 Markdown PRD（**发到话题作为消息 + 附件**）
4. 代码映射分析
5. 创建研发任务（HARD-GATE 要求用户确认）
6. 代码改造（Sub-Agent 并行）
7. SSH 远端测试
8. BOE/PPE 部署（3 个 HARD-GATE）
9. 归档总结

---

## 四、Sub-Agent 派发配置

`e2e-code-review-loop` 依赖 OpenClaw 的 `sessions_spawn` 派发 Sub-Agent。

### 4.1 默认配置

OpenClaw 原生支持 `sessions_spawn`。无需额外配置。

### 4.2 资源限制

多 Sub-Agent 并行会消耗更多资源（每个 Sub-Agent 独立 context 和模型调用）。建议：

```json5
{
  "agents": {
    "defaults": {
      "subAgents": {
        "maxConcurrent": 3,             // 最多并发 3 个
        "timeoutMinutes": 30            // 单个 30 分钟超时
      }
    }
  }
}
```

> **注意**：上面是推荐配置示例，具体字段名和支持以当前版本的 OpenClaw 为准。不同版本可能有差异。

### 4.3 Sub-Agent 工具白名单

`e2e-code-review-loop` 派发 Sub-Agent 时会指定工具授权白名单：

**授权**（Sub-Agent 可用）：

- `bytedance-codebase`
- `bytedance-bits`
- `bytedance-auth`
- 本地 `bash`（限于 lint/build）

**禁止**（不授权给 Sub-Agent，避免越权）：

- `bytedance-tce` / `bytedance-tcc`（部署）
- `feishu-cli-msg`（通知）
- `sessions_spawn`（避免递归派发）

---

## 五、常见问题

### Q1：`openclaw gateway restart` 后 skill 还是没加载？

检查点：

```bash
# 1. 确认 extraDirs 配置生效
openclaw config get skills.load.extraDirs

# 2. 确认目录存在
ls ~/.agents/skills/ | head

# 3. 确认 skill 文件结构正确
cat ~/.agents/skills/using-end-to-end-delivery/SKILL.md | head -5

# 4. 诊断
openclaw doctor
```

### Q2：Gateway 启动失败，config 报错？

OpenClaw 用 Zod 严格 schema 校验。启动失败时看日志：

```bash
openclaw logs --follow
```

常见错误：

- 多余的键（schema 不认识）
- 类型错误（期望 boolean 给了 string）
- 路径不是绝对路径（`~/` 在某些场景需要展开）

**建议**：用 `openclaw config set` 代替直接改文件。

### Q3：Skill 的 description 用中文触发不准？

LLM 触发 skill 基于 description 语义匹配。中文 description 有时会因为模型偏向英文而触发率下降。

**优化**：

- 检查 description 是否多种触发词变体都有（中英文都列）
- 参考 `docs/skill-orchestration-map.md` 的触发关键词建议

### Q4：话题里 Agent 回复太慢？

- 千问 3.6 Plus 在大 context 下响应慢是正常的
- 考虑：
  - 阶段 1 的澄清提示用户打断（"够了，进入下一步"）
  - Sub-Agent 并发度提高（如果模型 TPM 允许）

### Q5：多台机器共享同一套 skill？

OpenClaw 官方是单机设计。如果团队多人用：

- 每个人本地各装一份（推荐）
- 或用 Git submodule 同步 `~/.agents/skills/`（见 `install.sh` 的 update 模式）

### Q6：飞书账号和 Gateway 的关系？

OpenClaw Gateway 上配的飞书账号 = Agent 的"身份"。

- 账号 A 在话题里发 "@XX"，Agent 看到的是**账号 A 发的消息**
- 多人在话题里互动都是**账号 A 在和他们说话**（单身份）

---

## 六、推荐的生产部署模式

### 模式 A：个人使用（推荐研发个人）

```
用户 Mac/Linux 本机
├── OpenClaw Gateway (systemd / launchd)
├── 本地 ~/.agents/skills/ (包含本项目 13 + 本地 46)
├── 飞书 PC 客户端
└── 公司 VPN
```

### 模式 B：团队小组（试点）

```
共享 VM (Linux, 内网)
├── OpenClaw Gateway (systemd)
│   └── 公司账号的飞书机器人
├── ~/.agents/skills/
└── 多人在同一话题里协作
```

> **⚠️ 多人场景警告**：OpenClaw 单用户设计。多人用同一个 Agent 实例，session 可能混乱。如果团队协作需求强烈，考虑：
>
> - 每个用户独立起一个 `openclaw --profile <username>` 实例
> - 飞书机器人支持多账号路由

---

## 七、卸载

如果需要卸载本项目：

```bash
# 停止 Gateway
openclaw gateway stop

# 删除 extraDirs 配置
openclaw config unset skills.load.extraDirs

# 删除项目 skill（只删带 .installed-by-e2e-delivery 标记的，不误伤本地已有 skill）
cd ~/github/end-to-end-delivery
./install.sh --uninstall --target openclaw

# 恢复 AGENTS.md 备份
mv ~/.openclaw/workspace/AGENTS.md.backup ~/.openclaw/workspace/AGENTS.md

# 重启
openclaw gateway start
```

---

## 八、官方文档索引

更多细节参考 OpenClaw 官方文档：

- Configuration：<https://docs.openclaw.ai/gateway/configuration>
- Skills：<https://docs.openclaw.ai/tools/skills>
- Workspace：<https://docs.openclaw.ai/concepts/agent-workspace>
- Multi-Agent：<https://docs.openclaw.ai/multi-agent>

---

*本集成指引随 OpenClaw 版本迭代可能需要更新。遇到文档与实际不符时，请以 OpenClaw 官方为准，并提 issue 告知维护者。*
