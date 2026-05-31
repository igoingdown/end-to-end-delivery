# 如何添加新 Skill

本指南覆盖向本项目添加新 skill 的完整流程。

---

## 目录结构

```
skills/{skill-name}/
├── SKILL.md                    # 必须：skill 定义（frontmatter + 正文）
├── references/                 # 按需：参考文档
│   ├── openclaw-tools.md       # OpenClaw 运行时的工具映射
│   ├── trae-tools.md           # Trae 运行时的工具映射
│   └── *.md                    # 其他参考文档
└── scripts/                    # 按需：可执行脚本
    └── *.sh                    # install.sh 会自动 chmod +x
```

## SKILL.md 格式

```yaml
---
name: skill-name          # 必须与目录名完全一致
description: "..."         # 50-2000 字符，用于 LLM 路由触发
---
```

frontmatter 之后是 Markdown 正文，定义 skill 的行为规范。

### description 要求

- **最少 50 字符**：太短会降低 LLM 路由命中率
- **最多 2000 字符**：太长会挤占 system prompt 空间
- 包含用户可能说的**触发短语**（中英文都加）
- 写清楚 skill 的核心能力和适用场景

## 命名约定

| 层 | 前缀 | 示例 |
|---|---|---|
| 编排层（有写操作/跨 skill 调用） | `e2e-` | `e2e-deploy-pipeline` |
| 飞书层 | `e2e-` | `e2e-prd-share` |
| 对话层（纯对话/只读） | 语义名 | `adversarial-qa`、`prd-generation` |
| Bootstrap | `using-` | `using-end-to-end-delivery` |

命名前先确认与 `~/.claude/skills/` 和 `~/.agents/skills/` 下已有 skill 无冲突。

## 复杂度判定

决定 skill 该做简单还是复杂：

| 命中即停 | → 复杂 Skill |
|---|---|
| 有写操作或部署动作 | 需要 HARD-GATE + `--dry-run` |
| 有循环（code → test → fix） | 需要状态管理 |
| 中途需等待人工确认 | 需要 HARD-GATE |
| 跨 3 个以上 skill 组合调用 | 需要编排逻辑 |
| **以上都不是** | **→ 简单 Skill** |

完整判定矩阵见 README.md「Skill 复杂度判定矩阵」章节。

## 跨运行时适配

如果 skill 调用了底层 skill（`bytedance-*`、`feishu-cli-*` 等），需要在 `references/` 下提供工具映射文件：

- `openclaw-tools.md`：OpenClaw 运行时下的工具调用约定、认证前置、网络依赖、失败处理
- `trae-tools.md`：Trae 运行时下的工具差异、IDE 集成优势、降级方案

每个文件的内容是**skill 特有的**，不是通用模板。参考现有 skill（如 `e2e-deploy-pipeline/references/`）的写法。

纯对话类 skill（如 `adversarial-qa`）不调用底层 skill，不需要工具映射文件。

## 提交前检查

```bash
# 1. 校验 frontmatter 格式
bash scripts/validate-skills.sh

# 2. 确认安装脚本能识别新 skill（需要先加到 install.sh 的 PROJECT_SKILLS 数组）
bash install.sh --dry-run

# 3. CI 会自动检查
#    - ShellCheck（如果有 scripts/*.sh）
#    - Markdown lint
#    - frontmatter 校验
#    - 14 个 skill 完整性（需要更新为新数量）
#    - references/ 文件存在性
```

## 加入 install.sh

在 `install.sh` 的 `PROJECT_SKILLS` 数组中添加新 skill 名：

```bash
PROJECT_SKILLS=(
  ...
  "your-new-skill"    # 新增
)
```

同步更新 CI 中 "Verify all 14 skills exist" 步骤的期望列表和数量。

## 加入主流程（如需要）

如果新 skill 是 7 阶段主流程的一部分，需要同步更新：

1. `skills/using-end-to-end-delivery/SKILL.md` 的流程图
2. `docs/skill-orchestration-map.md` 的完整流程图
3. README.md 的项目结构和引用依赖图
