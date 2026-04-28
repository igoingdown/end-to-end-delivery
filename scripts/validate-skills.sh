#!/usr/bin/env bash
# validate-skills.sh —— 校验本项目 skill 目录的完整性与 frontmatter 规范
#
# 校验项：
#   1. 每个 skill 目录都有 SKILL.md
#   2. SKILL.md 以 YAML frontmatter 开头（--- ... ---）
#   3. frontmatter 里 name 字段与目录名完全一致
#   4. frontmatter 里 description 字段非空
#   5. (软警告) description 长度在 [50, 2000] 字符之间（过短描述不够触发 LLM 路由，
#      过长则挤占 system prompt）
#
# 用法：
#   ./scripts/validate-skills.sh
#   ./scripts/validate-skills.sh --strict   # 把软警告也当作失败
#
# 退出码：0 = 全部通过；1 = 有硬错误；2 = 有软警告（仅 --strict 时）

set -eo pipefail
set -u

STRICT=0
if [[ "${1:-}" == "--strict" ]]; then
  STRICT=1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$ROOT/skills"

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

errors=0
warnings=0

fail() {
  echo -e "${RED}[FAIL]${NC} $*" >&2
  errors=$((errors + 1))
}

warn() {
  echo -e "${YELLOW}[WARN]${NC} $*" >&2
  warnings=$((warnings + 1))
}

pass() {
  echo -e "${GREEN}[ok]${NC} $*"
}

if [[ ! -d "$SKILLS_DIR" ]]; then
  fail "skills/ 目录不存在：$SKILLS_DIR"
  exit 1
fi

# 从 SKILL.md 的 frontmatter 里抽单个字段值（只取第一个冒号后的内容，去引号去首尾空白）
# 限制：不支持多行 YAML 值（本项目 description 全是单行，够用）
extract_field() {
  local file="$1"
  local field="$2"
  # 只看第一个 --- 到第二个 --- 之间
  awk -v field="$field" '
    /^---$/ { count++; next }
    count == 1 {
      if ($0 ~ "^" field ":") {
        sub("^" field ":[[:space:]]*", "")
        sub(/^"/, "")
        sub(/"$/, "")
        sub(/^'\''/, "")
        sub(/'\''$/, "")
        print
        exit
      }
    }
    count >= 2 { exit }
  ' "$file"
}

# 校验每个 skill 目录
for skill_dir in "$SKILLS_DIR"/*/; do
  skill_name="$(basename "$skill_dir")"
  skill_md="$skill_dir/SKILL.md"

  if [[ ! -f "$skill_md" ]]; then
    fail "$skill_name: 缺少 SKILL.md"
    continue
  fi

  # 必须以 --- 开头（frontmatter）
  first_line="$(head -1 "$skill_md")"
  if [[ "$first_line" != "---" ]]; then
    fail "$skill_name: SKILL.md 未以 --- 开头（缺 YAML frontmatter）"
    continue
  fi

  # frontmatter 必须有第二个 ---
  if ! awk 'NR>1 && /^---$/ {found=1; exit} END {exit !found}' "$skill_md"; then
    fail "$skill_name: SKILL.md frontmatter 未闭合（缺第二个 ---）"
    continue
  fi

  name_val="$(extract_field "$skill_md" name || true)"
  desc_val="$(extract_field "$skill_md" description || true)"

  if [[ -z "$name_val" ]]; then
    fail "$skill_name: frontmatter 缺 name 字段"
  elif [[ "$name_val" != "$skill_name" ]]; then
    fail "$skill_name: frontmatter name='$name_val' 与目录名不一致"
  fi

  if [[ -z "$desc_val" ]]; then
    fail "$skill_name: frontmatter 缺 description 字段（或为空）"
  else
    local_len=${#desc_val}
    if [[ $local_len -lt 50 ]]; then
      warn "$skill_name: description 只有 $local_len 字符，偏短（建议 50+）"
    elif [[ $local_len -gt 2000 ]]; then
      warn "$skill_name: description 长度 $local_len 字符，偏长（建议 <2000）"
    fi
  fi

  if [[ -z "${skill_had_error:-}" ]] && [[ -n "$name_val" ]] && [[ -n "$desc_val" ]] && [[ "$name_val" == "$skill_name" ]]; then
    pass "$skill_name"
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "errors: $errors, warnings: $warnings"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $errors -gt 0 ]]; then
  exit 1
fi
if [[ $STRICT -eq 1 ]] && [[ $warnings -gt 0 ]]; then
  exit 2
fi
exit 0
