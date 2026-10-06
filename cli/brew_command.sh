local mode=''
[ -z "${args[--mas]:-}" ] || mode=--mas
[ -z "${args[--check]:-}" ] || mode=--check
[ -z "${args[--cleanup]:-}" ] || mode=--cleanup
brew_bundle "$mode"
