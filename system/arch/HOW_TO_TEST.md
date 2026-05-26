# HOW_TO_TEST — End-to-end VM test of the dotfiles refactor

Audience: anyone (human or Claude) who needs to verify a change in
`system/arch/playbooks/`, `roles/`, or any of the dotfiles symlinks
before merging to `main`.

The test exercises the full path from a blank Arch install all the way
to a usable shell:

1. Provision a libvirt qcow2 VM (path B — pacstrap, no Arch installer).
2. Run `init.yml` against the chroot to seed minimum-viable system config.
3. Boot the VM, SSH in as the per-user account.
4. Run `system-sync.yml` to install packages and apply system config.
5. Run `./install` (dotbot) to symlink user-level dotfiles.
6. Launch `zsh` so the new shell config is exercised.
7. Re-run `system-sync.yml --check --diff` — must report `changed=0`.

If you skip any step, you have not E2E-tested the change.

> **Reminder for Claude**: do not claim "done" until step 7's
> idempotency check passes. Type-checks and `--syntax-check` verify
> code correctness, not feature correctness.

---

## 0. Host prerequisites

```bash
# On the host (Arch):
pacman -S --needed libvirt qemu-desktop edk2-ovmf dosfstools \
                   arch-install-scripts virt-install
systemctl enable --now libvirtd
sudo virsh net-start default || true
sudo virsh net-autostart default
```

Confirm:

```bash
virsh net-list           # default should be Active
ls /usr/share/edk2/x64/  # OVMF_CODE.4m.fd must exist (UEFI firmware)
```

---

## 1. Provision the VM (path B — pacstrap into qcow2)

A throwaway test VM. Adjust paths/sizes for your host.

```bash
VM=arch-test
WORK=/tmp/vm-refactor-test
mkdir -p "$WORK"
cd "$WORK"

# Disk image (40 GB sparse qcow2)
qemu-img create -f qcow2 "$WORK/$VM.qcow2" 40G

# Format partitions inside the qcow2 via qemu-nbd
sudo modprobe nbd max_part=8
sudo qemu-nbd --connect=/dev/nbd0 "$WORK/$VM.qcow2"
sudo sgdisk -Z /dev/nbd0
sudo sgdisk -n 1:0:+512M -t 1:ef00 -c 1:EFI    /dev/nbd0
sudo sgdisk -n 2:0:0     -t 2:8300 -c 2:ROOT   /dev/nbd0
sudo mkfs.fat -F32 /dev/nbd0p1
sudo mkfs.ext4 -F  /dev/nbd0p2

# Mount + pacstrap a minimal Arch
sudo mount /dev/nbd0p2 /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/nbd0p1 /mnt/boot
sudo pacstrap -K /mnt base linux linux-firmware grub efibootmgr \
                     networkmanager openssh sudo vim git \
                     python ansible python-passlib

# Generate fstab
sudo genfstab -U /mnt | sudo tee /mnt/etc/fstab

# Throwaway SSH key for VM access (regenerate per test)
ssh-keygen -t ed25519 -N "" -f "$WORK/id_ed25519" -C "vm-test"
```

### Seed a user inside the chroot

```bash
sudo arch-chroot /mnt /bin/bash <<'CHROOT'
useradd -m -G wheel -s /bin/bash archtest
echo 'archtest ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/10-archtest
chmod 440 /etc/sudoers.d/10-archtest
echo 'archtest:archtest' | chpasswd      # known throwaway password
mkdir -p /home/archtest/.ssh
chown archtest:archtest /home/archtest/.ssh
chmod 700 /home/archtest/.ssh
CHROOT

sudo cp "$WORK/id_ed25519.pub" /mnt/home/archtest/.ssh/authorized_keys
sudo chown 1000:1000 /mnt/home/archtest/.ssh/authorized_keys
sudo chmod 600       /mnt/home/archtest/.ssh/authorized_keys
```

### Copy the dotfiles repo into the VM

```bash
sudo cp -r "$HOME/dotfiles" /mnt/home/archtest/
sudo chown -R 1000:1000 /mnt/home/archtest/dotfiles
```

---

## 2. Run `init.yml` against the chroot

```bash
# Per-user values for the test VM
sudo tee /mnt/home/archtest/dotfiles/system/arch/local.yml <<'YML'
username: archtest
hostname: arch-test
timezone: UTC
reflector_country: Singapore
wireless_iface: lo            # placeholder; VM uses virtio NIC
dns_over_tls: false           # libvirt NAT often blocks port 853
YML

# Run init.yml inside the chroot
sudo arch-chroot /mnt /bin/bash -c '
  cd /home/archtest/dotfiles/system/arch
  ansible-galaxy collection install -r requirements.yml
  ansible-playbook playbooks/init.yml \
    -e "new_password=archtest" \
    --connection=local
'
```

Expected outcome: `failed=0`. The DNS symlink task should report
`skipped` (chroot-safe gate).

### Detach the disk and define the VM

```bash
sudo umount /mnt/boot /mnt
sudo qemu-nbd --disconnect /dev/nbd0

# Install bootloader via a second chroot would be cleaner — for path B
# we rely on GRUB installed inline. If first boot lands at the UEFI
# shell, drop a fallback at /boot/EFI/BOOT/BOOTX64.EFI.

virt-install \
  --name "$VM" \
  --memory 4096 \
  --vcpus 2 \
  --disk path="$WORK/$VM.qcow2",bus=virtio \
  --os-variant archlinux \
  --network network=default,model=virtio \
  --graphics none \
  --console pty,target_type=serial \
  --boot loader=/usr/share/edk2/x64/OVMF_CODE.4m.fd,loader.readonly=yes,loader.type=pflash \
  --import --noautoconsole
```

> **VM RAM**: 4 GB is the minimum. Heavy AUR Go/Rust builds
> (e.g. anything pulling in aws-sdk-go) need more — bump to 6 GB if
> you see `signal: killed` during a yay build.

---

## 3. Boot, log in, verify the network

Get the VM's IP:

```bash
virsh domifaddr "$VM"        # wait until you see an entry under "default"
VM_IP=$(virsh domifaddr "$VM" | awk '/ipv4/{print $4}' | cut -d/ -f1)
echo "VM IP: $VM_IP"
```

SSH in:

```bash
ssh -i "$WORK/id_ed25519" -o StrictHostKeyChecking=no archtest@$VM_IP
```

Sanity:

```bash
# Inside the VM:
hostname              # expect: arch-test
locale -a | grep en_US # expect: en_US.utf8  (proves bootstrap locale_gen ran)
ping -c1 1.1.1.1      # outbound must work
ping -c1 archlinux.org # DNS must resolve
```

If DNS fails: check `/etc/resolv.conf` is a symlink to
`/run/systemd/resolve/stub-resolv.conf` and `dns_over_tls: false` in
`local.yml` (libvirt's default NAT often blocks port 853).

---

## 4. Run `system-sync.yml` — full E2E

```bash
# Inside the VM, as archtest:
cd ~/dotfiles/system/arch
ansible-galaxy collection install -r requirements.yml

ansible-playbook playbooks/system-sync.yml --ask-become-pass
# password: archtest
```

Expected: `failed=0`, AUR install completes (or banner warns about
specific failed packages — that's the intended behavior, not a bug).
Skipped tasks for `gpu_amd`, `zfs`, `ddcutil`, `swap`, etc. are
expected because those feature flags default to false.

**Known environmental gotchas (not refactor bugs)**:

- AUR Go/Rust builds OOM — bump VM RAM to 6+ GB.
- `pgp` keyserver unreachable from VM NAT → an AUR package may fail
  to fetch a maintainer key. Re-run; transient.
- Docker's nftables can wipe libvirt's MASQUERADE rule on the host
  after the VM boots — if outbound dies mid-run, re-add:
  `nft add rule ip nat POSTROUTING ip saddr 192.168.122.0/24 ip daddr != 192.168.122.0/24 counter masquerade`

---

## 5. Run `./install` — dotbot symlinks

```bash
# Inside the VM, as archtest:
cd ~/dotfiles
./install
```

Expected: dotbot reports each link as `[OK]`. No prompts. No failures.

Spot-check a few symlinks:

```bash
readlink ~/.zshrc        # should point into ~/dotfiles/config/zshrc
readlink ~/.config/git   # should point into ~/dotfiles/config/git/config/
readlink ~/.config/nvim  # should point into ~/dotfiles/config/neovim/
```

---

## 6. Launch zsh

This exercises the user-level shell config (`~/.zshrc`, atuin,
zoxide, fzf, plugins, etc.) end-to-end.

```bash
# Inside the VM:
exec zsh
```

Expected:

- Prompt loads without errors.
- `which zoxide atuin fzf` all resolve to installed binaries.
- `atuin --version` works.
- `tmux new -d` succeeds; tmux config picks up.
- `nvim --headless +q` exits 0 (config doesn't error on startup).

If any of these fail, the corresponding tool was either not installed
by `system-sync` or not symlinked by `./install`. Fix in the
appropriate role/dotbot config — do not work around in `~/.zshrc`.

---

## 7. Idempotency check — the hard gate

This is the acceptance criterion. From the same shell, immediately
re-run system-sync:

```bash
cd ~/dotfiles/system/arch
ansible-playbook playbooks/system-sync.yml --ask-become-pass --check --diff
```

Required: `changed=0   failed=0`. Any `changed > 0` task on a fresh
re-run is a refactor bug — fix it before merging.

Common idempotency pitfalls to scan for in the recap:

- `lineinfile` tasks that always report changed (regex too narrow).
- `command:`/`shell:` tasks missing `creates:` / `changed_when:`.
- Handler-triggered tasks that re-fire because a watched file's mtime
  drifted (e.g. a copy task that always writes).

---

## 8. Teardown

```bash
# On the host:
sudo virsh destroy  arch-test
sudo virsh undefine arch-test --nvram
rm -rf /tmp/vm-refactor-test
```

---

## Quick reference — file locations

| Path | Purpose |
|---|---|
| `system/arch/playbooks/init.yml` | Chroot-time bootstrap (run once, in pacstrap chroot) |
| `system/arch/playbooks/system-sync.yml` | Idempotent system + package sync (run regularly) |
| `system/arch/inventory/group_vars/all.yml` | Repo-wide defaults; full package lists; feature flags |
| `system/arch/local.yml` (gitignored) | Per-user/per-host overrides |
| `system/arch/local.yml.example` | Documented template of every overridable variable |
| `./install` (repo root) | dotbot — symlinks user-level dotfiles |
| `install.conf.yaml` | dotbot's link map |
