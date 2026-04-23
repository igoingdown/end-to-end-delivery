---
name: e2e-remote-test
description: "端到端交付的远端测试 skill（MVP 简化版），**消费 e2e-solution-design 产出的 verification.md**，通过 SSH 连接到字节开发机执行编译和单元测试，**结果回写 verification.md §1（编译验证）和 §2（单测验证）**。**严格禁止**在本地跑测试。前置假设：用户已通过 Dev SSH 工具把最新代码同步到开发机（本 skill 不做代码同步）。当代码改动完成、需要跑单测验证、需要在远端环境测试时必须调用此 skill。典型触发场景：'跑一下单测'、'在开发机跑测试'、'SSH 测试'、'远端跑一下编译'、'测试一下这个改动'、'remote test'、'verify on dev machine'。内部通过 scripts/run-remote-test.sh 执行 SSH 连接 + 编译 + 测试 + 结果回传。"
---

# E2E Remote Test —— 远端测试（MVP 简化版）

## 定位

端到端交付主流程的**阶段 5**：在**公司远端开发机**验证代码改动。

**MVP 边界**（不做的事）：
- ❌ 不做代码同步（假设用户已用 Dev SSH 推送了代码）
- ❌ 不做依赖管理（假设开发机环境已就绪）
- ❌ 不做复杂的测试策略（如集成测试、E2E 测试）

**MVP 做的事**（核心）：
- ✅ SSH 连接开发机
- ✅ 执行编译命令
- ✅ 执行单元测试命令
- ✅ 收集结果、格式化展示

---

## 硬约束（不可违反）

1. **禁止本地跑测试**。任何情况下都必须走 SSH。
2. **开发机信息由用户提供**。不假设 hostname。
3. **命令由用户配置或从项目推断**。不硬编码编译/测试命令。
4. **测试失败时明确返回失败用例**。不吞错误。

---

## 前置条件

进入本 skill 前，必须满足：

- [x] `e2e-solution-design` 已产出 `specs/[简称]/verification.md`（含编译/单测 AC）
- [x] 用户已配置 Dev SSH 别名（在本地 `~/.ssh/config` 里能 `ssh <dev-host>` 连通）
- [x] 用户已用 Dev SSH 工具把最新代码同步到开发机
- [x] 用户知道**远端代码目录**（绝对路径）
- [x] 用户知道**编译命令**（或者语言默认命令能推断）
- [x] 用户知道**测试命令**

**缺失任一** → 结构化问用户。示例：

```
在跑远端测试前，我需要确认 4 件事：

1. 开发机 SSH alias（比如 `dev01` 或 `bytedance-dev`）
2. 远端代码目录（绝对路径，比如 `/home/tiger/workspace/xxx-api`）
3. 编译命令（比如 `go build ./...` 或 `make build`）
4. 测试命令（比如 `go test ./...` 或 `pytest tests/`）

如果你是 Go 项目，通常 3、4 分别是 `go build ./...` 和 `go test ./...`。
```

---

## 核心工作流

```
读 verification.md AC → 执行测试 → 回写结果
   │
   ▼
┌──────────────────────────────────┐
│ 步骤 1：读 verification.md        │
│ 提取 §1（编译验证）和 §2（单测）AC│
└────────────────┬─────────────────┘
                 │
                 ▼
┌──────────────────────────────────┐
│ 步骤 2：前置校验                  │
│ - SSH 连通性测试                  │
│ - 目录存在性检查                  │
└────────────────┬─────────────────┘
                 │
                 ▼
┌──────────────────────────────────┐
│ 步骤 3：执行 run-remote-test.sh   │
│ (SSH → cd → build → test)        │
└────────────────┬─────────────────┘
                 │
                 ▼
┌──────────────────────────────────┐
│ 步骤 4：解析结果                  │
│ 通过/失败用例数 + 失败详情       │
└────────────────┬─────────────────┘
                 │
                 ▼
┌──────────────────────────────────┐
│ 步骤 5：回写 verification.md      │
│ 更新 §1-2 的 Status/Results      │
└────────────────┬─────────────────┘
                 │
                 ▼
产出：更新后的 verification.md
```

---

## 脚本调用

本 skill 的实际执行由 `scripts/run-remote-test.sh` 完成。

**调用方式**：

```bash
bash scripts/run-remote-test.sh \
  --host <SSH_ALIAS> \
  --dir <REMOTE_DIR> \
  --build "<BUILD_CMD>" \
  --test "<TEST_CMD>" \
  [--timeout <SECONDS>]
```

**调用示例**：

```bash
bash scripts/run-remote-test.sh \
  --host dev01 \
  --dir /home/tiger/workspace/user-segment-api \
  --build "go build ./..." \
  --test "go test -v ./... -count=1" \
  --timeout 600
```

**超时**默认 10 分钟（600 秒）。测试量大时用户可指定。

---

## 参数说明

| 参数 | 必填 | 说明 |
|---|---|---|
| `--host` | ✅ | SSH 别名或 `user@host` 格式 |
| `--dir` | ✅ | 远端代码绝对路径 |
| `--build` | ✅ | 编译命令（整体用引号包住） |
| `--test` | ✅ | 测试命令（整体用引号包住） |
| `--timeout` | ❌ | 超时秒数，默认 600 |
| `--env` | ❌ | 可重复，远端环境变量 `KEY=VALUE` |

---

## 结果解析

脚本的 stdout/stderr 会回传给主 Agent，本 skill 按以下规则解析：

### 成功判断

脚本 exit code = 0 → 成功
脚本 exit code ≠ 0 → 失败

### 失败原因识别

按脚本输出的 marker 识别失败阶段：

- `[BUILD_FAILED]` → 编译失败
- `[TEST_FAILED]` → 测试失败（解析失败用例）
- `[TIMEOUT]` → 超时
- `[SSH_FAILED]` → SSH 连接问题

### Go 测试失败用例提取（示例）

对于 `go test` 输出，按以下模式提取失败：

```
--- FAIL: TestFoo (0.05s)
    foo_test.go:42: expected 10, got 5
```

提取 → `TestFoo` 失败，位置 `foo_test.go:42`。

### Python pytest 失败提取

```
FAILED tests/test_foo.py::test_bar - AssertionError: expected 10, got 5
```

提取 → `tests/test_foo.py::test_bar` 失败。

### 其他语言

Java/Rust/Node.js 等语言的测试框架输出略有差异。`run-remote-test.sh` 尽量捕获通用模式；解析不到时，**直接把完整 stdout 返回**，让主 Agent 基于完整输出判断。

---

## 报告格式

无论成功失败，产出**结构化报告**：

### 成功示例

```markdown
# 远端测试报告 ✅

**开发机**: dev01
**代码目录**: /home/tiger/workspace/user-segment-api
**执行时间**: 2026-04-19 14:35:00 (UTC+8)
**总耗时**: 2 分 15 秒

## 编译
✅ 成功（耗时 45 秒）

## 单测
✅ 全部通过

- 测试用例总数：128
- 通过：128
- 失败：0
- 跳过：0
- 耗时：1 分 30 秒

## 下一步
可以进入阶段 6（部署）。
调用 e2e-deploy-pipeline 开始 BOE 部署。
```

### 失败示例

```markdown
# 远端测试报告 ❌

**开发机**: dev01
**代码目录**: /home/tiger/workspace/user-segment-api
**执行时间**: 2026-04-19 14:35:00
**总耗时**: 3 分 42 秒

## 编译
✅ 成功

## 单测
❌ 有 3 个测试失败

- 总数：128
- 通过：125
- 失败：3
- 跳过：0

### 失败详情

1. **TestSegmentRuleValidation** (`service/segment_service_test.go:78`)
   ```
   expected error "invalid RPN expression", got nil
   ```

2. **TestCreateRule_Concurrent** (`handler/segment_handler_test.go:142`)
   ```
   deadline exceeded
   ```

3. **TestRuleParser_EdgeCase** (`parser/rpn_test.go:201`)
   ```
   panic: runtime error: index out of range [5] with length 5
   ```

## 诊断建议

- 失败 1: 规则校验逻辑未抛出预期错误 → 检查 `service/segment_service.go` 的校验分支
- 失败 2: 并发测试超时 → 可能是死锁或过度等待
- 失败 3: 解析器 bug → 数组越界

## 下一步
需要回到阶段 4（代码改造）修复。
建议：调用 `e2e-code-review-loop` 并告知这 3 个失败用例。
```

---

## 失败处理

### 失败 A：SSH 连接失败

- 检查 SSH alias 是否正确
- 建议用户先手工 `ssh <alias>` 验证
- 返回 `BLOCKED`，等用户修好 SSH

### 失败 B：远端目录不存在

- 提示用户：代码可能还没推送到开发机
- 建议：用 Dev SSH 工具同步代码后再跑
- 返回 `NEEDS_CONTEXT`

### 失败 C：编译失败

- 展示完整编译错误
- **不尝试**自动修复（那是 `e2e-code-review-loop` 的事）
- 返回 `DONE_WITH_CONCERNS`（因为 skill 本身完成了，只是结果是编译失败）

### 失败 D：测试超时

- 询问用户是否需要加大 `--timeout`
- 或者建议缩小测试范围（只跑相关包）

### 失败 E：测试失败

- 结构化列出失败用例
- 返回 `DONE_WITH_CONCERNS`
- 主 Agent 根据失败数决定是否回退到 `e2e-code-review-loop`

---

## 和其他 skill 的协同

### 输入来自

- `e2e-solution-design` —— verification.md（含编译/单测 AC）
- `e2e-code-review-loop` —— 代码改动完成后触发远端测试

### 输出给

- **回写 verification.md §1-2**（编译验证/单测验证的 Status/Results）
- 如果通过 → 主 Agent 进入 `e2e-deploy-pipeline`
- 如果失败 → 主 Agent 回退到 `e2e-code-review-loop`，附带失败用例

### 迭代循环

本 skill 可能被**反复调用**（code → test → fix → test 循环）。

`e2e-code-review-loop` 应该限制循环次数（建议最多 3 次），防止无限循环。

---

## 反 AI-slop 规范

### 禁用模式

- ❌ 编造测试结果（"应该能通过"）
- ❌ 跳过失败不报（"绝大多数通过了"）
- ❌ 在本地跑"验证下"
- ❌ 随便猜测失败原因（说"可能是"但没依据）

### 正确模式

- ✅ 实际调用脚本，拿实际输出
- ✅ 失败全部报出，不筛选
- ✅ 失败诊断基于**实际**错误信息
- ✅ 不确定时说"这个错误我没见过，建议人工看"

---

## 参考资料

- `scripts/run-remote-test.sh` —— SSH 执行脚本（核心）
- `references/openclaw-tools.md` —— OpenClaw 运行时
- `references/trae-tools.md` —— Trae 运行时（可用 IDE 内置 terminal）

---

## 自检清单（每次执行前）

- [ ] 4 个必填参数（host/dir/build/test）是否都有？
- [ ] 是否真的通过 SSH 跑，没偷偷在本地跑？
- [ ] 超时设置是否合理？
- [ ] 结果是否结构化展示？
- [ ] 失败时是否**完整**列出失败用例（不截断）？

---

*本 skill MVP 边界明确：不做代码同步、不做复杂测试策略、只做"SSH + 编译 + 测试"的最小闭环。后续版本可扩展（见项目 README 的 MVP 硬约束 #25）。*
