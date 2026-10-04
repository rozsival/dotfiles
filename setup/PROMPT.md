Set up this Mac with me. `bin/dot setup` has already done the automated part.

Use the `workstation-setup` skill (.agents/skills/workstation-setup/SKILL.md) and follow it: run
`bin/dot doctor`, then work through what fails one item at a time in the skill's phase order,
re-running the relevant check after each step, until `bin/dot doctor` reports all checks passed.

I do everything that signs in, approves, or handles a secret: browser logins, 1Password, the App
Store, `gh auth login`, `herdr machine add`, sudo prompts. Tell me exactly what to click or type,
wait until I confirm, then verify it yourself. Never print a secret's value or ask me to paste one
into this chat.
