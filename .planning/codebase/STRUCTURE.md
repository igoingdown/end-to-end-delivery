# Directory Structure

## Root Layout

```
end-to-end-delivery/
├── AGENTS.md                          # Agent personality / main Prompt (Chinese)
├── README.md                          # Project overview, hard constraints, quick start
├── install.sh                         # Install/update/uninstall script (symlink skills)
├── .gitignore                         # OS/editor/logs/secrets exclusions
├── LICENSE                            # Placeholder (MVP not open-source yet)
│
├── skills/                            # 13 new skills (development source)
│   ├── using-end-to-end-delivery/     # [1] Bootstrap meta-skill
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── skill-composition.md
│   │       └── runtime-and-troubleshooting.md
│   │
│   │                                  # Conversation layer (dialogue-stage only)
│   ├── adversarial-qa/                # [2] Adversarial Q&A (strength 5/5 → 2/5)
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── question-banks.md
│   ├── requirement-clarification/     # [3] Structured clarification (MoSCoW)
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── acceptance-criteria-patterns.md
│   │       └── moscow-templates.md
│   ├── prd-generation/                # [4] PRD generation (Markdown)
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── prd-templates.md
│   │       └── writing-patterns.md
│   ├── e2e-web-search/                # [5] Web research skill
│   │   └── SKILL.md
│   │
│   │                                  # Orchestration layer (operational workflows)
│   ├── e2e-codebase-mapping/          # [6] Cross-repo code analysis
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── openclaw-tools.md
│   │       └── trae-tools.md
│   ├── e2e-dev-task-setup/            # [7] BITS dev task creation
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── openclaw-tools.md
│   │       ├── trae-tools.md
│   ├── e2e-remote-test/               # [8] SSH remote test execution
│   │   ├── SKILL.md
│   │   ├── references/
│   │   │   ├── openclaw-tools.md
│   │   │   └── trae-tools.md
│   │   └── scripts/
│   │       └── run-remote-test.sh     ← SSH test runner
│   ├── e2e-deploy-pipeline/           # [9] BOE deploy + PPE ticket
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── openclaw-tools.md
│   │       └── trae-tools.md
│   ├── e2e-code-review-loop/          # [10] Code review with Sub-Agents
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── openclaw-tools.md
│   │       └── trae-tools.md
│   │
│   │                                  # Feishu layer (collaboration/notification)
│   ├── e2e-progress-notify/           # [11] Progress notifications via Feishu
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── openclaw-tools.md
│   │       └── trae-tools.md
│   ├── e2e-architecture-draw/         # [12] Architecture diagram to Feishu whiteboard
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── openclaw-tools.md
│   │       └── trae-tools.md
│   ├── e2e-prd-share/                 # [13] Share PRD to Feishu topic
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── openclaw-tools.md
│   │       └── trae-tools.md
│   │
│   │                                  # Solution design (Spec-Driven Development)
│   ├── e2e-solution-design/           # [14] Plan + Task + Verification docs
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── plan-template.md
│   │       ├── task-template.md
│   │       ├── verification-template.md
│   │       ├── design-modes.md
│   │       ├── openclaw-tools.md
│   │       └── trae-tools.md
│
├── docs/                              # Project documentation
│   ├── skill-orchestration-map.md     # Full 7-stage flow diagram + stage details
│   ├── architecture.md                # Architecture document
│   ├── existing-skills-inventory.md   # 46 pre-existing skill index
│   ├── integration-trae.md            # Trae IDE integration guide
│   ├── integration-openclaw.md        # OpenClaw + Feishu integration guide
│   └── integration-testing.md         # Smoke test checklist (L1-L4)
│
├── configs/                           # Configuration snippets
│   └── openclaw-snippet.json          # OpenClaw config to merge into ~/.openclaw/openclaw.json
│
└── .planning/                         # Generated planning artifacts (not committed)
```

## Directory Purposes

### `skills/`
- **Purpose**: Source directory for all 13+1 skills created by this project. Each subdirectory is a self-contained Agent skill following the Agent Skills standard.
- **Key Files**: Each skill has a `SKILL.md` entry point with YAML frontmatter (`name`, `description`)
- **Conventions**:
  - Skill names use kebab-case
  - Orchestration-layer skills use `e2e-` prefix
  - Conversation-layer skills use standalone semantic names (`adversarial-qa`, `requirement-clarification`, `prd-generation`)
  - Bootstrap skill uses descriptive name `using-end-to-end-delivery`
  - Each skill's substructure:
    - `SKILL.md` (required) -- main skill definition
    - `references/` (optional) -- supplementary documentation, tool mappings, templates
    - `scripts/` (optional) -- executable scripts (only in `e2e-remote-test`)

### `docs/`
- **Purpose**: Project-level documentation for maintainers and adopters
- **Key Files**:
  - `skill-orchestration-map.md` -- Complete flow diagram, stage-by-stage details, trigger keywords, living document data flow
  - `architecture.md` -- System architecture, layers, component diagram, deployment topology, security model
  - `existing-skills-inventory.md` -- Index of 46 pre-existing local skills, organized by E2E stage, with dependency mapping table
  - `integration-trae.md` / `integration-openclaw.md` -- Platform-specific integration guides
  - `integration-testing.md` -- 4-level smoke test checklist (L1-L4)
- **Conventions**: Markdown files, Chinese-language content, self-documenting with clear section headers

### `configs/`
- **Purpose**: Reusable configuration snippets for runtime integration
- **Key Files**:
  - `openclaw-snippet.json` -- JSON5 config fragment to merge into `~/.openclaw/openclaw.json`
- **Conventions**: JSON5 format (supports comments and trailing commas), designed for partial merge not full replacement

## File Organization Patterns

### Skill Internal Structure (standard pattern)

Every skill follows this consistent layout:

```
skills/{skill-name}/
├── SKILL.md                            # Required: YAML frontmatter + Markdown body
├── references/                         # Optional: supporting documents
│   ├── trae-tools.md                   # Trae tool commands / platform mappings
│   ├── openclaw-tools.md               # OpenClaw tool commands / platform mappings
│   ├── {template}.md                   # Templates for output documents
│   └── ...                             # Additional reference docs
└── scripts/                            # Optional: executable scripts (rare)
    └── *.sh                            # Shell scripts
```

### Naming Conventions

- **Skill directories**: kebab-case, `e2e-` prefix for orchestration skills
  - Examples: `e2e-deploy-pipeline/`, `e2e-codebase-mapping/`
  - Non-e2e skills: `adversarial-qa/`, `prd-generation/`
- **Files within skills**: lowercase with hyphens
  - `plan-template.md`, `question-banks.md`, `run-remote-test.sh`
- **Runtime mapping files**: `{runtime}-tools.md` pattern
  - Always paired: `trae-tools.md` + `openclaw-tools.md` when a skill needs runtime adaptation

### Reference File Organization

Skills with runtime-specific behavior keep parallel files:
- `references/trae-tools.md` -- Trae IDE commands, capabilities, and limitations
- `references/openclaw-tools.md` -- OpenClaw commands, capabilities, and limitations

This keeps each skill portable between the two runtimes without conditional logic in `SKILL.md` itself.

### Document Artifact Conventions

Generated artifacts follow a fixed location pattern:
- **PRD**: `PRD.md` in the project working directory root
- **Codebase mapping**: `CODEBASE-MAPPING.md` in the project working directory root
- **Spec documents**: `specs/[需求简称]/{plan.md, task.md, verification.md}` -- created once by `e2e-solution-design`

## Module Boundaries

### Skill Boundaries

Each skill is a fully independent module:
- Skills do not import or require each other programmatically
- Communication between skills happens through:
  1. **Document artifacts** (e.g., `PRD.md` is created by `prd-generation` and consumed by `e2e-solution-design`)
  2. **LLM-based orchestration** (the Agent decides which skill to call based on description matching)
  3. **Explicit skill calls** (e.g., `e2e-codebase-mapping` internally calls `bytedance-codebase` + `bytedance-bam`)

### Project Boundary

This project owns 14 items in the `skills/` directory and the root `AGENTS.md`. It does not modify the 46 pre-existing skills in `~/.agents/skills/`. The `install.sh` script copies (symlinks or `cp -R`) skills from the development directory to the production directory.

### Runtime Boundary

Skills internalize runtime differences through the `references/` pattern. The `SKILL.md` body describes the skill's logic generically, while `references/trae-tools.md` and `references/openclaw-tools.md` document the specific commands for each runtime. This keeps skills portable without code changes.

## Entry Points

### `AGENTS.md` -- Agent Personality
- **Location**: project root
- **Purpose**: The main prompt that defines the Agent's role, responsibilities, principles, work mode, and hard constraints. Loaded by both Trae and OpenClaw runtimes.
- **Trigger**: Loaded when the project is opened in Trae, or when `AGENTS.md` is symlinked to the OpenClaw workspace.

### `using-end-to-end-delivery/SKILL.md` -- Bootstrap
- **Location**: `skills/using-end-to-end-delivery/SKILL.md`
- **Purpose**: The meta-skill that is read at the start of every end-to-end delivery session. Defines the 7-stage main flow, HARD-GATE mechanism, Sub-Agent four-state protocol, three living document constraints, 1% rule, and announce protocol.
- **Trigger**: Automatically loaded at session start by convention (not by LLM description matching).

### `install.sh` -- Installation
- **Location**: project root
- **Purpose**: Syncs all 13+ skills from `skills/` to `~/.agents/skills/`. Validates preconditions, detects naming conflicts (with `--force` override option), sets executable permissions on scripts. Supports `--dry-run`, `--force`, and `--uninstall` modes.
- **Usage**: `./install.sh` for install/update; `./install.sh --uninstall` for removal.

## Configuration Locations

- **OpenClaw config**: `~/.openclaw/openclaw.json` -- add `skills.load.extraDirs: ["~/.agents/skills"]` (snippet provided in `configs/openclaw-snippet.json`)
- **OpenClaw AGENTS.md mapping**: symlink or copy `AGENTS.md` to `~/.openclaw/workspace/AGENTS.md`
- **Trae skill path**: configured via Trae Settings → Skills / Agent → search path → add `~/.agents/skills`
- **Trae AGENTS.md mapping**: symlink to project root from current project workspace, or configure as Trae Custom Agent
- **ByteDance auth**: `~/.bytedance/` (OAuth tokens)
- **Feishu auth**: `~/.feishu-cli/` (OAuth tokens)
- **OpenClaw API keys**: `~/.openclaw/` (not project-specific)

## Where to Add New Code

### New Skill
- **Create in**: `skills/{new-skill-name}/`
- **Must have**: `SKILL.md` with valid frontmatter (`name`, `description`)
- **Should have**: `references/trae-tools.md` + `references/openclaw-tools.md` if the skill calls runtime-specific tools
- **Naming**: Use `e2e-` prefix for orchestration skills, or a unique semantic name for conversation-layer skills
- **Install**: Run `./install.sh` to sync to `~/.agents/skills/`

### New Reference/Template for Existing Skill
- **Add to**: `skills/{existing-skill-name}/references/{name}.md`
- **Register**: Reference it from the parent `SKILL.md` in the "参考资料" section

### New Scripts
- **Add to**: `skills/{skill-name}/scripts/`
- **Only in**: `e2e-remote-test` currently (the only skill with executable scripts)
- **Convention**: `.sh` extension, set executable permissions in `install.sh` (already handled)

### New Documentation
- **Add to**: `docs/` directory
- **Convention**: Markdown, Chinese, self-documenting

### Configuration Changes
- **Modify**: `configs/openclaw-snippet.json` for OpenClaw config changes
- **Note**: Snippets are merge-friendly, not meant for full replacement

## Special Directories

### `~/.agents/skills/` (Production location)
- **Purpose**: The runtime directory where OpenClaw and Trae load skills from
- **Populated by**: `install.sh` copies from this project's `skills/`
- **Not committed**: This is a user-local directory, outside the project repo
- **Contains**: 13 project skills + 46 pre-existing skills

### `.planning/`
- **Purpose**: Generated planning artifacts (codebase maps, implementation plans)
- **Not committed**: Excluded from version control
- **Contains**: `.planning/codebase/` (this file, ARCHITECTURE.md, etc.)

---

*Structure analysis: 2026-04-22*
