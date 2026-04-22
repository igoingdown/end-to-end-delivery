# Trae 运行时工具映射 · e2e-remote-test

## Trae 优势：IDE 集成终端

Trae 是 IDE，有内置 terminal。用户可以**直接**在 terminal 里看到 SSH 输出，不需要 Agent 中转。

调用方式：

```
方式 A（推荐）：Agent 调脚本，输出流式回传到 IDE
bash ~/.agents/skills/e2e-remote-test/scripts/run-remote-test.sh \
  --host "$HOST" ...

方式 B：引导用户手工跑
Agent 构造完整命令 → 给用户一键复制
用户在 IDE terminal 里执行，Agent 解析输出
```

Trae 下 **方式 A 优先**。只有脚本路径问题时 fallback 到 B。

## SSH 配置优势

Trae 跑在用户本机，`~/.ssh/config` 就是用户的真实配置。
用户在 IDE 里已经能 `ssh dev01` 连通，Agent 直接复用即可，无需额外配置。

## 代码同步的协同建议

本 skill MVP 不做代码同步，但 Trae 用户有"Dev SSH" 插件能一键同步。

Agent 可以提醒：

```
💡 Trae 用户提示：
  在跑测试前，请用 Dev SSH 工具 Sync 把最新代码推送到 $HOST。
  不然测试跑的是旧代码。
```

**不自动做同步**（MVP 硬约束）。

## 超时管理

Trae 下超时更宽松（IDE 场景用户耐心更高），可以用默认 `--timeout 600`。

长测试（> 10 分钟）建议拆分：
- 先跑 smoke test（快速反馈）
- 再跑 full test（后台）

## 结果呈现

Trae 用户是研发，结果报告可以：
- 直接贴完整 stdout（不省略）
- 失败用例直接用代码块展示（IDE 能高亮）
- 给出"点击跳转"提示（"`foo_test.go:42` —— 用 Cmd+Click 打开"）

## 工具名映射

| 操作 | OpenClaw | Trae |
|---|---|---|
| 执行脚本 | `bash` 工具 | `run_shell_cmd` 或 terminal 集成 |
| SSH 本身 | 本地 `ssh` 二进制 | 本地 `ssh` 二进制（同） |
| 文件存取 | `/workspace` | IDE workspace |
