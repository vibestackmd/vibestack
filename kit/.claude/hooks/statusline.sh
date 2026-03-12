#!/bin/bash
input=$(cat)

# Extract JSON values without jq using grep/sed
get_val() {
  echo "$input" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*[^,}]*" | head -1 | sed 's/.*:[[:space:]]*//' | tr -d '"'
}

dir=$(get_val "current_dir")
model=$(get_val "display_name")
pct=$(get_val "used_percentage")

# Default context to 0 if null/empty
case "$pct" in
  null|"") pct="0" ;;
  *.*) pct="${pct%%.*}" ;;
esac

echo "${dir} | ${model} | ctx: ${pct}%"
