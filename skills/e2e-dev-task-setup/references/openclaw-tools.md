# OpenClaw 运行时工具映射 · e2e-dev-task-setup

## 依赖的底层 skill

- `bytedance-auth` —— SSO 前置
- `bytedance-bits` —— 研发任务 CRUD、分支绑定
- `bytedance-codebase` —— 验证分支是否存在（可选）

## 关键约束

### `--dry-run` 是 HARD-GATE 实现

`bytedance-bits` 原生支持 `--dry-run` 参数。本 skill 利用这一点实现 HARD-GATE：
- 首次调用必加 `--dry-run`
- 展示 payload 给用户
- 用户确认后，才让 bytedance-bits skill 去掉 `--dry-run` 重新调用

### `--json` 位置约束

`bytedance-bits` 的底层 CLI 要求 `--json` 放在命令**前**（不是后）：

```
✅ bytedcli --json bits develop create ...
❌ bytedcli bits develop create --json ...
```

本 skill 不直接拼命令，但要知道这个约束，出错时好 debug。

## 返回值处理

`bytedance-bits` 以 JSON 格式返回。本 skill 需要从 JSON 中提取：
- `dev_id` —— 主 key
- `bits_url` —— 给用户的链接
- `created_at` —— 时间戳

不要自己解析文本，让 `bytedance-bits` skill 处理 JSON 解析。

## 错误处理

常见错误：
- `Not authenticated` → 调 `bytedance-auth login` 重试
- `Missing argument: --dev-id` → 参数检查
- `Service PSM not found` → PSM 名拼错，向用户确认

详细错误清单见 `bytedance-bits` 的 `references/troubleshooting.md`（由该 skill 自维护）。

## OpenClaw 特定

- 产出的 dev-id 需要持久化（写入话题归档总结）
- 通过 `sessions_send` 把 dev-id 传递给 `e2e-code-review-loop`
- 失败时通过 `feishu-cli-msg` 发告警卡片
