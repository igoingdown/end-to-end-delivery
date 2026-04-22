# OpenClaw 运行时工具映射 · e2e-remote-test

## 核心工具

本 skill 主要依赖：
- `bash` 工具 —— 执行 `scripts/run-remote-test.sh`
- 本地 SSH 配置 —— `~/.ssh/config` 的 alias

**不依赖**任何 `bytedance-*` skill，因为这是纯 SSH 操作。

## OpenClaw 执行环境

OpenClaw 的 bash 工具执行脚本时：

```bash
bash ~/.agents/skills/e2e-remote-test/scripts/run-remote-test.sh \
  --host "$HOST" \
  --dir "$REMOTE_DIR" \
  --build "$BUILD_CMD" \
  --test "$TEST_CMD"
```

**路径说明**：生产期 skill 在 `~/.agents/skills/`，所以脚本路径是 `~/.agents/skills/e2e-remote-test/scripts/run-remote-test.sh`。

## SSH 前置配置

**OpenClaw 运行的机器**必须已配置：

1. `~/.ssh/config` 里有开发机的 alias
2. `~/.ssh/id_rsa` 或等价的私钥能登录开发机
3. `ssh-agent` 已加载私钥（避免每次输入密码）

OpenClaw 部署在服务端时，这些配置要由运维预先准备。

## 结果回传

脚本 stdout/stderr 直接回传给主 Agent。主 Agent 按 SKILL.md 的"结果解析"章节解析 marker：
- `[BUILD_FAILED]` / `[TEST_FAILED]` / `[TIMEOUT]` / `[SSH_FAILED]` / `[DIR_NOT_FOUND]`

## 超时管理

OpenClaw 的 bash 工具自身可能有超时。脚本的 `--timeout` 应**略小于** OpenClaw bash 工具超时，避免被 OpenClaw 先 kill 导致结果丢失。

建议：
- 默认 `--timeout 600`（脚本内）
- OpenClaw bash 工具超时设 900+

## 话题归档

测试报告（成功或失败）应通过 `feishu-cli-msg` 发到话题，方便后续追溯。
