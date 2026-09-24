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

Boot a current NixOS graphical USB image in UEFI mode. Disable Secure Boot for
the initial `framework-bootstrap` installation. Section 6 enables signing and
TPM unlocking after the first successful boot.
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
nix build .#nixosConfigurations.framework-bootstrap.config.system.build.toplevel --no-link
```

The evaluated disk path must match the laptop's SSD. The layout creates a 1 GiB
EFI partition plus a LUKS-encrypted Btrfs partition with `/`, `/nix`, `/home`, and
`/.snapshots` subvolumes. There is no disk swap or hibernation. The snapshot
subvolume is available for future use; it does not schedule snapshots or backups.

### 3. Set the disk passphrase and install

On **Haven**, keep the passphrase in a temporary RAM-backed file outside the
checkout. This passphrase unlocks the first boots and remains your recovery
method after TPM enrollment. Save it in a password manager accessible from
another device:

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
  --flake .#framework-bootstrap \
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

Framework reuses Haven's existing SSH key for GitHub authentication and Git
signing. Copy both `~/.ssh/id_ed25519_haven` and its `.pub` file from Haven to
the same paths on the **laptop**, using an authenticated SSH connection or an
encrypted removable drive. Keep the private key outside this checkout and the
Nix store. Preserve any existing destination key rather than overwriting it.

On the **laptop**, set permissions and load the key into its SSH agent:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519_haven
chmod 644 ~/.ssh/id_ed25519_haven.pub
ssh-add ~/.ssh/id_ed25519_haven
```

Use the key's existing passphrase if prompted. Its existing GitHub registrations
apply on both hosts. For verified commits, the public key must also be registered
as a signing key on GitHub.

Complete section 6 before using `nixswitch`, which selects the final `framework`
configuration and requires local Secure Boot keys. The rebuild also regenerates
the allowed-signers file from the copied public key.

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

### 6. Enable Secure Boot and automatic disk unlocking

These configurations are stages for the same laptop, with hostname `framework`:

| Flake configuration | Purpose |
| --- | --- |
| `framework-bootstrap` | Initial installation with unsigned systemd-boot |
| `framework-secureboot` | Sign boot files and enable Secure Boot before creating the TPM policy |
| `framework` | Normal use with Secure Boot and measured TPM unlocking |

On the installed **laptop**, create its signing keys and install signed boot files:

```bash
cd ~/code/personal/dotfiles
sudo sbctl create-keys
sudo nixos-rebuild boot --flake .#framework-secureboot
sudo sbctl verify
```

The systemd-boot and `nixos-generation-*.efi` images must be signed. Separate
kernel files may appear unsigned because the signed Lanzaboote image verifies
their hashes. Keep `/var/lib/sbctl` private and include it in an encrypted backup;
never add signing keys to Git or the Nix store.

Reboot into firmware settings. Under Framework's **Administer Secure Boot**,
delete the individual signatures in **PK Options**, **KEK Options**, and **DB
Options** to enter Setup Mode. Preserve **DBX**. Do not use **Erase all Secure
Boot Settings**. Save and boot NixOS again, entering the disk passphrase.

Enroll the laptop's keys together with Microsoft and firmware certificates:

```bash
sudo sbctl enroll-keys --microsoft --firmware-builtin
```

Reboot into firmware settings, enable **Enforce Secure Boot**, save, and boot
NixOS. Enter the disk passphrase, then confirm `bootctl status` reports Secure
Boot **enabled**. If it cannot boot, disable enforcement again and inspect the
signed files before continuing.

Now enable the TPM policy and reboot once more using the passphrase:

```bash
sudo nixos-rebuild boot --flake .#framework
sudo reboot
```

After that boot, check the policy service and the PCRs it covers:

```bash
sudo systemctl status systemd-pcrlock-make-policy.service
sudo jq '[.pcrValues[].pcr] | unique | sort' /var/lib/systemd/pcrlock.json
```

The service must have succeeded and the list must include **0, 4, and 7**. These
cover firmware, the boot chain, and Secure Boot policy. Do not enroll an incomplete
policy. Check `bootctl status` still reports Secure Boot enabled.

Enroll the TPM, entering the existing disk passphrase locally when prompted:

```bash
sudo systemd-cryptenroll \
  --tpm2-device=auto \
  --tpm2-pcrs= \
  --tpm2-with-pin=no \
  --tpm2-pcrlock=/var/lib/systemd/pcrlock.json \
  /dev/disk/by-partlabel/disk-main-luks
sudo reboot
```

The empty `--tpm2-pcrs=` avoids adding a second static PCR binding; the managed
policy supplies the checks. This adds a TPM slot and preserves the original
passphrase slot. No disk passphrase should be needed for a normal boot afterward.
The login password and screen lock still apply.

Verify another reboot after a normal `nh os switch`. Lanzaboote updates the
managed policy with the installed generations, keeping up to eight boot entries.
Firmware changes can require the recovery passphrase. `systemd-pcrlock` is still
experimental, so keep that recovery method available even after successful tests.
If TPM unlocking fails, use the passphrase and investigate before changing any
LUKS slots. Never wipe the passphrase slot during TPM recovery.

References: [Lanzaboote setup](https://nix-community.github.io/lanzaboote/getting-started/prepare-your-system.html),
[Framework firmware enrollment](https://nix-community.github.io/lanzaboote/getting-started/enable-secure-boot.html),
[measured boot](https://nix-community.github.io/lanzaboote/how-to-guides/enable-measured-boot.html).

## Install directly from a live USB

This route also works for Haven. Obtain this checkout on the live system, using
an explicitly published branch containing the host or a copy from Haven. A plain
GitHub clone only contains changes that have been pushed.

Use Bash, install Git with `nix-shell -p git` if needed, and enter the checkout:

```bash
export NIX_CONFIG='experimental-features = nix-command flakes'
host=framework # or haven
install_config=framework-bootstrap # use haven when installing Haven
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
sudo nixos-install --flake ".#$install_config" --no-root-password
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
