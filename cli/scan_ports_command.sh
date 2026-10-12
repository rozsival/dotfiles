ports="${args[ports]:-}"
if [ -n "$ports" ]; then
  [ -z "${args[--check]:-}" ] || die '--check takes no ports'
  project="$(scan_ports_project "${args[--project]}")" || exit 1
  scan_ports_register "$project" "$ports"
fi
scan_ports_sync "${args[--check]:-0}"
[ $FAILS = 0 ]
