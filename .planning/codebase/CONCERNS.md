# Known Concerns & Risks

**Analysis Date:** 2026-04-22

---

## Technical Debt

- **Zero automated tests**: The entire project has no test files (no `*.test.*`, `*.spec.*`). `docs/integration-testing.md` describes manual smoke test procedures (L1-L4) only. There is no unit, integration, or E2E test automation. Changes to skills, `install.sh`, and scripts rely entirely on ad-hoc manual testing.
  - Files: `install.sh`, `skills/e2e-remote-test/scripts/run-remote-test.sh`, all SKILL.md files
  - Impact: Regressions in skill triggers, HARD-GATE behavior, or install.sh will not be caught until a user hits them in production.

- **Backup artifact left in repo**: `skills/e2e-dev-task-setup/SKILL.md.bak` is an untracked or accidentally-commed backup file. It suggests ad-hoc editing without proper version control hygiene.
  - File: `skills/e2e-dev-task-setup/SKILL.md.bak`
  - Impact: If included in the sync to `~/.agents/skills/`, it may confuse the runtime or get picked up as a valid skill file.

- **MVP still incomplete**: Only 2 commits exist on `main` (`4294fee [fix]新增文本`, `0bcdb15 [fix]新增文本`). The project is in Step 1 of a 4-step delivery plan. Skills described in the architecture (phases 3-7) are documented but not fully implemented or integration-tested.
  - Impact: The orchestration flow from `docs/skill-orchestration-map.md` describes 7 phases, but most exist only as SKILL.md stubs or partial implementations.

- **Orchestration-doc drift risk**: The 7-phase flow in `docs/skill-orchestration-map.md` (v2.0) introduces `e2e-solution-design` with Spec-Driven Development, but the README.md (Step 1 delivered scope) describes only the MVP of "Clarification -> PRD -> Code -> Test -> Deploy". The two documents describe subtly different flows (6 vs 7 phases).
  - Files: `docs/skill-orchestration-map.md` vs `README.md`

---

## Security Concerns

- **HARD-GATE enforcement is prompt-level, not system-level**: The entire write-operation safety model (HARD-GATE, `--dry-run` gates) is implemented as instructions in `AGENTS.md` and SKILL.md files. An LLM that ignores or misinterprets these instructions can execute write operations without user confirmation. There is no programmatic gate preventing direct execution.
  - Files: `AGENTS.md` (lines 129-139), `skills/using-end-to-end-delivery/SKILL.md` (section IV)
  - Severity: **CRITICAL**. The security boundary is "trust the LLM to follow instructions in a Markdown file."

- **`install.sh` destructive sync**: In `do_sync()`, when updating an existing skill, the script does `rm -rf "$dst"` followed by `cp -R "$src" "$dst"` — this is a blind destructive replacement. If the source is corrupted or incomplete between runs, the target skill is destroyed before the copy completes.
  - File: `install.sh` (lines 203-207)
  - Severity: MEDIUM. No backup is created before destructive deletion.

- **SSH key reliance without credential management**: `e2e-remote-test` depends entirely on the user's local `~/.ssh/config` and private keys. The Agent has no independent SSH credential management, meaning compromised local SSH keys give a rogue Agent full access to developer machines.
  - File: `skills/e2e-remote-test/scripts/run-remote-test.sh` (lines 7-9, 100)
  - Severity: MEDIUM. Relies on local SSH security posture.

- **`install.sh --force` is irreversible**: Running `./install.sh --force` will overwrite any local skill with the same name, including non-project skills. The heuristic for detecting "is this already our install?" (`grep -q "端到端交付" "$target_skill_md"`) is fragile — a third-party skill containing the text "端到端交付" would be treated as "already installed" and skipped.
  - File: `install.sh` (lines 162-164)
  - Severity: LOW. Requires explicit `--force` flag, but the detection heuristic is weak.

---

## Performance Risks

- **LLM routing trigger is probabilistic**: Skill triggering relies on LLM semantic matching against SKILL.md `description` fields. Chinese descriptions trigger less reliably with some models. The project explicitly notes ("LLM 路由 skill 偶尔会选错") as a known limitation.
  - Files: `docs/architecture.md` (line 437), `docs/integration-openclaw.md` (lines 307-311)
  - Impact: User says "deploy to BOE" but Agent might trigger the wrong skill, leading to confusion or incorrect actions.

- **Sub-Agent context explosion**: Each Sub-Agent spawned by `sessions_spawn` gets an independent context and model invocation. With `maxConcurrent: 3` and 30-minute timeouts, a complex code review with multiple repos can easily consume significant API quota and take 30+ minutes end-to-end.
  - Files: `docs/integration-openclaw.md` (lines 236-250), `skills/e2e-code-review-loop/`
  - Impact: Expensive and slow. The recommended `maxConcurrent: 3` is arbitrary and may not match actual TPM limits.

- **Qwen 3.6 Plus slow response under large context**: The docs acknowledge that Qwen 3.6 Plus is slow in large-context scenarios. With 13 project skills + 46 local skills all loaded, the context window is likely very large, leading to slow LLM responses.
  - File: `docs/integration-openclaw.md` (line 315)
  - Impact: User-facing latency during every interaction.

- **SSH timeout hardcoded at 600s**: `run-remote-test.sh` defaults to a 600-second timeout for build + test. Large monorepo test suites may exceed this, causing false-negative failures.
  - File: `skills/e2e-remote-test/scripts/run-remote-test.sh` (line 19)

---

## Scalability Limitations

- **OpenClaw is single-user by design**: The architecture explicitly documents that OpenClaw is a single-user product. Multi-user team scenarios require manual workarounds (per-user `--profile` instances or Git submodule sync of `~/.agents/skills/`).
  - Files: `docs/architecture.md` (line 434), `docs/integration-openclaw.md` (lines 356-359)
  - Impact: A team of 5+ developers using a shared OpenClaw Gateway will experience session confusion and credential collisions. No native multi-tenant support exists.

- **No session history persistence across skill flows**: The 7-phase flow depends on the Agent maintaining context across multiple steps (PRD -> codebase mapping -> code review -> test -> deploy). If the session is interrupted (network issue, gateway restart, topic archive), there is no durable state recovery mechanism. Skills reference "three living documents" (`plan.md`, `task.md`, `verification.md`) but there's no checkpoint/restore system.
  - Files: `docs/skill-orchestration-map.md` (section on three living docs), `skills/using-end-to-end-delivery/SKILL.md` (section V)
  - Impact: If a session dies mid-flow, the Agent loses its place and must reconstruct context manually.

- **Trae Sub-Agent degrades to serial**: In the Trae runtime, `e2e-code-review-loop` must fall back to serial execution because Trae's multi-Agent parallelism is less mature than OpenClaw's `sessions_spawn`.
  - File: `docs/integration-trae.md` (line 165)
  - Impact: Code review loops are significantly slower in Trae mode, reducing throughput for multi-repo changes.

---

## Maintenance Challenges

- **Heavy dependency on internal ByteDance platforms**: The project depends on ~30 internal ByteDance skills (`bytedance-*`) and ~13 Feishu skills (`feishu-cli-*`). These are external to this repo, may change independently, and their APIs are not version-locked. Any breaking change in `bytedance-bits`, `bytedance-tce`, or `bytedance-tcc` cascades directly into this project.
  - Files: `docs/existing-skills-inventory.md` (all listed skills)
  - Impact: High external surface area. The "weave, don't build" philosophy is a double-edged sword — stability depends on 46 external components.

- **Trae is an internal tool with unstable APIs**: `docs/integration-trae.md` explicitly notes "Specific Trae version APIs may differ; refer to Trae's latest docs." The integration instructions are intentionally vague because Trae is internal and its API surface changes.
  - File: `docs/integration-trae.md` (line 5, lines 48-55 with "(specific UI path depends on version, below is illustrative)")
  - Impact: Integration docs may drift quickly with Trae updates. Maintainers must manually verify against each Trae release.

- **Language barrier**: The entire codebase (AGENTS.md, README.md, all SKILL.md files, all docs, install.sh comments) is in Chinese (with some English). This limits the contributor base to Chinese-speaking ByteDance developers only.
  - Impact: No external contributors; knowledge transfer to non-Chinese-speaking team members is blocked.

- **Fragile skill conflict detection in `install.sh`**: The heuristic `grep -q "端到端交付" "$target_skill_md"` to determine whether a skill is "installed by this project" is fragile. A future non-project skill that mentions "端到端交付" (end-to-end delivery) in its description would be falsely marked as "already installed" and skipped during sync.
  - File: `install.sh` (lines 162-164, 292-294)

---

## Single Points of Failure

- **`AGENTS.md` is the single personality file**: The entire Agent behavior, safety gates, skill usage protocols, and communication style are defined in a single 223-line file (`AGENTS.md`). If this file is not loaded (e.g., symlink broken, workspace misconfigured), the Agent loses all safety constraints and behavioral rules.
  - File: `AGENTS.md`
  - No fallback personality or degraded mode exists.

- **`e2e-solution-design` is the only skill initializer for living documents**: `plan.md`, `task.md`, and `verification.md` can only be created by `e2e-solution-design`. If this skill fails, no other skill can bootstrap the spec artifacts, blocking phases 5-7 entirely.
  - File: `skills/e2e-solution-design/SKILL.md`
  - Referenced constraint: `skills/using-end-to-end-delivery/SKILL.md` (section V)

- **OpenClaw Gateway is the sole production runtime for Feishu**: All Feishu-based interactions route through a single OpenClaw Gateway instance. If it crashes, Feishu topics lose the Agent entirely until restart.
  - File: `docs/architecture.md` (section 7)

---

## Dependency Risks

- **Node.js 22+ required**: The project requires Node.js 22.16+ (recommended 24.x) for OpenClaw. This is a relatively new LTS requirement that may not be available on all developer machines.
  - File: `docs/architecture.md` (line 445)

- **No dependency lock or version pinning**: There is no `package.json`, `package-lock.json`, or any version pinning for OpenClaw, Trae, or the internal ByteDance skill ecosystem. The project assumes "latest stable" for all runtimes.
  - Impact: Breaking changes in any upstream dependency can cause immediate failure.

- **Qwen 3.6 Plus / GLM-5.1 as mandatory models**: The project hardcodes these specific models. If either model is deprecated, rate-limited, or becomes unavailable, the Agent cannot function.
  - Files: `README.md` (hard constraint #6), `AGENTS.md` (hard constraint #4)
  - Impact: Only 2 supported models; both are specific versions with potential deprecation risk.

---

## Operational Concerns

- **No CI/CD pipeline for the skills repo**: Changes to this repository are manual — there is no CI to validate that `install.sh` works, that SKILL.md files are syntactically valid (frontmatter exists), or that all 13 skills are present in the `PROJECT_SKILLS` array in `install.sh`.
  - Impact: A broken commit can silently introduce defects that only surface on manual install.

- **No monitoring or observability for the Agent itself**: There is no structured logging, no error tracking, no metrics collection (e.g., how often skills are triggered, how often HARD-GATE is honored, session success/failure rates). The only "observability" is the user seeing errors in their chat.
  - Impact: Maintainers are flying blind. They cannot detect widespread skill routing failures or HARD-GATE bypasses without user reports.

- **No rollback mechanism**: If a user encounters issues after installing new skill versions, the only rollback is manual `./install.sh --uninstall` or manually deleting from `~/.agents/skills/`. There is no version snapshot or easy downgrade path.
  - File: `install.sh` (uninstall section, lines 267-317)

---

## Documentation Gaps

- **Some skills are incomplete in the repo**: Several directories contain only `SKILL.md` without `references/` or `scripts/` subdirectories (e.g., `requirement-clarification/`, `prd-generation/`, `e2e-codebase-mapping/`, `e2e-dev-task-setup/`, `e2e-deploy-pipeline/`, `e2e-code-review-loop/`, `e2e-progress-notify/`, `e2e-prd-share/`). The architecture doc references `references/` files that may not exist in the repo.
  - Files: Multiple skills under `skills/`
  - Impact: Skills that claim to have tool mapping layers (`references/trae-tools.md` / `references/openclaw-tools.md`) may be missing them, breaking dual-runtime compatibility.

- **No versioned API documentation for skill interfaces**: The contracts between skills (what `e2e-code-review-loop` expects from `e2e-codebase-mapping`, what `e2e-deploy-pipeline` passes to `bytedance-tce`) are defined implicitly in SKILL.md prose, not as structured interfaces or schemas.
  - Impact: When a skill changes its input/output format, downstream users have no programmatic way to detect the breaking change.

- **No changelog or release notes**: With only 2 commits and no changelog, adopters cannot tell what changed between versions.
  - Impact: Users upgrading skills via `install.sh` have no visibility into what's new or what's potentially breaking.

---

## Recommended Mitigations

| Concern | Priority | Recommended Fix |
|---------|----------|-----------------|
| HARD-GATE is prompt-only, not programmatic | **HIGH** | Add a programmatic guard (e.g., shell wrapper that intercepts write commands, or OpenClaw-level tool permission policy) |
| Zero automated tests | **HIGH** | Add at least: (1) install.sh integration test, (2) skill frontmatter validation, (3) run-remote-test.sh unit tests with mock SSH |
| install.sh destructive sync | **MEDIUM** | Add atomic sync: copy to temp dir, validate, then atomic rename. Or use rsync for differential sync |
| No CI/CD pipeline | **MEDIUM** | Add GitHub Actions or internal CI to: validate all 13 skills have SKILL.md, check frontmatter format, run install.sh --dry-run |
| Session state loss on interruption | **MEDIUM** | Implement session checkpoint: after each HARD-GATE, write state to a `.e2e-session/` directory; on restart, resume from last checkpoint |
| Dependency version pinning | **MEDIUM** | Add version constraints in a `constraints.md` or similar, specifying minimum OpenClaw version, Node.js version, and internal skill versions |
| Skill interface contracts | **LOW** | Define structured interfaces between skills (e.g., what `verification.md` fields each skill owns) as YAML schemas |
| Remove SKILL.md.bak | **LOW** | Delete `skills/e2e-dev-task-setup/SKILL.md.bak` or add `*.bak` to `.gitignore` |
| Changelog | **LOW** | Add a `CHANGELOG.md` and document each commit/feature change |

---

*Concerns audit: 2026-04-22*
