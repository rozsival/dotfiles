# bashly stores a repeatable arg as one string of %q-quoted values.
local -a titles
eval "titles=(${args[title]:-})"
vault_sync pull "${args[--force]:-0}" "${titles[@]}"
