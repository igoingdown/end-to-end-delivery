#!/usr/bin/env bash
# install.sh —— 端到端交付 Agent 安装/更新脚本
#
# 作用：把 ~/github/end-to-end-delivery/skills/* 同步到 ~/.agents/skills/
#
# 使用：
#   ./install.sh            # 安装（首次）或更新（后续）
#   ./install.sh --dry-run  # 预览，不实际拷贝
#   ./install.sh --force    # 强制覆盖（重名时）
#   ./install.sh --uninstall # 卸载本项目 skill
#   ./install.sh --help
#
# 设计原则：
#   - 默认不覆盖已有 skill（安全）
#   - 命名冲突时明确报错（避免误伤本地 46 个 skill）
#   - 所有操作都可 dry-run
#   - 有 uninstall 逆操作

set -euo pipefail
IFS=$'\n\t'

# ============== 配置 ==============
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skills"
TARGET_DIR="${HOME}/.agents/skills"

# 本项目安装到每个 skill 目录里的标记文件，用于可靠识别"本项目安装的 skill"
# （取代早期基于 grep SKILL.md 文案的启发式判断）
INSTALL_MARKER=".installed-by-e2e-delivery"

# 本项目 14 个 skill 的名字（和目录名一致）
PROJECT_SKILLS=(
  "using-end-to-end-delivery"
  "adversarial-qa"
  "requirement-clarification"
  "prd-generation"
  "e2e-web-search"
  "e2e-codebase-mapping"
  "e2e-solution-design"
  "e2e-dev-task-setup"
  "e2e-remote-test"
  "e2e-deploy-pipeline"
  "e2e-code-review-loop"
  "e2e-progress-notify"
  "e2e-architecture-draw"
  "e2e-prd-share"
)

# ============== 颜色输出 ==============
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()    { echo -e "${BLUE}[info]${NC} $*"; }
success() { echo -e "${GREEN}[ok]${NC} $*"; }
warn()    { echo -e "${YELLOW}[warn]${NC} $*"; }
error()   { echo -e "${RED}[error]${NC} $*" >&2; }

# ============== 参数解析 ==============
DRY_RUN=0
FORCE=0
UNINSTALL=0

usage() {
  cat <<EOF
用法：
  $0                  首次安装或更新
  $0 --dry-run        预览将要执行的操作
  $0 --force          遇到重名 skill 时强制覆盖（⚠️ 谨慎使用）
  $0 --uninstall      卸载本项目 14 个 skill（不动本地其他 skill）
  $0 --help           打印本帮助

配置：
  SOURCE_DIR = $SOURCE_DIR
  TARGET_DIR = $TARGET_DIR

本项目包含 ${#PROJECT_SKILLS[@]} 个 skill（全部以 e2e- 前缀或独立语义名）：
EOF
  for s in "${PROJECT_SKILLS[@]}"; do
    echo "  - $s"
  done
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)    DRY_RUN=1; shift ;;
    --force)      FORCE=1; shift ;;
    --uninstall)  UNINSTALL=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    *)
      error "未知参数: $1"
      usage
      exit 1
      ;;
  esac
done

# ============== 前置校验 ==============
preflight() {
  info "前置校验..."

  # 1. 源目录存在
  if [[ ! -d "$SOURCE_DIR" ]]; then
    error "源目录不存在: $SOURCE_DIR"
    error "请确认你在 end-to-end-delivery 项目根目录下运行本脚本"
    exit 2
  fi

  # 2. 目标目录存在（或能创建）
  if [[ ! -d "$TARGET_DIR" ]]; then
    warn "目标目录不存在: $TARGET_DIR"
    if [[ $DRY_RUN -eq 0 ]]; then
      info "将创建目标目录..."
      mkdir -p "$TARGET_DIR"
      success "已创建 $TARGET_DIR"
    else
      info "(dry-run) 会创建 $TARGET_DIR"
    fi
  fi

  # 3. 项目 skill 全都在源目录存在
  local missing=()
  for skill in "${PROJECT_SKILLS[@]}"; do
    if [[ ! -d "$SOURCE_DIR/$skill" ]]; then
      missing+=("$skill")
    fi
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    error "以下 skill 在源目录缺失："
    for s in "${missing[@]}"; do
      error "  - $SOURCE_DIR/$s"
    done
    error "请确保本项目完整克隆，再重试"
    exit 3
  fi

  # 4. 每个 skill 都有 SKILL.md
  missing=()
  for skill in "${PROJECT_SKILLS[@]}"; do
    if [[ ! -f "$SOURCE_DIR/$skill/SKILL.md" ]]; then
      missing+=("$skill")
    fi
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    error "以下 skill 缺少 SKILL.md 文件："
    for s in "${missing[@]}"; do
      error "  - $SOURCE_DIR/$s/SKILL.md"
    done
    exit 4
  fi

  success "前置校验通过"
}

# ============== 冲突检测 ==============
detect_conflicts() {
  info "检查命名冲突..."

  local conflicts=()
  for skill in "${PROJECT_SKILLS[@]}"; do
    if [[ -e "$TARGET_DIR/$skill" ]]; then
      # 通过 manifest 标记文件可靠识别"本项目安装的 skill"
      # 存在标记 → 视为需要更新（不算冲突）
      # 无标记 → 本地用户自有的同名 skill（冲突）
      if [[ -f "$TARGET_DIR/$skill/$INSTALL_MARKER" ]]; then
        :
      else
        conflicts+=("$skill")
      fi
    fi
  done

  if [[ ${#conflicts[@]} -gt 0 ]]; then
    warn "检测到命名冲突（本地已有同名 skill）："
    for s in "${conflicts[@]}"; do
      warn "  - $TARGET_DIR/$s"
    done
    if [[ $FORCE -eq 1 ]]; then
      warn "已指定 --force，将覆盖上述 skill"
      warn "⚠️ 这会破坏本地已有的同名 skill！"
    else
      error "遇到冲突，停止安装。"
      error "如果确认要覆盖，重跑加 --force 参数："
      error "  $0 --force"
      error "或先手动重命名本地冲突 skill。"
      exit 5
    fi
  else
    success "无冲突，可以安装"
  fi
}

# ============== 同步逻辑 ==============
do_sync() {
  info "开始同步 skill..."
  local count_new=0
  local count_updated=0

  for skill in "${PROJECT_SKILLS[@]}"; do
    local src="$SOURCE_DIR/$skill"
    local dst="$TARGET_DIR/$skill"
    local tmp="${dst}.tmp.$$"

    if [[ -e "$dst" ]]; then
      info "[更新] $skill"
      if [[ $DRY_RUN -eq 0 ]]; then
        # 原子更新：先拷到临时目录，成功后再替换
        # 中途失败不会留下半截目录
        rm -rf "$tmp"
        cp -R "$src" "$tmp"
        touch "$tmp/$INSTALL_MARKER"
        rm -rf "$dst"
        mv "$tmp" "$dst"
      fi
      count_updated=$((count_updated + 1))
    else
      info "[新增] $skill"
      if [[ $DRY_RUN -eq 0 ]]; then
        rm -rf "$tmp"
        cp -R "$src" "$tmp"
        touch "$tmp/$INSTALL_MARKER"
        mv "$tmp" "$dst"
      fi
      count_new=$((count_new + 1))
    fi

    # 确保 scripts/ 下的 .sh 文件有执行权限
    if [[ -d "$dst/scripts" ]]; then
      if [[ $DRY_RUN -eq 0 ]]; then
        find "$dst/scripts" -name "*.sh" -exec chmod +x {} \;
      fi
    fi
  done

  if [[ $DRY_RUN -eq 0 ]]; then
    success "同步完成：新增 $count_new 个，更新 $count_updated 个"
  else
    info "(dry-run) 将会：新增 $count_new 个，更新 $count_updated 个"
  fi
}

# ============== 安装流程 ==============
do_install() {
  info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  info " 端到端交付 Agent · 安装脚本"
  info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  if [[ $DRY_RUN -eq 1 ]]; then
    warn "dry-run 模式：不会实际修改文件"
  fi

  preflight
  detect_conflicts
  do_sync

  echo ""
  success "✅ 安装完成"
  echo ""
  info "后续步骤："
  echo "  1. 配置 OpenClaw（如果使用）："
  echo "     openclaw config set skills.load.extraDirs '[\"~/.agents/skills\"]'"
  echo "     openclaw gateway restart"
  echo ""
  echo "  2. 配置 Trae（如果使用）："
  echo "     在 Trae 设置里把 ~/.agents/skills 加到 skill 搜索路径"
  echo ""
  echo "  3. 挂载 AGENTS.md："
  echo "     ln -sf $SOURCE_DIR/../AGENTS.md ~/.openclaw/workspace/AGENTS.md"
  echo ""
  echo "  详细集成步骤见："
  echo "    docs/integration-openclaw.md"
  echo "    docs/integration-trae.md"
  echo "    docs/integration-testing.md  ← 请按里面的清单做一次 smoke test"
  echo ""
}

# ============== 卸载流程 ==============
do_uninstall() {
  info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  info " 端到端交付 Agent · 卸载脚本"
  info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  if [[ $DRY_RUN -eq 1 ]]; then
    warn "dry-run 模式：不会实际删除"
  fi

  warn "即将删除 $TARGET_DIR 下的 ${#PROJECT_SKILLS[@]} 个项目 skill"
  warn "本地其他 skill（bytedance-*、feishu-cli-* 等）不受影响"

  # 二次确认
  if [[ $DRY_RUN -eq 0 ]] && [[ $FORCE -eq 0 ]]; then
    # 允许 read 失败（Ctrl+D / EOF）而不让 set -e 直接退出，统一由下面的逻辑处理
    local confirm=""
    read -r -p "确认卸载？输入 'yes' 继续：" confirm || true
    if [[ "$confirm" != "yes" ]]; then
      error "已取消"
      exit 0
    fi
  fi

  local count_removed=0
  for skill in "${PROJECT_SKILLS[@]}"; do
    local dst="$TARGET_DIR/$skill"
    if [[ -e "$dst" ]]; then
      # 只删"本项目安装的"那些（有 manifest 标记）
      if [[ -f "$dst/$INSTALL_MARKER" ]]; then
        info "[删除] $skill"
        if [[ $DRY_RUN -eq 0 ]]; then
          rm -rf "$dst"
        fi
        count_removed=$((count_removed + 1))
      else
        warn "[跳过] $skill（无安装标记，可能是本地自有 skill）"
      fi
    fi
  done

  if [[ $DRY_RUN -eq 0 ]]; then
    success "卸载完成，共删除 $count_removed 个 skill"
  else
    info "(dry-run) 将删除 $count_removed 个 skill"
  fi

  echo ""
  info "别忘记也清理 OpenClaw 配置："
  echo "  openclaw config unset skills.load.extraDirs"
  echo "  openclaw gateway restart"
  echo ""
}

# ============== 主入口 ==============
main() {
  if [[ $UNINSTALL -eq 1 ]]; then
    do_uninstall
  else
    do_install
  fi
}

main "$@"
