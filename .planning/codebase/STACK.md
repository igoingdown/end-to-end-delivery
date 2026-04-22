# Technology Stack

**Analysis Date:** 2026-04-22

## Overview

This project is an **AI Agent skill set** (not a traditional application). It delivers end-to-end software delivery capabilities through a collection of Markdown-based skill definitions and shell scripts, designed to run on two runtimes: **OpenClaw** (AI agent gateway with Feishu channel) and **Trae IDE** (ByteDance internal AI IDE). The project introduces 14 new skills that orchestrate 46 pre-existing local skills into a 7-stage delivery pipeline.

## Languages

- **Bash** - The `install.sh` script (329 lines) and `skills/e2e-remote-test/scripts/run-remote-test.sh` handle installation/deployment and SSH-based remote test execution.
- **Markdown** - All 14 skill definitions are pure Markdown files (`SKILL.md`), interpreted by the OpenClaw/Trae runtime as agent instructions. No compiled code exists in this project.
- **JSON5** - Configuration snippets for OpenClaw (`configs/openclaw-snippet.json`) use JSON5 format (supports comments, trailing commas).

## Frameworks & Libraries

- **OpenClaw** (2026+, latest stable) - Primary agent gateway runtime. Loads skills from `~/.agents/skills/` via `skills.load.extraDirs` configuration. Provides Feishu channel integration, `sessions_spawn` for sub-agent dispatch, and skill hot-reload (`skills.load.watch`).
- **Trae IDE** (latest with Agent Skills support) - Secondary runtime for developer-focused workflows. Loads skills via MCP or Trae skill search path configuration.
- **Agent Skills Standard** - Both runtimes implement the open Agent Skills protocol (SKILL.md with YAML frontmatter, `references/` directories, optional `scripts/`).

## LLM Models

- **Qwen 3.6 Plus** (千问 3.6 Plus) - Primary model, hard constraint #6. Model ID: `qwen/qwen-3.6-plus`.
- **GLM-5.1** (智谱) - Fallback model. Model ID: `zhipu/glm-5.1`.

## Runtime Requirements

- **Node.js** 22.16+ (recommended 24.x) - Required for OpenClaw gateway.
- **Bash** 5.x+ - Required for `install.sh` and `run-remote-test.sh`.
- **SSH client** - `e2e-remote-test` skill requires SSH connectivity to remote development machines via `~/.ssh/config`.
- **OpenClaw** installed and gateway functional (for OpenClaw runtime).
- **Trae IDE** with Agent Skills support (for Trae runtime).

## Build Tools

- **No build step** - This is a skill-definition project. Skills are copied directly from `skills/` to `~/.agents/skills/` via `install.sh`.
- **install.sh** - Bash script that syncs 14 skills from development directory (`~/github/end-to-end-delivery/skills/`) to production directory (`~/.agents/skills/`). Supports `--dry-run`, `--force`, and `--uninstall` flags.

## Infrastructure

### Platform Dependencies (via `bytedance-*` skills)

These are external ByteDance internal platforms accessed through pre-existing skills in `~/.agents/skills/`:

- **BITS** - R&D task management, MR/CR system, CI pipelines, release tickets. Accessed via `bytedance-bits` skill with `bytedcli` CLI.
- **TCE** (Container Platform) - Kubernetes container deployment platform for BOE/PPE environments. Accessed via `bytedance-tce` skill.
- **TCC** (Configuration Center) - Configuration management and cross-site sync. Accessed via `bytedance-tcc` skill.
- **BAM** - Service IDL/Method search. Accessed via `bytedance-bam` skill.
- **Hive** - Data asset discovery, schema, lineage. Accessed via `bytedance-hive` skill.
- **Goofy Deploy** - Frontend deployment platform. Accessed via `bytedance-goofy-deploy` skill.
- **Overpass** - IDL code generation (kitex/hertz/lust). Accessed via `bytedance-overpass` skill.
- **SCM** - Source code management, version queries, build triggers. Accessed via `bytedance-scm` skill.
- **Neptune** - Rate limiting and stability configuration. Accessed via `bytedance-neptune` skill.

### Feishu Platform (via `feishu-cli-*` skills)

- **Feishu Messaging API** - Text, cards, images, file messages. Accessed via `feishu-cli-msg`.
- **Feishu Board API** - Whiteboard creation with Mermaid/PlantUML import. Accessed via `feishu-cli-board`.
- **Feishu Docs/Export/Import** - Document read, write, export, import. Accessed via `feishu-cli-read/write/import/export`.
- **Feishu Search** - Document and message search. Accessed via `feishu-cli-search`.
- **Feishu Auth** - OAuth management. Accessed via `feishu-cli-auth`.
- **Feishu Toolkit** - Spreadsheets, calendar, tasks, group chat, wiki. Accessed via `feishu-cli-toolkit`.

### Authentication

- **ByteDance SSO** - Managed via `bytedance-auth` skill (OAuth tokens stored in `~/.bytedance/`).
- **Feishu OAuth** - Managed via `feishu-cli-auth` skill (tokens stored in `~/.feishu-cli/`).
- **JWT tokens** - Multi-region service tokens via `bytedance-jwt` skill.

### Observability (available but not MVP-required)

- **APM** - `bytedance-apm` (QPS, P99, Redis, Runtime, MySQL monitoring).
- **Log Service** - `bytedance-log` (PSM/LogID/Pod queries, clustering analysis).
- **Argos Log** - `argos-log` (logid-precise tracking).
- **Redis** - `bytedance-cache` (BigKey analysis, slow log).
- **RDS** - `bytedance-rds` (database queries, diagnostics).
- **ES** - `bytedance-es` (DSL queries, mapping management).
- **BMQ** - `bytedance-bmq` (Kafka topic, consumer group, lag queries).

## Notable Dependencies

### This Project (14 new skills in `skills/`)

| Skill | Complexity | Type |
|-------|------------|------|
| `using-end-to-end-delivery` | Simple | Bootstrap (meta-skill, read first every session) |
| `adversarial-qa` | Simple | Dialogue (adversarial Q&A) |
| `requirement-clarification` | Simple | Dialogue (MoSCoW structuring) |
| `prd-generation` | Simple | Dialogue (Markdown PRD output) |
| `e2e-web-search` | Simple | Dialogue (web research) |
| `e2e-codebase-mapping` | Simple | Orchestration (cross-repo analysis) |
| `e2e-dev-task-setup` | **Complex** | Orchestration (writes BITS tasks) |
| `e2e-remote-test` | **Complex** | Orchestration (SSH + test execution) |
| `e2e-deploy-pipeline` | **Complex** | Orchestration (deploys + tickets) |
| `e2e-code-review-loop` | **Complex** | Orchestration (Sub-Agent parallel loop) |
| `e2e-solution-design` | **Complex** | Orchestration (SDD plan/task/verification) |
| `e2e-progress-notify` | Simple | Feishu (progress notifications) |
| `e2e-architecture-draw` | Simple | Feishu (architecture diagrams) |
| `e2e-prd-share` | Simple | Feishu (PRD sharing) |

### Existing Local (46 skills in `~/.agents/skills/`)

30+ `bytedance-*` skills, 13+ `feishu-cli-*` skills, plus utility skills (`ai-coding-radar`, `find-skills`, etc.). Full inventory at `docs/existing-skills-inventory.md`.

## Configuration

### Environment

- **No `.env` files** - The project has no dotenv configuration. All authentication is managed externally via `bytedance-*` and `feishu-cli-*` skills (SSO tokens in `~/.bytedance/`, `~/.feishu-cli/`).
- **OpenClaw configuration** - `~/.openclaw/openclaw.json` needs `skills.load.extraDirs` pointing to `~/.agents/skills`. See `configs/openclaw-snippet.json` for the merge snippet.
- **SSH configuration** - `~/.ssh/config` must contain aliases for remote development machines (required by `e2e-remote-test`).

### File System

- **Development**: `~/github/end-to-end-delivery/` (Git-managed)
- **Production**: `~/.agents/skills/` (cross-agent shared directory, OpenClaw priority 3)

---

*Stack analysis: 2026-04-22*
