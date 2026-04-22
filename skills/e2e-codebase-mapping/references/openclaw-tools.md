# OpenClaw 运行时工具映射 · e2e-codebase-mapping

> 本 skill 在 OpenClaw 运行时下的工具调用约定。

## 依赖的底层 skill

在 OpenClaw 下，本 skill 依赖以下已安装 skill（在 `~/.agents/skills/` 中）：

- `bytedance-auth` —— 认证前置
- `bytedance-codebase` —— 代码搜索 / 文件读 / Diff 查询
- `bytedance-bam` —— 服务 PSM / IDL / Method 查询
- `bytedance-hive` —— 数据血缘（可选）

## 工具调用方式

OpenClaw 下通过 skill 描述自动触发，**不要**自己拼 `bytedcli` 命令：

```
❌ 不要：
在本 skill 中直接执行 bash 命令 `NPM_CONFIG_REGISTRY=... npx @bytedance-dev/bytedcli codebase search ...`

✅ 正确：
在本 skill 的 prompt 中说明"调用 bytedance-codebase 搜索 X 关键词"，
让 bytedance-codebase skill 自己处理命令拼接、认证、JSON 解析。
```

## 跨 skill 认证

调用 `bytedance-*` 系列前，**默认**假设 `bytedance-auth` 已登录。

遇到 `Not authenticated` 错误时：
1. 调用 `bytedance-auth` 重新登录
2. 重试原始操作
3. 2 次失败 → 返回 `BLOCKED` 给主 Agent

## OpenClaw 特定注意

- Sessions 之间不共享 context，本 skill 的产出必须持久化到文件（Markdown）
- `sessions_spawn` 派发 Sub-Agent 时，要把 CODEBASE-MAPPING 产出文件路径作为上下文传递
- 归档话题时，Agent 应该把产出文件放到话题的"附件"区域（通过 `feishu-cli-msg` 发文件）

## 网络依赖

所有 `bytedance-*` 调用需要字节内网。
OpenClaw 在公网环境下会无法访问 —— 此时本 skill 应明确告知"需要内网环境"并 `BLOCKED`。
