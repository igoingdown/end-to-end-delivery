# Trae 运行时工具映射 · e2e-codebase-mapping

> 本 skill 在 Trae IDE 下的工具调用约定。

## Trae 和 OpenClaw 的关键差异

| 维度 | OpenClaw | Trae |
|---|---|---|
| Skill 加载路径 | `~/.agents/skills/` (第 3 优先级) | `.trae/skills/` 或通过 MCP |
| Sub-Agent | `sessions_spawn` | Trae 的子 agent 机制 |
| 文件访问 | 通过 workspace | IDE 直接的文件系统访问 |
| 用户交互 | 飞书话题（异步） | IDE 内对话（同步） |

## 依赖的底层 skill

Trae 下，本 skill 同样依赖：

- `bytedance-auth`
- `bytedance-codebase`
- `bytedance-bam`

**前提**：本地 `~/.agents/skills/` 已经通过 Trae 的 MCP 机制挂载进来（见 `docs/integration-trae.md`）。

## Trae 特定优势

### 优势 1：直接文件系统访问

Trae 是 IDE，可以**直接读**本地 clone 的代码。

如果用户已经在 Trae 里打开了相关仓库：
- 不用通过 `bytedance-codebase` 远程搜索
- 直接用 Trae 的文件操作工具（`view`、`grep`）
- 更快，更详细

**判断逻辑**：
```
步骤 4（深入改动点）时，先判断：
- 用户当前 Trae workspace 里有没有这个仓库 → 有 → 直接读本地文件
- 没有 → 调用 bytedance-codebase 远程读
```

### 优势 2：结果直接写到文件

产出的 `CODEBASE-MAPPING-*.md` 可以直接写到用户的 workspace 目录：

```
Trae 用户：
本 skill 完成后，在用户当前 project 根目录生成 CODEBASE-MAPPING-*.md
用户可以直接在 IDE 里打开编辑
```

## 对话风格差异

Trae 主要用户是研发同学，可以：
- 用代码片段、技术术语
- 直接贴 IDL 定义、Git diff
- 少做"向非研发同学解释"的转换

## 工具名映射（如果 Trae 版本有差异）

截至 2026-04，Trae 对 Agent Skills 标准的支持与 OpenClaw 基本一致。
如果发现工具名差异（`Read` vs `view` 之类），在本文件增补映射。

当前已知映射：
- Trae 的文件读：用 IDE 内置的 `view` 工具
- OpenClaw 的文件读：通过 `bytedance-codebase` 远程读

## 网络依赖

Trae 本身不强制内网。但调用 `bytedance-*` skill 时仍需内网。

用户在外网环境时：
- 本地已有代码 → 仍可做映射
- 需要查远程仓库 / BAM → `BLOCKED`
