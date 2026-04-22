# Architecture

## Overview

This project is an **End-to-End Delivery AI Agent** composed of 13 Skills that orchestrate a full software delivery lifecycle -- from a vague user idea through requirement clarification, PRD generation, solution design, code implementation, remote testing, and deployment to BOE/PPE. It runs on two platforms: **Trae IDE** (for developers) and **OpenClaw + Feishu topic** (for non-technical users).

The project does not build lower-level capabilities from scratch. It **weaves** together 13 new orchestration/conversation skills with 46 pre-existing local skills (`bytedance-*`, `feishu-cli-*`, etc.) that interface with ByteDance's internal platforms (BITS, TCE, TCC, BAM, Feishu OpenAPI).

## Design Patterns

- **Weave-not-Build**: The project creates no infrastructure capabilities. It composes 13 glue-layer skills on top of 46 pre-existing skills. Each new skill declares which existing skills it calls via the `references/` directory, keeping the orchestration stable against changes in underlying implementations.
- **HARD-GATE (Safety Gate)**: All write operations require mandatory `--dry-run` preview followed by explicit user confirmation before execution. Gates are placed at: PRD finalization, plan/task/verification document finalization, code merge (per-MR), BOE deployment, config sync, and PPE ticket creation. Gates cannot be batched ("one-click confirm all" is rejected).
- **Sub-Agent Four-State Protocol**: When spawning parallel Sub-Agents (used only in `e2e-code-review-loop` at `skills/e2e-code-review-loop/SKILL.md`), each returns one of: `DONE`, `DONE_WITH_CONCERNS`, `BLOCKED`, `NEEDS_CONTEXT`. The main agent dispatches based on the returned state and never assumes success.
- **Living Documents**: Three spec documents (`plan.md`, `task.md`, `verification.md`) are created once by `e2e-solution-design` and subsequently consumed/updated by downstream skills. `task.md` checkboxes are updated by the main agent only (not Sub-Agents) to avoid concurrent conflicts. `verification.md` chapters have fixed owners.
- **Skill Complexity Classification**: Skills are classified as Simple (pure dialogue/read-only, 1-3 steps) or Complex (write operations, loops, HARD-GATEs, cross-skill orchestration). Classification drives whether `--dry-run` and user confirmation are required.

## Component Diagram

```
┌─────────────────────────────────────────────────┐
│  User Entry                                      │
│  Trae IDE (研发) / OpenClaw + Feishu (非研发)    │
└────────────┬────────────────────┬────────────────┘
             │                    │
━━━━━━━━━━━━━▼━━━━━━━━━━━━━━━━━━━━▼━━━━━━━━━━━━━━
│  Agent Runtime: AGENTS.md (人格)                 │
│  AGENTS.md @ /Users/bytedance/github/            │
│  end-to-end-delivery/AGENTS.md                   │
└────────────┬────────────────────┬────────────────┘
             │                    │
━━━━━━━━━━━━━▼━━━━━━━━━━━━━━━━━━━━▼━━━━━━━━━━━━━━
│  Bootstrap: using-end-to-end-delivery            │
│  skills/using-end-to-end-delivery/SKILL.md        │
│  1% rule + 宣布协议 + HARD-GATE + Sub-Agent四态  │
└────────────┬────────────────────────────────────┘
             │
━━━━━━━━━━━━━▼━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
│  Conversation Layer (对话层)                      │
│  adversarial-qa, requirement-clarification,      │
│  prd-generation, e2e-web-search                  │
└────────────┬────────────────────────────────────┘
             │ (PRD.md produced)
━━━━━━━━━━━━━▼━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
│  Solution Design (方案设计)                       │
│  e2e-solution-design                             │
│  skills/e2e-solution-design/SKILL.md              │
│  → specs/[需求简称]/plan.md/task.md/verification  │
└────────────┬────────────────────────────────────┘
             │ (specs consumed)
━━━━━━━━━━━━━▼━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
│  Code Execution Layer (代码执行层)                │
│  e2e-dev-task-setup, e2e-code-review-loop        │
│  → Sub-Agent parallel task execution             │
└────────────┬────────────────────────────────────┘
             │ (verification.md §1 §2 consumed)
━━━━━━━━━━━━━▼━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
│  Testing Layer (测试层)                           │
│  e2e-remote-test                                 │
│  skills/e2e-remote-test/scripts/run-remote-test.sh│
└────────────┬────────────────────────────────────┘
             │ (verification.md §3 §4 consumed)
━━━━━━━━━━━━━▼━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
│  Deployment Layer (部署层)                        │
│  e2e-deploy-pipeline                             │
│  skills/e2e-deploy-pipeline/SKILL.md              │
│  → bytedance-env + tce + tcc + bits              │
└────────────┬────────────────────────────────────┘
             │
━━━━━━━━━━━━━▼━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
│  Cross-cutting (贯穿性)                           │
│  e2e-progress-notify, e2e-architecture-draw,     │
│  e2e-prd-share                                   │
└────────────┬────────────────────────────────────┘
             │
━━━━━━━━━━━━━▼━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
│  Existing Skills (本地已有 46 个)                  │
│  bytedance-*, feishu-cli-*, others               │
└────────────┬────────────────────────────────────┘
             │
━━━━━━━━━━━━━▼━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
│  Underlying Platforms (底层平台)                   │
│  BITS / TCE / TCC / BAM / Feishu API / Hive / ... │
└──────────────────────────────────────────────────┘
```

## Layer Structure

The system follows a 6-layer architectural model:

### Layer 0: Underlying Platforms
- **Purpose**: ByteDance's internal DevOps platforms and Feishu OpenAPI
- **Services**: BITS (dev tasks/tickets), TCE (container platform), TCC (config center), BAM (service IDL), Feishu messaging/docs/board APIs
- **Accessed via**: `references/trae-tools.md` and `references/openclaw-tools.md` in each skill

### Layer 1: Existing Skills (46 pre-installed)
- **Purpose**: Reusable atomic capabilities (auth, codebase search, deployment, messaging)
- **Location**: `~/.agents/skills/` (not modified by this project)
- **Key examples**: `bytedance-auth`, `bytedance-codebase`, `bytedance-bits`, `bytedance-tce`, `bytedance-tcc`, `feishu-cli-msg`, `feishu-cli-board`
- **Referenced skill inventory**: `docs/existing-skills-inventory.md`

### Layer 2: Weaving Layer Skills (13 new skills)
- **Location**: `skills/` directory in this project
- **Sub-layers**:
  - **Conversation Layer (4)**: `adversarial-qa`, `requirement-clarification`, `prd-generation`, `e2e-web-search` -- dialogue-stage skills for clarification and PRD creation
  - **Orchestration Layer (5)**: `e2e-codebase-mapping`, `e2e-dev-task-setup`, `e2e-remote-test`, `e2e-deploy-pipeline`, `e2e-code-review-loop` -- operational workflow skills
  - **Feishu Layer (3)**: `e2e-progress-notify`, `e2e-architecture-draw`, `e2e-prd-share` -- collaboration/notification skills
- **Bootstrap (1)**: `using-end-to-end-delivery` -- read at every session start, defines the main flow

### Layer 3: Agent Personality
- **Location**: `AGENTS.md` at project root
- **Purpose**: Defines the Agent's role as an "End-to-End Delivery Manager", its responsibilities, core principles, work mode constraints (1% rule, HARD-GATE, four-state protocol, anti-AI-slop, runtime adaptation)

### Layer 4: Agent Runtime
- **Trae IDE**: Loads skills via MCP or Trae's skill search path mechanism
- **OpenClaw Gateway**: Loads skills via `skills.load.extraDirs` pointing to `~/.agents/skills/`

### Layer 5: User Entry
- **Trae IDE**: Developer opens a project, interacts via chat panel
- **OpenClaw + Feishu**: User sends message in Feishu topic, OpenClaw Routes to the agent

## Key Abstractions

### Skill
- **Description**: Self-contained module defined by `SKILL.md` with frontmatter (name, description) and optional `references/` and `scripts/` subdirectories
- **Complexity**: Simple (pure dialogue/read-only) or Complex (write operations, loops, HARD-GATEs)
- **Location**: `skills/{skill-name}/SKILL.md`
- **Examples**: `skills/adversarial-qa/SKILL.md`, `skills/e2e-deploy-pipeline/SKILL.md`

### HARD-GATE
- **Description**: Mandatory safety checkpoint for all write operations
- **Pattern**: `--dry-run` → show payload → ask user → explicit confirmation → execute
- **Locations**: Defined in AGENTS.md section II, implemented in individual SKILL.md files using `<HARD-GATE>...</HARD-GATE>` markers
- **Examples**: PRD finalization, BOE deployment (see `skills/e2e-deploy-pipeline/SKILL.md` lines 101-119)

### Living Documents (三活文档)
- **Description**: Three Markdown files created by `e2e-solution-design` and consumed/updated by downstream skills
- **Files**: `specs/[需求简称]/plan.md`, `specs/[需求简称]/task.md`, `specs/[需求简称]/verification.md`
- **Single-creation principle**: Only `e2e-solution-design` creates these files; other skills only consume or update existing fields
- **Defined in**: `skills/e2e-solution-design/SKILL.md` section 三阶段工作流

### Project Type Branching
- **Description**: At stage 3, the system identifies whether this is a brownfield (existing codebase), greenfield (new project), or ambiguous project, then branches accordingly
- **Brownfield** → `e2e-codebase-mapping` → `CODEBASE-MAPPING.md`
- **Greenfield** → `e2e-web-search` + `bytedance-cloud-docs` → lightweight research brief
- **Ambiguous** → HARD-GATE asks user directly
- **Location**: `using-end-to-end-delivery/SKILL.md` section 三

### References Pattern (Runtime Adaptation)
- **Description**: Each non-trivial skill contains `references/trae-tools.md` and `references/openclaw-tools.md` to map tool commands between the two runtimes
- **Location**: e.g., `skills/e2e-remote-test/references/trae-tools.md`, `skills/e2e-remote-test/references/openclaw-tools.md`

## Data Flow

### Primary Flow: 7 Stages

```
Stage 1: Requirement Clarification
  User input → adversarial-qa (5/5 intensity) → requirement-clarification
  → Core requirements consensus (no file output, conversation artifact)

Stage 2: PRD Generation
  PRD.md ← prd-generation (gather → refine → reader-test) → HARD-GATE

Stage 3: Understanding Current State (branching)
  Brownfield → e2e-codebase-mapping → CODEBASE-MAPPING.md
  Greenfield → e2e-web-search + cloud-docs → research brief

Stage 4: Solution Design
  e2e-solution-design → specs/[需求简称]/{plan.md, task.md, verification.md}
  → HARD-GATE × 3 (plan, task, verification each confirmed separately)

Stage 5: Code Implementation
  e2e-dev-task-setup → 1 BITS task
  e2e-code-review-loop → Sub-Agent parallel execution per task.md entry
  → task.md checkbox updated by main agent [ ] → [x]
  → N MRs → HARD-GATE: confirm each MR merge

Stage 6: Remote Testing
  e2e-remote-test → scripts/run-remote-test.sh (SSH to dev machine)
  → verification.md §1 §2: Status updated (pending → passed/failed)
  → Pass → Stage 7; Fail → rollback to Stage 5

Stage 7: Deployment
  e2e-deploy-pipeline → 3 sub-stages:
    7.1 BOE deploy (bytedance-tce) → HARD-GATE ①
    7.2 Config sync (bytedance-tcc) → HARD-GATE ②
    (user validates on BOE)
    7.3 PPE ticket (bytedance-bits create-ticket) → HARD-GATE ③
  → verification.md §3 §4 updated → human fills §5 UAT
```

### Cross-cutting Flow

- `e2e-progress-notify` fires at every critical stage transition (PRD finalized, BITS task created, MRs merged, test failed, BOE deployed, PPE ticket created, stage blocked) → calls `feishu-cli-msg`
- `e2e-architecture-draw` called optionally after stage 4 to visualize plan.md on Feishu whiteboard → calls `feishu-cli-board`
- `e2e-prd-share` sends PRD to Feishu topic after stage 2 → calls `feishu-cli-msg`

### Living Document Data Flow

```
Stage 4: solution-design
  │
  ├─ plan.md          ← initialized, static after finalization
  ├─ task.md          ← initialized, checkboxes updated by code-review-loop
  └─ verification.md  ← initialized, results filled by remote-test/deploy
       │
       ▼
Stage 5: code-review-loop → reads task.md entries, updates checkboxes
       │
       ▼
Stage 6: remote-test → reads verification §1 §2 AC → writes Status/Results
       │
       ▼
Stage 7: deploy-pipeline → reads verification §3 §4 AC → writes Status/Results
       │
       ▼
Human fills §5 UAT → Delivery complete
```

## State Management

This system is fundamentally **prompt-driven and conversation-based**, not a traditional application with runtime state. State is managed through:

- **Markdown files** as durable state: `PRD.md`, `CODEBASE-MAPPING.md`, and `specs/[需求简称]/{plan.md, task.md, verification.md}` serve as the system's shared memory across stages and between skills
- **Conversation history** as transient state: The dialogue context (Feishu topic messages or Trae IDE chat) carries the conversation thread
- **task.md as a living checklist**: The `[ ]` → `[x]` checkbox pattern tracks code implementation progress. Updated exclusively by the main agent after each Sub-Agent returns its state
- **verification.md as a living status report**: Each section's `Status` field (`pending` → `running` → `passed`/`failed`) tracks verification progress. Written by the responsible skill's owner (remote-test for §1/§2, deploy-pipeline for §3/§4, human for §5)
- **No database, no session store**: All persistent state lives in Markdown files on the filesystem. The system is stateless between invocations; resumption is based on reading existing documents

## Concurrency Model

- **Main Agent is single-threaded**: Stages are processed sequentially by default. HARD-GATEs act as synchronization points that block progression until user confirmation
- **Sub-Agent parallelism**: Only `e2e-code-review-loop` spawns concurrent Sub-Agents (one per `task.md` entry) via `sessions_spawn` in OpenClaw
  - Each Sub-Agent has an independent context and model session
  - Sub-Agents are given restricted tool whitelists (no deployment or notification permissions)
  - Maximum concurrency recommended at 3 concurrent Sub-Agents with 30-minute timeout (configurable in OpenClaw config)
  - In Trae IDE, concurrent execution is degraded to serial processing due to limited multi-agent support
- **No shared mutable state between Sub-Agents**: Each Sub-Agent receives only its task entry's data. `task.md` updates are performed by the main agent after Sub-Agent completion, not by Sub-Agents themselves (prevents write conflicts)

## Extension Points

### Adding New Skills
- Place new skill in `skills/{new-skill-name}/` with `SKILL.md` containing frontmatter (`name`, `description`)
- If the skill needs runtime-specific tool mappings, add `references/trae-tools.md` and `references/openclaw-tools.md`
- If the skill needs executable scripts, place in `scripts/` subdirectory
- Run `./install.sh` to sync to `~/.agents/skills/`
- Naming convention: use `e2e-` prefix for orchestration-layer skills, or unique semantic names for conversation-layer skills

### Extending the 7-Stage Flow
- New stages can be inserted between existing stages. The Bootstrap skill (`using-end-to-end-delivery/SKILL.md`) defines the main flow sequence and must be updated
- New stages should consume or produce Markdown artifacts to integrate with the living document system

### Adding New Trigger Words
- Each Skill's description (frontmatter) contains trigger phrases. The LLM routes to skills based on semantic matching with user input
- To improve trigger rate, add synonym variations to the description. Chinese descriptions may have lower trigger accuracy with some models; include English trigger variants

### Runtime Extensions
- The `references/` pattern allows each skill to support new platforms by adding `${platform}-tools.md` files
- Currently supports `trae-tools.md` and `openclaw-tools.md` for the two primary runtimes

---

*Architecture analysis: 2026-04-22*
