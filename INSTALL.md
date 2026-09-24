# Installing and managing hosts

Both hosts use the same flake and lock file. `nixos/common.nix` and
`nixos/desktop.nix` provide shared system settings; `home/common.nix` provides
shared apps. Each host imports its hardware and optional apps explicitly.

| Host | Configuration |
| --- | --- |
| `haven` | Desktop, NVIDIA, Lian Li, gaming, Ollama, Discord, Zed, speech, Proton Drive |
| `framework` | Framework 13 Pro, Ultra X7 358H, 32 GB RAM, encrypted Btrfs, suspend only, OpenVPN 3, Slack |
| Both | Niri/DMS, browsers, editors, development tools, Codex CLI, Vesktop, Spotify, Proton VPN, Podman |

Framework also includes PowerShell (`pwsh`), SOPS, Pulumi, Terraform, Argo CD
(`argocd`), Rider, the .NET 10 SDK, DBeaver, Tiny RDM, and Charles Proxy. The .NET
SDK is selected per host; Haven keeps its existing SDK.

`local.nix` contains public per-host settings, including Git identities and SSH
key paths. Keep private keys, VPN profiles with credentials, and passphrases
outside this repository.

## Install Framework from Haven

Run the commands marked **Haven** from this checkout. The checkout can contain
uncommitted edits; new Nix files must be added with `git add` so flakes include
them. There is no need to push the branch before installing from Haven.

Framework's hardware scan and WD_BLACK SN7100 4 TB disk ID are recorded in this
checkout. Verify them against the target before installing, especially if the
SSD has been replaced. Evaluation alone cannot verify laptop suspend.

### 1. Boot the laptop's installer

Boot a current NixOS graphical USB image in UEFI mode. This configuration uses
systemd-boot without Secure Boot signing, so disable Secure Boot for this install.
Connect to the network using the desktop network menu, preferably Ethernet for
installation. Open a terminal on the **laptop**:

```bash
sudo systemctl start sshd
sudo passwd root
ip -br address
lsblk -d -o NAME,SIZE,MODEL,SERIAL
ls -l /dev/disk/by-id/
```

The root password is for the temporary live system. Record the laptop's IP and
the by-id path for its internal SSD, excluding entries ending in `-partN`.

### 2. Capture hardware and select the disk

On **Haven**, start Bash because the commands below use Bash syntax:

```bash
bash
cd ~/code/personal/dotfiles
target='root@192.168.1.123' # replace with the laptop's installer IP
ssh "$target" 'hostname; lsblk -d -o NAME,SIZE,MODEL,SERIAL'
ssh "$target" 'nixos-generate-config --no-filesystems --show-hardware-config' \
  > /tmp/framework-hardware.nix
```

Check the SSH host fingerprint against the laptop if prompted. Inspect the
hardware output before updating the saved scan:

```bash
cat /tmp/framework-hardware.nix
cp /tmp/framework-hardware.nix nixos/hosts/framework-hardware.nix
nano nixos/hosts/framework-disko.nix
```

Confirm the configured disk path matches the internal SSD's actual by-id name.
Review `local.nix`, including the work email and username, then:

```bash
git add nixos/hosts/framework-hardware.nix nixos/hosts/framework-disko.nix
nix flake check --no-build
nix eval --raw .#nixosConfigurations.framework.config.disko.devices.disk.main.device
nix build .#nixosConfigurations.framework.config.system.build.toplevel --no-link
```

The evaluated disk path must match the laptop's SSD. The layout creates a 1 GiB
EFI partition plus a LUKS-encrypted Btrfs partition with `/`, `/nix`, `/home`, and
`/.snapshots` subvolumes. There is no disk swap or hibernation. The snapshot
subvolume is available for future use; it does not schedule snapshots or backups.

### 3. Set the disk passphrase and install

On **Haven**, keep the passphrase in a temporary RAM-backed file outside the
checkout. Enter the passphrase you want to type when the laptop boots:

```bash
umask 077
luks_keyfile=$(mktemp /dev/shm/framework-luks.XXXXXX)
trap 'rm -f -- "$luks_keyfile"' EXIT
read -r -s -p 'New disk passphrase: ' luks_passphrase
printf '\n'
printf '%s' "$luks_passphrase" > "$luks_keyfile"
unset luks_passphrase
test -s "$luks_keyfile"
```

Do not continue with an empty passphrase file. The next command **erases the
configured laptop disk**. Verify the target IP and disk ID first.

```bash
(
set -euo pipefail
nix run .#nixos-anywhere -- \
  --flake .#framework \
  --target-host "$target" \
  --disk-encryption-keys /tmp/framework-luks-password "$luks_keyfile" \
  --phases kexec,disko,install
rm -f -- "$luks_keyfile"
ssh "$target" 'rm -f /tmp/framework-luks-password'
)
```

The installer uses the locally locked configuration and builds on Haven. On the
NixOS live image, it can use the running installer. Reboot is deliberately omitted
so the login password and checkout can be saved first. The passphrase file is
used only during installation; it is not installed into the initrd.

### 4. Set the login password and save the checkout

Still on **Haven**, set the installed user's password and save this exact
checkout, including the generated hardware configuration and local edits.
The block stops on any failure and only reboots after all steps succeed:

```bash
(
set -euo pipefail
ssh -t "$target" "nixos-enter --root /mnt -c 'passwd seb'"
tar --exclude='./result' --exclude='./result-*' --exclude='./.direnv' -czf - . \
  | ssh "$target" 'mkdir -p /mnt/home/seb/code/personal/dotfiles && tar -xzf - -C /mnt/home/seb/code/personal/dotfiles'
ssh "$target" "nixos-enter --root /mnt -c 'chown -R seb:users /home/seb/code'"
ssh "$target" reboot
)
```

If you changed the username in `local.nix`, substitute it in this section's
password command, destination paths, and ownership command.

Remove the USB, unlock the disk locally, then log in as `seb`. The installed
configuration does not enable an SSH server; use the laptop console after reboot.

### 5. First login

Generate a separate key on the **laptop**:

```bash
ssh-keygen -t ed25519 -C 'framework' -f ~/.ssh/id_ed25519_framework
ssh-add ~/.ssh/id_ed25519_framework
```

Add the public key to GitHub as an authentication key and a signing key. Then
run `nixswitch` to regenerate the allowed-signers file. Signed commits require
this key. Commit the real hardware configuration and disk ID from Haven or the
laptop so they are available for reinstalls.

Codex CLI, Vesktop, Spotify, and Proton VPN are installed through shared Home
Manager configuration; Slack is specific to Framework. Sign into each app on the laptop. Import the employer's
VPN profile into OpenVPN 3 separately; credentials are not part of this flake.

Framework also installs [jetersen's DMS OpenVPN 3 plugin](https://github.com/jetersen/dms-openvpn3)
with its Python D-Bus dependency. In DMS Settings, open Plugins, enable
**DMS Integration for OpenVPN 3**, then add its widget to DankBar. If it is not
listed after a rebuild, run `dms ipc call plugin-scan scan`. DMS keeps the toggle
and bar placement editable. The plugin can import profiles and connect or
disconnect sessions; interactive credentials, OTP, and browser authentication
still require `openvpn3 session-auth`, following the widget's instructions.
Update the pinned plugin with `nix flake update dms-openvpn3` and rebuild.

Check Wi-Fi, audio, display scaling, and suspend/resume on the actual laptop.
Framework seeds DMS with lock-before-suspend enabled and a five-minute idle-lock
timeout on battery and AC power. These settings stay editable in DMS and are
preserved on rebuilds. Test that the screen is locked after waking from suspend.
OpenVPN 3 uses systemd-resolved for VPN DNS; verify internal work domains
when connected. Test the work VPN and Proton VPN separately before using both
at once.

## Install directly from a live USB

This route also works for Haven. Obtain this checkout on the live system, using
an explicitly published branch containing the host or a copy from Haven. A plain
GitHub clone only contains changes that have been pushed.

Use Bash, install Git with `nix-shell -p git` if needed, and enter the checkout:

```bash
export NIX_CONFIG='experimental-features = nix-command flakes'
host=framework # or haven
```

Review `local.nix` and `nixos/hosts/$host-disko.nix`. For Framework, verify the
disk ID and create `/tmp/framework-luks-password` with mode 0600 using
hidden input as above. Haven's layout erases all three configured NVMe drives.

Generate and review the machine's hardware module before installation:

```bash
nixos-generate-config --no-filesystems --show-hardware-config > /tmp/host-hardware.nix
cat /tmp/host-hardware.nix
cp /tmp/host-hardware.nix "nixos/hosts/$host-hardware.nix"
git add "nixos/hosts/$host-hardware.nix" "nixos/hosts/$host-disko.nix"
nix flake check --no-build
```

After verifying the disk IDs, partition and install using the pinned tools:

```bash
(
set -euo pipefail
sudo nix --extra-experimental-features 'nix-command flakes' run .#disko -- \
  --mode destroy,format,mount --flake ".#$host"
sudo nixos-install --flake ".#$host" --no-root-password
sudo nixos-enter --root /mnt -c 'passwd seb'
sudo mkdir -p /mnt/home/seb/code/personal/dotfiles
sudo cp -a . /mnt/home/seb/code/personal/dotfiles/
sudo nixos-enter --root /mnt -c 'chown -R seb:users /home/seb/code'
rm -f /tmp/framework-luks-password
sudo reboot
)
```

Adjust `seb` if necessary. Save the checkout before rebooting; the live USB's
home directory is temporary. Follow the first-login steps above for Framework.

## Updates and recovery

Run `nixswitch` on either installed host. `nh` selects the configuration matching
its hostname from `~/code/personal/dotfiles`. Commit and pull shared changes
between machines; the hosts stay on the same branch. `nixup` updates their shared
lock file, so evaluate both hosts before applying it:

```bash
nix flake check --no-build
```

To build both configurations without activating them, use `nix flake check`.
Neither command tests physical hardware or reformats disks.

If installation fails after formatting, fix the build error and rerun
`nixos-install`, or use `nixos-anywhere --phases install` with the same flake and
target. Do not repeat `destroy,format,mount` unless you intend to erase the disk
again. After rebooting back into an installer, recreate Framework's temporary
passphrase file and use `nix run .#disko -- --mode mount --flake .#framework` as
root to unlock and mount the existing layout before `nixos-enter` or reinstalling.

References: [nixos-anywhere quickstart](https://nix-community.github.io/nixos-anywhere/quickstart.html),
[installation secrets](https://nix-community.github.io/nixos-anywhere/howtos/secrets.html),
[disko](https://github.com/nix-community/disko).
