# Arch Linux Ansible playbooks

Two playbooks drive the lifecycle of an Arch box:

- **`playbooks/init.yml`** — first-time install. Runs once from inside
  `arch-chroot /mnt` on a live ISO, as root, before reboot.
- **`playbooks/system-sync.yml`** — ongoing config sync. Runs on the
  booted system as your regular user, with `--ask-become-pass`.

Everything else (16 roles, group_vars, inventory, ansible.cfg) sits
under this directory.

## First-time setup

Per-user values (username, hostname, timezone, …) live in `local.yml`,
which is gitignored. Copy the template and fill it in before running
either playbook.

```bash
cd system/arch
cp local.yml.example local.yml
$EDITOR local.yml
```

Then bootstrap Ansible and the Galaxy collections it depends on:

```bash
./ansible-setup.sh
```

This installs `ansible`, `python-passlib`, and the three collections
listed in `requirements.yml` (`kewlfft.aur`, `community.general`,
`ansible.posix`) into `.ansible/collections/`.

## Phase 1 — install (init.yml)

From inside `arch-chroot /mnt` on the live ISO, as root, after
`pacstrap` has put the base system on disk:

```bash
ansible-playbook playbooks/init.yml
```

`init.yml` prompts only for the root/user password. Everything else
comes from `local.yml`. It runs the six roles needed to make the
machine bootable: `bootstrap`, `bootloader`, `users`, `network`,
`dns`, `pacman`. Every role here passes `start_services: false`
because `systemctl start` doesn't work in a chroot — services are
only enabled. They start on first real boot.

Exit the chroot, unmount, reboot.

## Phase 2 — ongoing sync (system-sync.yml)

On the booted system, as your unprivileged user:

```bash
ansible-playbook playbooks/system-sync.yml --ask-become-pass
```

Re-runnable any time. A clean second run should report `changed=0`.

## Feature flags

Optional roles are gated on `features.*` booleans. Defaults live in
`group_vars/all.yml`; override per host in `local.yml`. See
`local.yml.example` for the full list. Default-on: `docker`,
`display_manager`, `user_tools`. Default-off: `gpu_amd`, `zfs`,
`ddcutil`, `swap`.

## Useful flags

- `--check --diff` — dry run with diff output for changed files.
- `--tags <role>` — run only one role's tasks. Every `import_role`
  carries a role-name tag (`--tags docker`, `--tags maintenance`, …).
  The pacman cache refresh task is tagged `always` so it runs even
  with `--tags`.

## Handler-driven restarts

Six services restart only when their config changes (not every run):

| Role | Service | Action |
|------|---------|--------|
| `security` | `sshd` | reload (zero-downtime) |
| `network` | `systemd-networkd` | restart |
| `dns` | `systemd-resolved` | restart |
| `docker` | `docker` | restart |
| `bootstrap` | (locale) | `locale-gen` rerun via `community.general.locale_gen` |
| `bootloader` | (grub) | `grub-mkconfig` rerun |

**Docker caveat:** restarting the docker daemon kills any running
containers. If you have long-running workloads, plan around it.

## Before commit

Lint locally:

```bash
ansible-lint playbooks/ roles/
```

`.ansible-lint` runs at the `moderate` profile. No CI; ad-hoc only.
