# Trae 运行时工具映射 · e2e-solution-design

## Trae 下的核心优势

**方案设计是 Trae 最擅长的场景**：
- Trae 是 IDE，可以直接读项目里的现有代码（不用走 `bytedance-codebase` 远程）
- Markdown 预览器能实时渲染 Mermaid
- 三个文件直接在 IDE 里可编辑、可 Git 管理

## 文件路径约定

Trae 下用户有明确的项目 workspace（就是当前打开的项目）。本 skill 的文件放在**项目根目录下**：

```
<当前 Trae 项目>/
└── specs/
    └── [需求简称]/
        ├── plan.md
        ├── task.md
        └── verification.md
```

这样三个文件可以**随代码一起 Git commit**，符合 Kiro 的最佳实践（specs 应该版本化管理）。

## Mermaid 预览优势

Trae 的 Markdown 预览器原生支持 Mermaid。用户打开 plan.md，直接看到渲染后的架构图。

本 skill 在 Trae 下生成 Mermaid 源码后，**不需要同步到飞书白板**（除非用户明确要求）：
- 研发在 Trae 里看源码渲染就行
- 飞书白板主要面向**非研发同学**（PM、运营）review

## 直接读本地代码

新项目轻量调研时，Trae 可以**直接读本地已有仓库的代码**作为参考：

```
Agent 在 Trae 下：
- 扫描当前 workspace 的 go.mod / package.json，识别技术栈
- 在项目里搜类似功能的现有实现（用 IDE grep）
- 不需要调 bytedance-codebase 远程搜
```

这比 OpenClaw 更快、更准。

## 实时协作

Trae 用户在 IDE 里 review plan.md 时，可以**直接编辑**。

Agent 的 HARD-GATE 可以简化为：
```
plan.md 已生成。
请在 IDE 里 review 并修改（如需要）。
修改完后告诉我 "go"，我继续生成 task.md。
```

这比 OpenClaw（用户只能文字回复）体验好。

## Git 集成

Trae 能直接用 Git。三文档生成后可以一键 commit：

```
Agent 完成三文档后：
"建议：git add specs/ 并 commit，方便后续追溯和回滚。
是否需要我帮你执行？"
```

OpenClaw 场景不走这套，走话题归档。

## 任务执行的 Trae 优势

`e2e-code-review-loop` 派发 Sub-Agent 执行 task.md 里的任务时，Trae 可以：

- Sub-Agent 直接修改 IDE 打开的文件
- 用户实时看到改动（IDE 的文件变更提示）
- 可以用 Trae 的"撤销"快速 revert

**但本 skill 不直接涉及代码执行**，这是下一阶段 `e2e-code-review-loop` 的事。

## 工具名映射

| 操作 | OpenClaw | Trae |
|---|---|---|
| 创建目录 | `bash mkdir` | IDE 文件树或 `bash` |
| 写 Markdown | `bash > file` 或 `create_file` | IDE 内直接写 |
| 读 PRD/CODEBASE-MAPPING | 通过 workspace 文件系统 | IDE view 工具 |
| 预览 Mermaid | 看源码（无渲染） | IDE Markdown 预览 |

## 轻量模式在 Trae 下的特殊优化

Trae 下轻量模式可以**合并三文档的 HARD-GATE**：

```
三文档已生成到 specs/[简称]/。
请在 IDE 里 review 三个文件：
- plan.md
- task.md
- verification.md

review 完告诉我 "go"。
```

用户在 IDE 里**并排打开**三个文件 review，比 OpenClaw 话题里逐段阅读体验好得多。

## 网络依赖

同 OpenClaw：核心产出不依赖内网，只有**新项目调研**和**同步飞书白板**依赖内网。

Trae 用户如果在外网（家里、差旅），可以完成核心方案设计，回公司再做调研和发布相关工作。
