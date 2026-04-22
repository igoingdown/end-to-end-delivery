# OpenClaw 运行时工具映射 · e2e-solution-design

## 核心工具

本 skill 主要是**文档生成**工作，依赖：
- `bash` 工具 —— 创建目录 `specs/[简称]/`、写入 3 个 Markdown 文件
- 本地文件系统 —— 读 PRD.md / CODEBASE-MAPPING.md，写 plan/task/verification

**可选调用**的底层 skill：
- `e2e-architecture-draw` —— 若用户要求同步画到飞书白板
- `e2e-web-search` —— 新项目模式下的轻量调研
- `bytedance-cloud-docs` —— 新项目模式下查类似方案

## 文件路径约定

OpenClaw 的 workspace 通常是 `~/.openclaw/workspace`。本 skill 的文件放在：

```
<workspace>/
└── specs/
    └── [需求简称]/
        ├── plan.md
        ├── task.md
        └── verification.md
```

**如果 session 里有明确的项目目录**（比如用户说"在项目 X 里做"），优先使用项目目录：

```
<用户项目目录>/
└── specs/
    └── [需求简称]/
        └── ...
```

## Mermaid 源码生成

本 skill **自己生成** Mermaid 源码（不调用 e2e-architecture-draw），理由见方案讨论 Q2 方案 C：
- 架构图是方案设计的**内在能力**
- `e2e-architecture-draw` 专注"飞书白板渲染"，职责分离更清晰

生成时注意：
- 用 Mermaid 标准语法（`graph LR`、`flowchart TD`、`sequenceDiagram` 等）
- 节点名含中文时用 `[中文名]` 包围
- 换行用 `<br/>`
- 关键改动标注 `★`

## 同步到飞书白板

三文档定稿后，Agent 主动询问用户是否要同步画到飞书白板：

```
方案设计完成。是否需要同步把架构图画到飞书白板？
- ✅ "是" → 调 e2e-architecture-draw
- ❌ "否" → 跳过
```

如果是 → 调用 `e2e-architecture-draw` skill，传入 plan.md 中的 Mermaid 源码。

## 话题归档

OpenClaw 下，三文档完成后建议通过 `feishu-cli-msg` 发到话题作为归档：

```
让 feishu-cli-msg 发送 3 个 Markdown 文件附件到话题：
- specs/[简称]/plan.md
- specs/[简称]/task.md  
- specs/[简称]/verification.md
```

话题中的附件方便后续查看和协作。

## 工作目录持久化

**关键约束**：OpenClaw 每个 session 可能有独立 workspace。如果用户在**新的 session**中继续需求：

- 主 Agent 要先搜索：`find ~/.openclaw/workspace -path "*/specs/*/plan.md"`
- 或询问用户上次方案存在哪里

不要假设 specs/ 目录在当前工作目录下就一定存在。

## 失败处理

- 写文件失败（权限/磁盘）→ 告知用户，降级为**仅展示 Markdown 内容**（不写盘）
- Mermaid 源码语法错误 → 降级为文字架构描述，不阻塞主流程
- 用户 HARD-GATE 反复修改（> 3 次）→ 询问是否回退到 PRD 阶段

## 网络依赖

本 skill 核心是文档生成，**不依赖内网**。

依赖内网的场景：
- 新项目模式调 `bytedance-cloud-docs` 查类似方案
- 话题归档调 `feishu-cli-msg`
- 同步到飞书白板调 `e2e-architecture-draw`

离线环境下这些降级为"跳过"即可，不影响核心产出。
