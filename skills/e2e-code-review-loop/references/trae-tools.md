# Trae 运行时工具映射 · e2e-code-review-loop

## Trae 下的 Sub-Agent 机制

Trae 对多 Agent 的支持与 OpenClaw 的 `sessions_spawn` 略有差异。

根据 Trae 版本，可能有以下几种方式：

### 方式 A：Trae 原生多 Agent（推荐）

Trae 支持在一个 workspace 内启动多个 agent 实例，每个实例独立 context。

```
主 Agent 调 Trae 的 "spawn child agent" API
每个 child agent 处理一个仓库
```

### 方式 B：串行降级

如果 Trae 版本不支持真正的并行 Sub-Agent：

```
主 Agent 串行处理每个仓库：
for repo in repos:
    - 启动新对话聚焦该仓库
    - 完成改动
    - 收集结果
    - 回到主对话
```

缺点：慢（3 个仓库 * 10 分钟 = 30 分钟），但更可靠。

### 方式 C：引导用户人工派发

如果 Trae 完全不支持多 Agent：

```
主 Agent 输出 3 个任务包给用户：
"请打开 3 个 Trae 窗口，每个窗口执行一个任务包"
收集用户手工反馈
```

降级方案，仅在 A/B 都不可行时用。

## 推荐使用方式

**Trae 下优先 B（串行）**：
- Trae 用户是研发，一次改一个仓库更符合开发习惯
- 研发可以在 IDE 里直接 review 每个改动
- 减少"Agent 并行但 IDE 窗口混乱"的问题

## 工具授权

Trae 下 Sub-Agent（或串行子任务）的工具授权同 OpenClaw：
- 允许：`bytedance-codebase`、`bytedance-bits`、本地 IDE 工具
- 禁止：部署类、通知类

## 代码合入的协作

Trae 下合入 MR：
- Agent 调 `bytedance-codebase` 合入
- 或引导研发在 code 平台上手动合入（更符合研发习惯）

## Review 的 Trae 优势

Trae 可以：
- 在 IDE 里直接看每个 MR 的 Diff
- 在 IDE 里直接给 comment
- 与 Agent 协作来回 review

## 网络

同 OpenClaw，依赖内网。
