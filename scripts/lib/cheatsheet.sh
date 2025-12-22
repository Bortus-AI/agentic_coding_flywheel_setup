#!/usr/bin/env bash
# ============================================================
# ACFS Cheatsheet - discover installed aliases/commands
# Source of truth: ~/.acfs/zsh/acfs.zshrc
# ============================================================

set -euo pipefail

ACFS_HOME="${ACFS_HOME:-$HOME/.acfs}"
ACFS_VERSION="${ACFS_VERSION:-0.1.0}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/../../VERSION" ]]; then
  ACFS_VERSION="$(cat "$SCRIPT_DIR/../../VERSION" 2>/dev/null || echo "$ACFS_VERSION")"
elif [[ -f "$ACFS_HOME/VERSION" ]]; then
  ACFS_VERSION="$(cat "$ACFS_HOME/VERSION" 2>/dev/null || echo "$ACFS_VERSION")"
fi

HAS_GUM=false
command -v gum &>/dev/null && HAS_GUM=true

print_help() {
  cat <<'EOF'
ACFS Cheatsheet (aliases + quick commands)

Usage:
  acfs cheatsheet [query]
  acfs cheatsheet --category <name>
  acfs cheatsheet --search <pattern>
  acfs cheatsheet --json

Examples:
  acfs cheatsheet
  acfs cheatsheet git
  acfs cheatsheet "push"
  acfs cheatsheet --category Agents
  acfs cheatsheet --search docker
EOF
}

json_escape() {
  local s="${1:-}"
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/\\n}
  s=${s//$'\r'/\\r}
  s=${s//$'\t'/\\t}
  printf '%s' "$s"
}

normalize_category() {
  local raw="${1:-}"
  raw="${raw%% (*}"
  raw="${raw#--- }"
  raw="${raw% ---}"
  raw="${raw//aliases/}"
  raw="${raw//alias/}"
  raw="${raw//  / }"
  raw="${raw#"${raw%%[![:space:]]*}"}"
  raw="${raw%"${raw##*[![:space:]]}"}"

  case "${raw,,}" in
    *agent*) echo "Agents" ;;
    *git*) echo "Git" ;;
    *docker*) echo "Docker" ;;
    *directory*) echo "Directories" ;;
    *bun*) echo "Bun" ;;
    *ubuntu*|*debian*|*convenience*) echo "System" ;;
    *modern*cli*) echo "Modern CLI" ;;
    *) [[ -n "$raw" ]] && echo "$raw" || echo "Misc" ;;
  esac
}

infer_category() {
  local name="${1:-}"
  local cmd="${2:-}"
  case "$name" in
    cc|cod|gmi|am) echo "Agents" ;;
    br|bl|bt) echo "Bun" ;;
    dev|proj|dots|p) echo "Directories" ;;
    g*) [[ "$cmd" == git* ]] && { echo "Git"; return 0; } ;;
    d*) [[ "$cmd" == docker* ]] && { echo "Docker"; return 0; } ;;
  esac
  echo "Misc"
}

cheatsheet_parse_zshrc() {
  local zshrc="${1:-$ACFS_HOME/zsh/acfs.zshrc}"
  [[ -f "$zshrc" ]] || return 1

  local current_category="Misc"
  local line rest

  while IFS= read -r line || [[ -n "$line" ]]; do
    # Section markers
    if [[ "$line" =~ ^#[[:space:]]*---[[:space:]]*(.+)[[:space:]]*---[[:space:]]*$ ]]; then
      current_category="$(normalize_category "${BASH_REMATCH[1]}")"
      continue
    fi
    if [[ "$line" =~ ^#[[:space:]]*===[[:space:]]*(.+)[[:space:]]*===[[:space:]]*$ ]]; then
      current_category="$(normalize_category "${BASH_REMATCH[1]}")"
      continue
    fi

    rest="$line"
    while [[ "$rest" =~ alias[[:space:]]+([a-zA-Z0-9_-]+)=('([^']*)'|\"([^\"]*)\"|([^[:space:]]+)) ]]; do
      local name="${BASH_REMATCH[1]}"
      local cmd="${BASH_REMATCH[3]:-${BASH_REMATCH[4]:-${BASH_REMATCH[5]}}}"

      local category="$current_category"
      [[ -z "$category" || "$category" == "Misc" ]] && category="$(infer_category "$name" "$cmd")"

      printf '%s|%s|%s|%s\n' "$category" "$name" "$cmd" "alias"

      # Continue searching after this match (supports multiple aliases per line)
      rest="${rest#*alias }"
    done
  done < "$zshrc"
}

cheatsheet_collect_entries() {
  local zshrc="${1:-$ACFS_HOME/zsh/acfs.zshrc}"
  local -a entries=()
  local line

  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    entries+=("$line")
  done < <(cheatsheet_parse_zshrc "$zshrc" || true)

  # De-dupe by name keeping the last definition.
  local -A seen=()
  local -a dedup_rev=()
  local i
  for ((i=${#entries[@]}-1; i>=0; i--)); do
    IFS='|' read -r _cat name _cmd _kind <<<"${entries[$i]}"
    if [[ -n "${seen[$name]:-}" ]]; then
      continue
    fi
    seen[$name]=1
    dedup_rev+=("${entries[$i]}")
  done

  # Reverse back to restore order of last-occurrence entries.
  for ((i=${#dedup_rev[@]}-1; i>=0; i--)); do
    echo "${dedup_rev[$i]}"
  done
}

cheatsheet_filter_entries() {
  local category_filter="${1:-}"
  local search_filter="${2:-}"
  local zshrc="${3:-$ACFS_HOME/zsh/acfs.zshrc}"

  local line cat name cmd kind
  while IFS= read -r line; do
    IFS='|' read -r cat name cmd kind <<<"$line"

    if [[ -n "$category_filter" ]]; then
      if [[ "${cat,,}" != "${category_filter,,}" ]]; then
        continue
      fi
    fi

    if [[ -n "$search_filter" ]]; then
      local hay="${cat} ${name} ${cmd}"
      if [[ "${hay,,}" != *"${search_filter,,}"* ]]; then
        continue
      fi
    fi

    echo "$line"
  done < <(cheatsheet_collect_entries "$zshrc")
}

cheatsheet_render_plain() {
  local category_filter="${1:-}"
  local search_filter="${2:-}"
  local zshrc="${3:-$ACFS_HOME/zsh/acfs.zshrc}"

  echo "ACFS Cheatsheet v$ACFS_VERSION"
  echo "Source: $zshrc"
  echo ""

  local current=""
  local cat name cmd kind line
  while IFS= read -r line; do
    IFS='|' read -r cat name cmd kind <<<"$line"
    if [[ "$cat" != "$current" ]]; then
      current="$cat"
      echo "$current"
    fi
    printf '  %-8s %s\n' "$name" "$cmd"
  done < <(cheatsheet_filter_entries "$category_filter" "$search_filter" "$zshrc")
}

cheatsheet_render_gum() {
  local category_filter="${1:-}"
  local search_filter="${2:-}"
  local zshrc="${3:-$ACFS_HOME/zsh/acfs.zshrc}"

  gum style --bold --foreground "#89b4fa" "ACFS Cheatsheet v$ACFS_VERSION"
  gum style --foreground "#6c7086" "Source: $zshrc"
  echo ""

  local current=""
  local cat name cmd kind line
  while IFS= read -r line; do
    IFS='|' read -r cat name cmd kind <<<"$line"
    if [[ "$cat" != "$current" ]]; then
      current="$cat"
      echo ""
      gum style --bold --foreground "#cba6f7" "$current"
    fi
    printf '  %-8s %s\n' "$name" "$cmd"
  done < <(cheatsheet_filter_entries "$category_filter" "$search_filter" "$zshrc")
}

cheatsheet_render_json() {
  local category_filter="${1:-}"
  local search_filter="${2:-}"
  local zshrc="${3:-$ACFS_HOME/zsh/acfs.zshrc}"

  local first=true
  printf '{'
  printf '"version":"%s",' "$(json_escape "$ACFS_VERSION")"
  printf '"source":"%s",' "$(json_escape "$zshrc")"
  printf '"entries":['

  local cat name cmd kind line
  while IFS= read -r line; do
    IFS='|' read -r cat name cmd kind <<<"$line"
    if [[ "$first" == "true" ]]; then
      first=false
    else
      printf ','
    fi
    printf '{'
    printf '"category":"%s",' "$(json_escape "$cat")"
    printf '"name":"%s",' "$(json_escape "$name")"
    printf '"command":"%s",' "$(json_escape "$cmd")"
    printf '"kind":"%s"' "$(json_escape "$kind")"
    printf '}'
  done < <(cheatsheet_filter_entries "$category_filter" "$search_filter" "$zshrc")

  printf ']'
  printf '}\n'
}

main() {
  local zshrc="$ACFS_HOME/zsh/acfs.zshrc"
  local category_filter=""
  local search_filter=""
  local json_mode=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h)
        print_help
        return 0
        ;;
      --json)
        json_mode=true
        shift
        ;;
      --category)
        category_filter="${2:-}"
        shift 2
        ;;
      --search)
        search_filter="${2:-}"
        shift 2
        ;;
      --zshrc)
        zshrc="${2:-$zshrc}"
        shift 2
        ;;
      *)
        # Treat positional arg as either category match or a search term.
        local q="$1"
        shift
        case "${q,,}" in
          agents|git|docker|directories|system|bun|modern\ cli)
            category_filter="$q"
            ;;
          *)
            search_filter="$q"
            ;;
        esac
        ;;
    esac
  done

  if [[ "$json_mode" == "true" ]]; then
    cheatsheet_render_json "$category_filter" "$search_filter" "$zshrc"
  elif [[ "$HAS_GUM" == "true" ]]; then
    cheatsheet_render_gum "$category_filter" "$search_filter" "$zshrc"
  else
    cheatsheet_render_plain "$category_filter" "$search_filter" "$zshrc"
  fi
}

main "$@"
