# Existing Skills Inventory —— 本地已有 46 个 Skill 索引

> **用途**：本项目 14 个新 skill 的"底层能力库"。每个新 skill 的 SKILL.md 应该引用本文件找到可复用能力。
>
> **数据来源**：用户本地 `~/.agents/skills/` 目录盘点（46 个 skill，2026-04-17 快照）。
>
> **更新策略**：本地 skill 数量/能力变化时同步更新本文件。

---

## 使用说明

### 如何在 SKILL.md 里引用已有 skill

**正确做法**（引用能力，不引用具体命令）：

```markdown
## Implementation

本 skill 需要搜索字节内部代码仓库，调用 `bytedance-codebase` skill 完成这一步。
让目标 skill 处理所有认证、参数、错误处理的细节。
```

**错误做法**（直接写底层命令）：

```markdown
# ❌ 不要这样
执行 `bytedcli codebase search --query xxx --site cn`
```

**原因**：`bytedance-codebase` 的命令和参数可能变化，但能力稳定。引用能力让你的 skill 对底层变化免疫。

---

## 按端到端阶段分类

### 阶段 0：认证基础（所有字节/飞书 skill 的前置）

| Skill | 能力 | 触发词 |
|---|---|---|
| `bytedance-auth` | 字节 SSO 登录、登出、token 查询 | 登录字节 CLI、认证状态、账号 |
| `feishu-cli-auth` | 飞书 OAuth、User Access Token 管理 | 登录飞书、飞书 token |
| `bytedance-jwt` | 获取字节内部服务 JWT Token（多 Region） | JWT、token、服务认证 |

**关键原则**：调用任何 `bytedance-*` 前，确保已 `bytedance-auth` 登录。遇到 `Not authenticated` 错误时，先调用 `bytedance-auth` 重新登录。

---

### 阶段 1：需求澄清 / 信息收集

| Skill | 能力 | 用于 |
|---|---|---|
| `bytedance-cloud-docs` | 搜索和获取字节内部云文档 | 查历史方案、技术背景、业务文档 |
| `feishu-cli-search` | 飞书文档、消息、应用搜索 | 找相关文档、查历史讨论 |
| `feishu-cli-read` | 读取飞书文档内容，转 Markdown | 读背景文档 |
| `ai-coding-radar` | AI Coding 领域情报（技术趋势） | 调研外部方案 |

---

### 阶段 2：PRD 生成（MVP 阶段仅用 Markdown）

**MVP 无依赖外部 skill**。纯 Markdown 生成，由 `prd-generation` skill 自身完成。

**未来扩展**（非 MVP）：
- `feishu-cli-import`：Markdown → 飞书文档（带图表、表格自动处理）
- `feishu-cli-perm`：设置协作者、分享权限
- `feishu-cli-write`：增量更新飞书文档

---

### 阶段 3：现状理解

#### 分支 A：brownfield（存量项目）

| Skill | 能力 | 用于 |
|---|---|---|
| `bytedance-codebase` | 代码仓库搜索、MR 管理、Diff 查询、CI Check Run、文件读取 | 跨仓分析、改动点识别 |
| `bytedance-bam` | 服务 PSM 搜索、Method 列表、IDL 版本查询 | 查接口定义、服务依赖 |
| `bytedance-hive` | Hive/ClickHouse/Doris 数据资产发现、字段 Schema、数据血缘 | 数据侧依赖分析 |

#### 分支 B：greenfield（新项目）

| Skill | 能力 | 用于 |
|---|---|---|
| `e2e-web-search` | 行业调研、类似方案搜索 | 调研竞品和行业做法 |
| `bytedance-cloud-docs` | 公司内部文档/方案检索 | 查公司内基建、类似系统 |

---

### 阶段 4：方案设计（SDD 三件套）

**MVP 阶段**：`e2e-solution-design` 不依赖外部 skill 的**主动调用**。它自己生成 Mermaid 源码 + Markdown。

**可选调用**：
| Skill | 能力 | 用于 |
|---|---|---|
| `e2e-architecture-draw` | 同步架构图到飞书白板 | （可选）把 plan.md 里的 Mermaid 发飞书白板 |
| `feishu-cli-msg` | 发 plan.md 附件到话题 | 跨团队方案 review |

产出：`specs/[简称]/{plan.md, task.md, verification.md}` 三件套。

---

### 阶段 5：研发任务与代码改造

| Skill | 能力 | 用于 |
|---|---|---|
| `bytedance-bits` | **创建研发任务（支持多仓 `--change`）**、绑分支、运行流水线、更新泳道、发布工单 | 标准研发流程入口 |
| `bytedance-overpass` | IDL 代码生成（kitex/hertz/lust） | 生成服务端/客户端代码骨架 |
| `bytedance-scm` | 源码管理、版本查询、构建触发、构建日志 | 查发布包版本、触发构建 |

**BITS 关键能力**：
- `--change "service=PSM1,branch=fix/feature1"` 多仓联动（核心价值）
- `--dry-run` 天然 HARD-GATE 机制
- `--json` 结构化输出（必须放在命令前：`bytedcli --json bits ...`）

---

### 阶段 6：远端测试（MVP 阶段）

**MVP 无依赖外部 skill**。`e2e-remote-test` 简化版内置 SSH 脚本，假设代码已在开发机。

**未来扩展**（非 MVP）：
- `bytedance-bits quick-run --wait` —— 云端流水线测试

---

### 阶段 7：部署

| Skill | 能力 | 用于 |
|---|---|---|
| `bytedance-env` | 环境配置列表、TCE/TCC 部署、设备管理、工单查询 | BOE/PPE 环境操作 |
| `bytedance-tce` | **容器平台**（实例管理、扩缩容、WebShell、泳道部署） | 容器级部署、排障 |
| `bytedance-tcc` | **配置中心**（查询、更新、部署、跨站点同步） | 配置变更 |
| `bytedance-bits` | **发布工单创建**（`create-ticket`） | PPE 发布审批流 |
| `bytedance-goofy-deploy` | Goofy 前端部署、Channel 管理、Preview | 前端项目部署 |

**关键路径**：
1. BOE：`bytedance-env` + `bytedance-tce`
2. PPE：`bytedance-bits create-ticket` 走工单流（审批 + 发布）
3. 配置同步：`bytedance-tcc`

---

### 通知与协作（跨阶段）

| Skill | 能力 | 用于 |
|---|---|---|
| `feishu-cli-msg` | 文本、卡片、图片、文件、Reaction、回复 | **所有关键节点通知**（默认优先 Interactive 卡片） |
| `feishu-cli-board` | **飞书白板**（Mermaid/PlantUML 导入、精确绘图） | 画架构图、流程图 |
| `feishu-cli-toolkit` | 电子表格、日历、任务、群聊、Wiki、用户查询 | 综合入口，多模块协同 |
| `feishu-cli-export` | 飞书文档导出 Markdown/PDF/Word | 备份、转换 |
| `bytedance-cloud-ticket` | Cloud Ticket 工单系统（审批、查询） | 非 BITS 的其他工单 |

---

### 可观测性（排障工具，MVP 不强制调用）

虽然 MVP 不做"上线后陪跑"，但以下 skill 是端到端交付过程中**排障的重要资源**：

| Skill | 能力 |
|---|---|
| `bytedance-log` | 日志服务（PSM/LogID/Pod 多维查询、聚类分析） |
| `argos-log` | Argos 日志（logid 精准追踪 + 关键词搜索） |
| `bytedance-apm` | APM 监控（QPS、P99、Redis、Runtime、TLB、TCC、MySQL） |
| `bytedance-cache` | Redis 查询、BigKey 分析、慢日志 |
| `bytedance-rds` | 数据库查询、诊断、BPM 工单 |
| `bytedance-es` | ES DSL 查询、Mapping 管理 |
| `bytedance-bmq` | Kafka Topic、Consumer Group、Lag 查询 |
| `bytedance-tos` | 对象存储 Bucket 管理 |
| `bytedance-netlink` | DNS/TLB 路由查询 |

**建议**：当用户在 PRD 或方案阶段提到"性能问题"、"依赖 XX 系统"时，主动查询对应 skill 补充上下文。

---

### 平台治理与配置

| Skill | 能力 |
|---|---|
| `bytedance-neptune` | 限流配置、稳定性配置、调度配置 |
| `bytedance-settings` | `app_settings` 白名单管理 |
| `bytedance-dkms` | 数据密钥管理（国际化服务） |
| `bytedance-kmsv2` | KMS v2 密钥管理（国际化） |
| `bytedance-iam` | 员工档案查询 |

---

### 数据与 BI

| Skill | 能力 |
|---|---|
| `bytedance-aeolus` | Aeolus BI 平台（Dashboard、数据集、SQL） |
| `bytedance-dorado` | Dorado 数据开发平台（批任务、Hive SQL、任务版本） |

---

### 其他

| Skill | 能力 | 相关性 |
|---|---|---|
| `bytedance-tools` | 字节 bytedcli 系列 skill 的路由入口 | ⚠️ 本项目**不建议**通过它路由，直接调具体 skill 更清晰 |
| `find-skills` | 发现和安装新 Agent Skill | 可作为"扩展能力"的后备 |
| `feishu-cli-doc-guide` | 飞书文档兼容性规范参考 | 被 feishu-cli-import/write/board 引用 |
| `family-travel-planner` | 家庭带宠物自驾游规划 | ❌ 与本项目无关 |
| `openrouter-balance` | OpenRouter 余额查询 + 飞书通知 | ❌ 与本项目无关 |

---

## 引用模式速查表

本项目 14 个新 skill **应该**依赖的已有 skill 清单：

| 新 Skill | 主要依赖 | 可选依赖 |
|---|---|---|
| `adversarial-qa` | 无 | `bytedance-cloud-docs`（查历史方案） |
| `requirement-clarification` | 无 | `feishu-cli-search`（查历史讨论） |
| `prd-generation` | 无 | 无 |
| `e2e-web-search` | 无（内置 web fetch） | `bytedance-cloud-docs` |
| `e2e-codebase-mapping` | `bytedance-codebase` + `bytedance-bam` | `bytedance-hive` |
| `e2e-dev-task-setup` | `bytedance-auth` + `bytedance-bits` | 无 |
| `e2e-remote-test` | 无（内置 SSH 脚本） | 无 |
| `e2e-deploy-pipeline` | `bytedance-env` + `bytedance-tce` + `bytedance-tcc` + `bytedance-bits` | `bytedance-goofy-deploy`（前端） |
| `e2e-code-review-loop` | `bytedance-codebase` + `bytedance-bits` | 无 |
| `e2e-progress-notify` | `feishu-cli-msg` + `feishu-cli-auth` | 无 |
| `e2e-architecture-draw` | `feishu-cli-board` + `feishu-cli-auth` | 无 |
| `e2e-prd-share` | `feishu-cli-msg` + `feishu-cli-auth` | 无 |

---

## 冲突风险说明

本项目 14 个新 skill 名与本地 46 个已有 skill **经过全量对比无命名冲突**。

**命名策略**：
- 编排层 skill 统一加 `e2e-` 前缀
- 对话层 skill 使用独立语义名（`adversarial-qa` 等不与任何 skill 重名）
- Bootstrap 使用长名 `using-end-to-end-delivery`

**加载优先级**：按 OpenClaw 文档，`~/.agents/skills/` 是第 3 优先级目录，新 skill 放进来后会被所有 agent 加载，不影响本地已有 skill 行为。

---

## 附录：46 个 Skill 全量列表

为方便搜索，按字母顺序列出：

```
ai-coding-radar              feishu-cli-export
argos-log                    feishu-cli-import
bytedance-aeolus             feishu-cli-msg
bytedance-apm                feishu-cli-perm
bytedance-auth               feishu-cli-read
bytedance-bam                feishu-cli-search
bytedance-bits               feishu-cli-toolkit
bytedance-bmq                feishu-cli-write
bytedance-cache              find-skills
bytedance-cloud-docs         openrouter-balance
bytedance-cloud-ticket
bytedance-codebase
bytedance-dkms
bytedance-dorado
bytedance-env
bytedance-es
bytedance-goofy-deploy
bytedance-hive
bytedance-iam
bytedance-jwt
bytedance-kmsv2
bytedance-log
bytedance-neptune
bytedance-netlink
bytedance-overpass
bytedance-rds
bytedance-scm
bytedance-settings
bytedance-tcc
bytedance-tce
bytedance-tools
bytedance-tos
family-travel-planner
feishu-cli-auth
feishu-cli-board
feishu-cli-doc-guide
```

---

*本索引由用户本地目录盘点生成，准确性取决于盘点时间点。建议 skill 库变动后重新生成。*
