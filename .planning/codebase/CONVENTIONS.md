# Coding Conventions

**Analysis Date:** 2026-04-22

## Style Guide

**Overall style:** The project uses Markdown as its primary "code" format. There is no compiled programming language -- skills are prompt definitions in Markdown frontmatter + prose, Bash scripts for automation, and JSON for configuration. All content is written in Simplified Chinese. The style is prescriptive, direct, and decision-document oriented (not narrative or report-style).

**Core writing principle:** Every sentence must carry information. No filler phrases, no "本项目旨在..." (this project aims to...), no "总的来说" (in summary). See the anti AI-slop norms embedded in every skill.

## Naming Conventions

### Files

| Pattern | Example | Notes |
|---|---|---|
| `SKILL.md` | `skills/adversarial-qa/SKILL.md` | The one mandatory entry file per skill |
| `SKILL.md.bak` | `skills/e2e-dev-task-setup/SKILL.md.bak` | Backup of superseded skill file |
| `<type>-<name>.md` | `references/question-banks.md` | Markdown reference files kebab-case |
| `run-<action>.sh` | `scripts/run-remote-test.sh` | Executable Bash scripts, kebab-case |
| `<name>.md` | `docs/integration-testing.md` | Documentation files kebab-case |
| `<name>-snippet.json` | `configs/openclaw-snippet.json` | Config fragments kebab-case |

### Skills (Directory Names)

| Prefix | Purpose | Examples |
|---|---|---|
| `e2e-*` | Orchestration and Feishu-layer skills | `e2e-codebase-mapping`, `e2e-progress-notify`, `e2e-prd-share` |
| No prefix | Conversation-layer skills (unique semantic names) | `adversarial-qa`, `requirement-clarification`, `prd-generation` |
| `bytedance-*` | Pre-existing ByteDance internal skills (NOT modified) | `bytedance-codebase`, `bytedance-bits` |
| `feishu-cli-*` | Pre-existing Feishu CLI skills (NOT modified) | `feishu-cli-msg`, `feishu-cli-board` |

**Naming rule for new skills:** Use `e2e-` prefix for all orchestration/platform-layer skills to avoid collision with the 46 pre-existing skills in `~/.agents/skills/`. Conversation-layer skills use unique semantic names verified against the existing inventory (see `docs/existing-skills-inventory.md`).

### Variables and Functions (inside SKILL.md references)

Variables in skill descriptions reference environment variables, not code variables. The convention is:
- Environment variables: `${HOME}`, `$SOURCE_DIR`, `$TARGET_DIR` (Bash style)
- Parameters: `--host`, `--dry-run`, `--force`, `--timeout` (POSIX long-form flags)

### Types and Concepts

- Status values use English uppercase: `DONE`, `BLOCKED`, `NEEDS_CONTEXT`, `DONE_WITH_CONCERNS`
- Hard constraint markers: `<HARD-GATE>` XML-style tags
- Severity markers: `★` (core change), `◇` (affected), `⚠️` (warning), `✅`/`❌` (pass/fail)
- Change types: `NEW`, `MODIFY`, `REFACTOR`

## Code Organization

### Skill Directory Structure (Mandatory)

Every skill follows this layout:

```
skills/<skill-name>/
├── SKILL.md                    # Required. Frontmatter + prose definition.
└── references/                 # Required (may be empty). Runtime-specific details.
    ├── openclaw-tools.md       # OpenClaw runtime tool mappings
    ├── traе-tools.md           # Trae runtime tool mappings
    └── [additional].md         # Topic-specific reference files
```

Complex skills may also include:

```
skills/<skill-name>/
├── SKILL.md
├── references/
└── scripts/                    # Executable scripts.
    └── run-*.sh                # Must have +x permission.
```

### Reference File Naming

- Each skill's `references/` directory separates OpenClaw and Trae runtime tool mappings into distinct files (`openclaw-tools.md` and `traе-tools.md`)
- Topic-specific reference files (e.g., `question-banks.md`, `writing-patterns.md`, `moscow-templates.md`) live alongside runtime mappings and are referenced from within the skill's SKILL.md
- References are read-on-demand by the Agent, not loaded into context at startup (progressive disclosure pattern)

### Document Placement

- `docs/` holds project-level documentation (architecture, integration guides, skill maps)
- `configs/` holds runtime configuration snippets
- `skills/` holds all deliverable skill content
- The root `AGENTS.md` is the Agent personality definition

## Documentation Standards

### Markdown Structure

Every SKILL.md uses this structure:

1. **YAML frontmatter** (3 fields minimum):
   ```yaml
   ---
   name: <skill-name>
   description: "<300+ character trigger description>"
   ---
   ```

2. **H1 heading** with skill full name
3. **Positioning section** (定位) -- what this skill does and does not do
4. **Preconditions** (前置条件) -- checklist of requirements to enter the skill
5. **Core workflow** (核心工作流) -- ASCII flowchart of steps
6. **Step details** (步骤详解) -- deep dive into each step
7. **Output format** (产出物格式) -- template for generated artifacts
8. **Collaboration** (和其他 skill 的协同) -- input sources and output consumers
9. **Failure handling** (失败处理) -- enumerated failure modes and recovery
10. **Anti AI-slop** (反 AI-slop 规范) -- banned phrases and patterns
11. **References** (参考资料) -- links to reference files
12. **Self-check** (自检清单) -- checklist to run before each response

### PRD Standards

PRDs follow a fixed template (see `skills/prd-generation/SKILL.md`):
- One-line summary (max 30 characters)
- Why (business value, user pain points, cost of not doing)
- What (Must/Should/Could/Won't)
- Out of scope
- Acceptance criteria (5 categories: functional, performance, security, data, anomaly)
- Risks and dependencies
- Release plan
- Open questions

### Writing Tone

- Decision-document style: direct conclusions, trade-offs, recommendations
- Engineer-to-engineer style: specific, numeric, verifiable
- Falsifiable claims: "this will improve retention by 2%" not "this will significantly improve user experience"
- Concrete examples over abstract concepts

## Error Handling Patterns

### In Bash Scripts

```bash
set -u                     # Exit on undefined variables
exit 10 / 11 / 20 / 30 / 40 / 50   # Distinct exit codes per error type
```

Markers wrap error output for programmatic parsing:
- `[SSH_FAILED]` -- SSH connectivity failure
- `[DIR_NOT_FOUND]` -- Remote directory missing
- `[BUILD_FAILED]` -- Compilation failure
- `[TEST_FAILED]` -- Test failure
- `[TIMEOUT]` -- Execution timeout
- `[UNKNOWN_ERROR]` -- Unexpected exit code

### In Skill Definitions

Each skill has a dedicated "失败处理" (failure handling) section that covers:
- Named failure modes (A, B, C...)
- Step-by-step diagnostic procedure
- Return state to main Agent (`BLOCKED`, `NEEDS_CONTEXT`, `DONE_WITH_CONCERNS`)
- Escalation to user when self-diagnosis fails

### HARD-GATE Mechanism

All write operations use a mandatory confirmation gate wrapped in `<HARD-GATE>...</HARD-GATE>`:
1. Execute with `--dry-run` (show full payload)
2. Ask user explicitly for confirmation
3. Wait for explicit keyword ("确认", "go", "可以", "执行")
4. Retry without `--dry-run`

Each HARD-GATE is independent; they cannot be merged into a single bulk confirmation.

## Logging Patterns

### In Bash Scripts

Color-coded output:
```bash
RED='\033[0;31m'    GREEN='\033[0;32m'    YELLOW='\033[0;33m'    BLUE='\033[0;34m'
info()    { echo -e "${BLUE}[info]${NC} $*" }
success() { echo -e "${GREEN}[ok]${NC} $*" }
warn()    { echo -e "${YELLOW}[warn]${NC} $*" }
error()   { echo -e "${RED}[error]${NC} $*" >&2 }
```

Progress indicators: `[step 1/4]`, `[step 2/4]`, etc.

### In Agent Responses

Agent announces skill invocations before executing: `🔧 正在使用 [skill-name]，目的：[one-line goal]`

Sub-Agent states form a four-state protocol: `DONE` | `DONE_WITH_CONCERNS` | `BLOCKED` | `NEEDS_CONTEXT`

## Configuration Patterns

### Install Script Conventions

`install.sh` uses parameter-driven configuration:
```bash
./install.sh             # Install or update
./install.sh --dry-run   # Preview only
./install.sh --force     # Overwrite on conflict
./install.sh --uninstall # Remove installed skills
```

- Source: `skills/` (development directory)
- Target: `~/.agents/skills` (production directory)
- Named conflict detection before any file operations
- Idempotent: re-running updates existing skills, adds new ones

### Skill Complexity Classification

| Simple | Complex |
|---|---|
| 1-3 steps, single-file | 4+ steps, loops, branching |
| Read-only / dialog only | Write operations with side effects |
| Stateless | Maintains intermediate state |
| Need no human card-point | Has HARD-GATEs |

See the "Skill Complexity Decision Matrix" in `README.md` for full rules.

### Environment Requirements

| Component | Minimum | Notes |
|---|---|---|
| Node.js | 22.16+ | For OpenClaw runtime |
| OpenClaw | Latest stable | 2026+ recommended |
| Trae IDE | Agent Skills support | Latest version |
| Model | Qwen 3.6 Plus | GLM 5.1 as fallback |
| SSH | Installed, configured | For remote testing |

Credentials are managed by dedicated skills (`bytedance-auth`, `feishu-cli-auth`). Token values are stored in standard tool directories (`~/.bytedance/`, `~/.feishu-cli/`, `~/.openclaw/`).

---

*Convention analysis: 2026-04-22*
