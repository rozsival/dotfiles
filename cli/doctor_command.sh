local name entry answer
# Fixes install software and ask for sudo, Touch ID and 1Password: a person's terminal only.
if [ -n "${args[--fix]:-}" ] && ! { [ -t 0 ] && [ -t 1 ]; }; then
  die 'doctor --fix runs installers that ask for sudo, Touch ID and 1Password: run it in your own terminal'
fi
doctor_checks
doctor_summary
if [ ${#FIXES[@]} -gt 0 ] && [ -z "${args[--fix]:-}" ]; then
  printf '%s fix(es) dot can run itself: %s\n' "${#FIXES[@]}" "$(printf '%s, ' "${FIXES[@]}" | sed 's/, $//')"
  hint 'dot doctor --fix, in your own terminal'
elif [ ${#FIXES[@]} -gt 0 ]; then
  printf '\nWill run, in this order (the rest needs you; see the hints above):\n'
  for name in $FIX_ORDER; do
    for entry in "${FIXES[@]}"; do
      [ "${entry%% *}" != "$name" ] || info "$entry"
    done
  done
  read -r -p "    Run them? [y/N] " answer || answer=''
  case "$answer" in
  [yY]*)
    doctor_fix
    FAILS=0 WARNS=0 FIXES=()
    step 'Checking again'
    doctor_checks
    doctor_summary
    # A fix can uncover the next: devbox agent install brings the identity renderer.
    [ ${#FIXES[@]} = 0 ] || hint 'still fixable: dot doctor --fix again'
    ;;
  esac
fi
[ "$FAILS" = 0 ]
