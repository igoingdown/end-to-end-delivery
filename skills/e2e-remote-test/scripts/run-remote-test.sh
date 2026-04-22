#!/usr/bin/env bash
# run-remote-test.sh —— 远端测试执行脚本（MVP 简化版）
#
# 作用：通过 SSH 连接到字节开发机，执行编译和测试，回传结果。
#
# 前置假设：
#   1. 用户已在 ~/.ssh/config 配置了 SSH 别名
#   2. 用户已用 Dev SSH 工具把代码推送到开发机
#   3. 开发机上的依赖已就绪（Go toolchain、npm 等）
#
# 硬约束：
#   - 不在本地跑任何测试
#   - 失败时返回非零 exit code
#   - 输出带 marker 方便解析（[BUILD_FAILED] / [TEST_FAILED] / [TIMEOUT]）

set -u

# ============== 默认值 ==============
TIMEOUT=600
ENV_VARS=()

# ============== 参数解析 ==============
usage() {
  cat <<EOF
用法：
  $0 --host <SSH_ALIAS> --dir <REMOTE_DIR> --build "<BUILD_CMD>" --test "<TEST_CMD>" [--timeout <SEC>] [--env KEY=VAL ...]

必填参数：
  --host        SSH 别名（从 ~/.ssh/config 读取）或 user@host 格式
  --dir         远端代码绝对路径
  --build       编译命令（加引号）
  --test        测试命令（加引号）

可选参数：
  --timeout     整体超时秒数（默认 600）
  --env         远端环境变量（可重复），格式 KEY=VALUE

示例：
  $0 --host dev01 \\
     --dir /home/tiger/workspace/user-segment-api \\
     --build "go build ./..." \\
     --test "go test -v ./..." \\
     --timeout 600

EOF
  exit 1
}

# 如果没有参数，打印用法
if [[ $# -eq 0 ]]; then
  usage
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)    HOST="$2"; shift 2 ;;
    --dir)     REMOTE_DIR="$2"; shift 2 ;;
    --build)   BUILD_CMD="$2"; shift 2 ;;
    --test)    TEST_CMD="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    --env)     ENV_VARS+=("$2"); shift 2 ;;
    -h|--help) usage ;;
    *)
      echo "[ERROR] Unknown argument: $1" >&2
      usage
      ;;
  esac
done

# ============== 校验必填参数 ==============
MISSING=()
[[ -z "${HOST:-}" ]] && MISSING+=("--host")
[[ -z "${REMOTE_DIR:-}" ]] && MISSING+=("--dir")
[[ -z "${BUILD_CMD:-}" ]] && MISSING+=("--build")
[[ -z "${TEST_CMD:-}" ]] && MISSING+=("--test")

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "[ERROR] Missing required arguments: ${MISSING[*]}" >&2
  usage
fi

# ============== 打印执行计划 ==============
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[e2e-remote-test] 执行计划"
echo "  HOST:        $HOST"
echo "  REMOTE_DIR:  $REMOTE_DIR"
echo "  BUILD:       $BUILD_CMD"
echo "  TEST:        $TEST_CMD"
echo "  TIMEOUT:     ${TIMEOUT}s"
if [[ ${#ENV_VARS[@]} -gt 0 ]]; then
  echo "  ENV:         ${ENV_VARS[*]}"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ============== 步骤 1：SSH 连通性测试 ==============
echo ""
echo "[step 1/4] SSH 连通性测试..."

# 快速 SSH 连接测试（5 秒超时）
if ! timeout 5 ssh -o BatchMode=yes -o ConnectTimeout=5 "$HOST" "echo ok" > /dev/null 2>&1; then
  echo "[SSH_FAILED] 无法连接到 $HOST" >&2
  echo "排查建议：" >&2
  echo "  1. 运行 'ssh $HOST' 手工测试" >&2
  echo "  2. 检查 ~/.ssh/config 是否有 $HOST 的配置" >&2
  echo "  3. 检查是否需要连公司 VPN" >&2
  exit 10
fi
echo "[step 1/4] ✅ SSH 连接正常"

# ============== 步骤 2：远端目录检查 ==============
echo ""
echo "[step 2/4] 检查远端目录是否存在..."

if ! ssh "$HOST" "[ -d '$REMOTE_DIR' ]"; then
  echo "[DIR_NOT_FOUND] 远端目录不存在: $REMOTE_DIR" >&2
  echo "排查建议：" >&2
  echo "  1. 代码可能还没推送到开发机" >&2
  echo "  2. 路径是否拼写正确" >&2
  echo "  3. 用户在开发机上的 HOME 可能不是预期路径" >&2
  exit 11
fi
echo "[step 2/4] ✅ 远端目录存在"

# ============== 构造远端执行的完整命令 ==============
# 拼接 ENV 变量
ENV_EXPORT=""
for kv in "${ENV_VARS[@]}"; do
  ENV_EXPORT="${ENV_EXPORT}export $kv; "
done

# 远端执行脚本（用 heredoc 传入，保留变量展开）
# 每个 marker 包裹对应阶段，方便主 Agent 解析
REMOTE_SCRIPT="
set -u  # 未定义变量报错
${ENV_EXPORT}
cd '$REMOTE_DIR' || { echo '[DIR_NOT_FOUND] cd 失败'; exit 11; }

echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
echo '[BUILD_START] 开始编译...'
echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'

BUILD_T0=\$(date +%s)
if ! $BUILD_CMD; then
  BUILD_T1=\$(date +%s)
  echo '[BUILD_FAILED] 编译失败 (耗时 '\$((BUILD_T1 - BUILD_T0))'s)'
  exit 20
fi
BUILD_T1=\$(date +%s)
echo '[BUILD_OK] 编译成功 (耗时 '\$((BUILD_T1 - BUILD_T0))'s)'

echo ''
echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
echo '[TEST_START] 开始测试...'
echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'

TEST_T0=\$(date +%s)
if ! $TEST_CMD; then
  TEST_T1=\$(date +%s)
  echo '[TEST_FAILED] 测试失败 (耗时 '\$((TEST_T1 - TEST_T0))'s)'
  exit 30
fi
TEST_T1=\$(date +%s)
echo '[TEST_OK] 测试通过 (耗时 '\$((TEST_T1 - TEST_T0))'s)'
"

# ============== 步骤 3：执行（带超时） ==============
echo ""
echo "[step 3/4] 远端执行 build + test（超时 ${TIMEOUT}s）..."

# 用 timeout 包裹 ssh
# -t 给 ssh 分配伪终端，确保某些工具（如 terminalUI 的测试）能正常输出
if ! timeout "$TIMEOUT" ssh -t "$HOST" "bash -c \"$REMOTE_SCRIPT\""; then
  EXIT_CODE=$?
  if [[ $EXIT_CODE -eq 124 ]]; then
    echo ""
    echo "[TIMEOUT] 超过 ${TIMEOUT}s 未完成" >&2
    exit 40
  fi

  # SSH / 远端脚本自定义 exit code
  case $EXIT_CODE in
    11) echo "[DIR_NOT_FOUND] 远端目录错误"; exit 11 ;;
    20) echo "[BUILD_FAILED] 编译失败"; exit 20 ;;
    30) echo "[TEST_FAILED] 测试失败"; exit 30 ;;
    *)
      echo "[UNKNOWN_ERROR] 未预期退出码: $EXIT_CODE" >&2
      exit 50
      ;;
  esac
fi

# ============== 步骤 4：成功 ==============
echo ""
echo "[step 4/4] ✅ 全部成功"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit 0
