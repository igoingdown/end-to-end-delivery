# OpenClaw 运行时工具映射 · e2e-code-review-loop

## 核心机制：sessions_spawn

OpenClaw 原生支持 `sessions_spawn` 派发 Sub-Agent。本 skill 核心依赖这个机制。

### 派发方式

```
# 主 Agent 调用 sessions_spawn
sessions_spawn(
  task_id="TASK-user-segment-api-001",
  task_package=<任务包 Markdown>,
  tools=["bytedance-codebase", "bytedance-bits", "bytedance-auth"],
  timeout_minutes=30
)
```

`sessions_spawn` 返回一个 session handle，主 Agent 通过 handle 查询状态。

### 并行派发

```
# 并行派发多个 Sub-Agent
handles = []
for task in sub_agent_tasks:
    handle = sessions_spawn(task)
    handles.append(handle)

# 等待全部完成
results = sessions_wait_all(handles, timeout=1800)  # 30 分钟总超时
```

### 结果收集

每个 Sub-Agent 通过 `sessions_return` 返回：

```python
{
  "status": "DONE" | "DONE_WITH_CONCERNS" | "BLOCKED" | "NEEDS_CONTEXT",
  "mr_url": "https://code.bytedance.net/...",
  "concerns": ["单测 X 不稳定", "..."],  # 如果有
  "context_needed": "...",  # 如果 NEEDS_CONTEXT
  "blocker_reason": "..."   # 如果 BLOCKED
}
```

## Sub-Agent 的工具访问

Sub-Agent 默认只有"主 Agent 授权"的工具。本 skill 派发时：

**授权**：
- `bytedance-codebase` —— 读代码、创 MR
- `bytedance-bits` —— 更新 dev-task 状态
- `bash`（仅限本地 lint/build，不能 SSH 远端）

**不授权**：
- `bytedance-tce` / `bytedance-tcc` —— 部署类，只能主 Agent 调
- `feishu-cli-msg` —— 通知类，只能主 Agent 调
- `sessions_spawn` —— Sub-Agent 不能再派发 Sub-Agent（避免递归）

## 状态监听

Sub-Agent 执行期间，主 Agent 可以：
- 用 `sessions_status(handle)` 查询当前进度
- 每 5 分钟查询一次，向用户同步进度（"Agent 正在改 user.segment.api"）

## 取消机制

用户说"取消"时：
- 主 Agent 调 `sessions_cancel(handle)` 取消所有正在跑的 Sub-Agent
- 已经创建的 MR 不会自动删除（需要用户手动）

## 会话持久化

如果本 skill 跨多轮对话：
- Sub-Agent 的状态由 OpenClaw 持久化（session 不丢）
- 主 Agent 恢复后能继续查 handle

## 网络依赖

所有 Sub-Agent 操作依赖字节内网。公网环境全部 `BLOCKED`。
