# AGENTS.md

Ansible roles that configure a macOS work laptop. Runs against `localhost`.

## Conventions

- Every YAML file uses the `.yaml` extension. Never `.yml`.
- All tunable data lives in `group_vars/all.yaml`. Roles stay generic and read
  variables. To change what the laptop looks like, edit that file, not a role.
- Roles hold behaviour. If a value is specific to this person or this machine,
  it belongs in `group_vars/all.yaml`.
- Record the reason behind a choice here, not as a comment in a YAML file.
  Comments in `group_vars/all.yaml` are section labels only.
- Verify changes with `--check` before applying. Prove claims about module
  behaviour against a scratch domain rather than the real machine.

## Decisions

### Defaults are listed even when they match Apple's

`macos_defaults` includes keys already at the macOS default. This pins the value
if Apple changes the default in a later release, corrects drift when an app or
System Settings moves it, and keeps the whole intended state in one file.

### Removing a setting uses `state: absent`, never line deletion

Ansible keeps no record of what it previously managed. Deleting a line from
`macos_defaults` leaves the old value on the machine and erases the evidence
that it was ever set. Changing the entry to `state: absent` deletes the key, so
macOS supplies its own default.

`state` defaults to `present`. Entries with `state: absent` take no `type` or
`value`.

### `LSQuarantine` is `absent` rather than `value: "true"`

This key controls Gatekeeper's "downloaded from the internet" warning. It was
disabled on this machine before Ansible managed it. Deleting the key restores
whatever Apple intends, which avoids pinning a guessed value.

### Tap to click needs four keys

`com.apple.AppleMultitouchTrackpad Clicking` alone has no effect. The built-in
and the external Magic Trackpad each have their own `Clicking` key, and
`NSGlobalDomain com.apple.mouse.tapBehavior` is what the session actually reads.
The `currentHost` variant covers the login window. All four are required.

### Secrets resolve through 1Password at template time

`~/.zshrc` is rendered by the `dotfiles` role. Secrets come from
`lookup('community.general.onepassword', uuid)`, so only item UUIDs are
committed. The `op` CLI must be signed in when the playbook runs, otherwise the
template fails.

Because the rendered file holds real tokens, it is written mode `0600` and the
task sets `no_log`.

### chezmoi was replaced by the `dotfiles` role

Dotfiles were managed by chezmoi against `sonniesedge/dotfiles`. That is now
Ansible's job. `roles/dotfiles/tasks/remove_chezmoi.yaml` cleans up the old
install and is guarded by `chezmoi_remove`, off by default.

### `EE_AI_GATEWAY_API_KEY` is deliberately absent

It was hardcoded in plain text in the old `dot_zshrc.tmpl` and is not in
1Password. Carrying it over would commit a live key. Treat the old key as
leaked. To restore it, add it to 1Password and reference the UUID in
`zsh_secrets`.

## Gotchas

- **`osx_defaults` honours check mode.** A `--check` run reports `changed` but
  writes nothing. Verified against a scratch domain.
- **`osx_defaults` fails on type mismatch.** If the key already exists with a
  different type, the run errors rather than coercing. `com.apple.dock tilesize`
  is stored as `float`, not `int`.
- **Keyboard and text-substitution settings apply per app at launch.** The
  `Restart affected apps` handler only covers `macos_apps_to_restart`. The rest
  need a logout or an app restart.
- **`autohide-delay: 0` removes the pause, not the animation.**
  `autohide-time-modifier` controls the slide itself.
- **`CreateDesktop: false` hides every desktop icon.** Files stay in
  `~/Desktop`, but the desktop becomes non-interactive.
- **The login shell is never changed automatically.** `chsh` needs a password,
  so the `shell` role reports and stops.
- **`~/.zshrc` is generated.** Hand edits are lost on the next run. Machine
  specific settings go in `~/.zshrc.local`, which Ansible creates once and never
  overwrites.
