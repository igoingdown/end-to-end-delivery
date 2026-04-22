# Testing

**Analysis Date:** 2026-04-22

## Overview

This project is an AI Agent skill set (Markdown prompts + Bash scripts), not a traditional software application with unit tests. Testing is **integration-focused and manual**, following a layered smoke test approach defined in `docs/integration-testing.md`. The testing philosophy is "key path verification" rather than "full coverage" -- validating that each stage of the delivery workflow executes correctly with real inputs.

## Test Types

### Smoke Tests (Primary Method)

**Framework:** Manual integration testing via `docs/integration-testing.md`

**Approach:** 4-layer progressive verification, executed in order. Each layer must pass before proceeding to the next.

| Layer | Target | Time | Method |
|---|---|---|---|
| **L1: Skill Loading** | 13 skills load correctly | 5 min | `openclaw skills list` + grep |
| **L2: Conversation Skills** | Bootstrap + 4 dialog skills | 20 min | Feishu/Trae conversation with test prompts |
| **L3: Orchestration Skills** | 5 orchestration + Feishu skills | 20 min | Trigger read-only orchestrations |
| **L4: End-to-End** | Full workflow with toy project | 1-2 hr | Complete delivery from requirement to PPE gate |

### L1: Skill Loading Correctness

**Commands:**
```bash
openclaw skills list | grep -E "(e2e-|using-end-to-end|adversarial-qa|requirement-clarification|prd-generation)"
openclaw doctor
```

**Pass criteria:**
- All 13 skills appear in the loaded list
- No red errors from `openclaw doctor`
- Agent is triggerable via `@端到端交付`

**Location:** Tested in `~/.agents/skills/` after running `install.sh`.

### L2: Conversation Layer Testing

**Test scenarios (from `docs/integration-testing.md`):**

1. **2.1 Bootstrap trigger** -- Send `@端到端交付 我有个新想法想聊聊`
   - Expected: Agent engages adversarial QA, asks at least one sharp question
   - Failure: Agent responds generically without triggering `adversarial-qa`

2. **2.2 Adversarial -> Clarification -> PRD flow** -- Provide a multi-turn sample requirement
   - Expected: 5/5 intensity QA -> HARD-GATE -> 2/5 refinement -> MoSCoW -> PRD Markdown
   - Pass criteria: Skill switches announced, HARD-GATE gates hit, PRD fits template

3. **2.3 Anti AI-slop verification** -- Review generated PRD
   - No boilerplate phrases ("总的来说", "赋能业务")
   - Acceptance criteria are specific (numbers, time windows)
   - Out-of-scope lists at least 3 items

4. **2.4 Web research** (optional) -- Ask for industry research
   - Expected: 1-3 searches with source-cited structured output

### L3: Orchestration Layer Testing (Read-Only)

**Test scenarios:**

1. **3.1 Codebase mapping** -- Trigger `e2e-codebase-mapping` with completed PRD
   - Pass: `bytedance-auth` succeeds, relevant repos found, change points marked ★/◇
   - Failure: `CODEBASE-MAPPING.md` has all ◇, no ★

2. **3.2 Architecture diagram** (optional, Feishu) -- Trigger `e2e-architecture-draw`
   - Pass: Mermaid source preview shown, Feishu board created with visible nodes

3. **3.3 PRD share** (optional, Feishu) -- Trigger `e2e-prd-share`
   - Pass: Card + Markdown attachment sent to thread

### L4: End-to-End Full Workflow

**Test scenarios:**

1. **4.1 Dev task creation (HARD-GATE stress test)**
   - Core check: **Task is not created without explicit user confirmation**
   - Payload shown completely, dry-run must precede creation

2. **4.2 Code modification loop (Sub-Agent protocol)**
   - Each Sub-Agent returns one of four states
   - Main Agent acts based on state
   - Loop count ≤ 3

3. **4.3 Remote test** -- Execute `scripts/run-remote-test.sh`
   - SSH connectivity pre-check passes
   - Directory check passes
   - Test report has clear structure (pass/fail count, failure details)

4. **4.4 Deployment HARD-GATE stress test**
   - 3 independent HARD-GATEs (BOE deploy, BOE config sync, PPE ticket creation)
   - Each gate is independent -- "bulk confirm" is rejected
   - Rollback plan shown before PPE gate
   - Agent stops cleanly on "cancel" mid-flow

### Remote Test Script (Automated)

**File:** `skills/e2e-remote-test/scripts/run-remote-test.sh`

**What it does:**
1. SSH connectivity check (5s timeout)
2. Remote directory verification
3. Build execution with marker wrapping
4. Test execution with marker wrapping
5. Structured exit codes

**Usage:**
```bash
bash scripts/run-remote-test.sh \
  --host dev01 \
  --dir /home/tiger/workspace/user-segment-api \
  --build "go build ./..." \
  --test "go test -v ./... -count=1" \
  --timeout 600
```

**Exit codes:**
- `0` -- All passed
- `10` -- SSH connection failed
- `11` -- Remote directory not found
- `20` -- Build failed
- `30` -- Tests failed
- `40` -- Timeout exceeded
- `50` -- Unknown error

**Supported test frameworks:** Go (`go test`), Python (`pytest`), with pattern-based output extraction. Other frameworks fall back to raw stdout.

## Test Data

### Test Requirements

Testing requires:
1. A valid ByteDance SSO login (via `bytedance-auth`)
2. Feishu CLI authentication (via `feishu-cli-auth`)
3. Company VPN connection
4. SSH access to a dev machine with code
5. A "toy requirement" for L4 testing (e.g., add a `/healthz` endpoint)

### Test Prompts

The integration test guide provides specific test prompts for each layer. Example requirement for L2:
```
我们想做个用户分层运营的能力。有的用户活跃度高是 VIP，有的活跃度低。
我们想给运营同学一个后台，能自助配置分层规则。
```

### Test Data Fixtures

No automated fixtures. Test data consists of:
- Reference question banks in `skills/adversarial-qa/references/question-banks.md`
- Acceptance criteria patterns in `skills/requirement-clarification/references/acceptance-criteria-patterns.md`
- PRD writing patterns in `skills/prd-generation/references/writing-patterns.md`
- MoSCoW templates by project type in `skills/requirement-clarification/references/moscow-templates.md`
- PRD templates by project type in `skills/prd-generation/references/prd-templates.md`

## Mocking Strategy

### What Gets Mocked

- **`--dry-run` parameter**: All `bytedance-*` write operations have a native `--dry-run` mode. This is the primary mock mechanism -- previewing payloads without side effects.
- **Test project for L4**: A personal/toy repository is used instead of a production repository.
- **Self-check in PRD generation**: 15-item quality checklist acts as internal validation (mock review).

### What is NOT Mocked

- Feishu interactions -- actual Feishu messages/cards are sent during testing
- SSH connections -- real SSH to real dev machines with real code
- Codebase search -- real `bytedance-codebase` searches against real ByteDance repositories
- BITS task creation -- only the dry-run is mockable; actual creation requires real confirmation

### Mocking by Design

The skill architecture itself provides boundary testing:
- Conversation-layer skills (dialog-only, no side effects) can be tested in isolation
- Orchestration-layer skills can be tested in read-only mode (L3) before write-mode testing (L4)
- The HARD-GATE mechanism acts as a built-in mock/verification layer for all write operations

## CI/CD Integration

### CI Pipeline Status

**No formal CI/CD pipeline** exists for this project. Testing is entirely manual post-installation.

### Git Workflow

- Development occurs in `~/github/end-to-end-delivery/`
- Installation syncs to `~/.agents/skills/` via `install.sh`
- Version control is git-only; no automated CI gate on commits

### Test Execution Schedule

| Event | What to Run |
|---|---|
| Each skill modification | L1 + related skill L2/L3 |
| New skill addition | L1 + custom L2 for new skill |
| Before release | Full L1-L4 |
| Monthly | L1-L3 regression |

See `docs/integration-testing.md` section "持续测试" (continuous testing).

## Known Gaps

### Untested Areas

1. **OpenClaw multi-user scenarios** -- OpenClaw is single-user by design. Shared machine testing (scenario B in architecture.md) has been validated only structurally, not under concurrent load.

2. **Trae runtime Sub-Agent delegation** -- If Sub-Agents need to degrade from parallel to serial in Trae, this fallback path has limited testing.

3. **Skill collision detection on first install** -- The conflict detection in `install.sh` works when 46 existing skills are already present. It has not been tested against a clean `~/.agents/skills/` with completely different skills.

4. **LLM model selection accuracy** -- The skill routing (based on `description` frontmatter) is tested with Qwen 3.6 Plus. Performance on smaller/lighter models is documented as problematic but not quantified.

5. **Cross-runtime session handoff** -- Users completing pre-stages in Trae and continuing via Feishu (described in `references/runtime-and-troubleshooting.md`) has no documented test procedure.

6. **e2e-solution-design skill** -- This core skill (producing `plan.md`, `task.md`, `verification.md`) is referenced extensively but not covered by any concrete test scenario in the integration testing guide.

7. **e2e-code-review-loop Sub-Agent parallelism** -- While the protocol (4-state) is well-documented, concurrent Sub-Agent behavior under network degradation is not tested.

### No Automated Test Coverage

- **No unit tests**: Skills are prompt/Markdown, not code. There is no framework for automated prompt testing.
- **No lint/validate**: No tool verifies SKILL.md frontmatter consistency, reference file existence, or workflow graph correctness.
- **No regression testing**: Skill interaction changes (e.g., modifying `adversarial-qa` intensity switching) require full manual re-verification.
- **No install script tests**: `install.sh` has no automated test (no `bats`, no `shunit2` or equivalent). Manual installation verification only.
- **No Bash script tests**: `scripts/run-remote-test.sh` is tested only through live SSH; no mocked test exists for local validation of its logic.

### Test Priority Recommendation

**High priority:**
- Test `e2e-solution-design` skill end-to-end (L3 equivalent)
- Automate `install.sh` validation (install -> verify skills list -> uninstall)

**Medium priority:**
- Add a mock-mode to `run-remote-test.sh` for local logic validation without SSH
- Create a checklist automation script that verifies all SKILL.md files have required sections

**Low priority:**
- Cross-runtime session handoff test procedure
- OpenClaw multi-user stress test

---

*Testing analysis: 2026-04-22*
