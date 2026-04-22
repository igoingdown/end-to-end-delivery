# Trae 运行时工具映射 · e2e-dev-task-setup

## 依赖的底层 skill

同 OpenClaw，前提是 `~/.agents/skills/` 已通过 Trae 的 MCP 挂载。

## Trae 特定优势

### IDE 上下文自动填充

Trae 是 IDE，可以**直接知道**当前打开的仓库和分支。

```
本 skill 在 Trae 下可以自动提取：
- 仓库 PSM（从 git remote 或 .bits 配置）
- 当前分支名
- 本地未提交的变更
```

减少询问用户的负担——Trae 用户（研发）在 IDE 里已经设置好了分支。

### 代码 Review 提前

Trae 下可以在创建任务**前**就做代码质量检查：
- 本地 lint
- 本地单测
- 扫描依赖漏洞

这些检查通过才进入 `--dry-run` 步骤。

## HARD-GATE 在 Trae 下的呈现

Trae 是同步对话，HARD-GATE 可以用**对话框式**展示：

```
┌─────────────────────────────────────┐
│  即将在 BITS 创建研发任务            │
│  [完整 payload 展示]                 │
│                                     │
│  [ ✅ 确认创建 ]  [ ❌ 取消 ]        │
└─────────────────────────────────────┘
```

（Trae 如果支持按钮式交互，可以用；不支持则用文本"等待用户回复"）

## 工具名映射

| 操作 | OpenClaw | Trae |
|---|---|---|
| 读文件 | `bytedance-codebase` 远程读 | IDE 内建 `view` |
| 执行 bash | `bash` 工具 | IDE 内建 terminal |
| 发飞书消息 | `feishu-cli-msg` | `feishu-cli-msg`（仍可用，如果 MCP 已挂载） |

## 网络约束

Trae 本身不强制内网。但所有 `bytedance-bits` 操作需要内网。

用户在外网时，**整个 skill 都不可用**。明确告知：

```
e2e-dev-task-setup 需要访问字节内网（BITS 平台）。
请先连 VPN 或到内网环境再调用我。
```
