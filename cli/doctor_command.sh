doctor_system
doctor_dotfiles
doctor_identity
doctor_devbox
doctor_agents
printf '\n'
if [ $FAILS = 0 ]; then
  printf '%s%s✓ all checks passed%s (%d warning(s))\n' "$B" "$GRN" "$RST" "$WARNS"
else
  printf '%s%s✗ %d check(s) failing%s, %d warning(s)\n' "$B" "$RED" "$FAILS" "$RST" "$WARNS"
  return 1
fi
