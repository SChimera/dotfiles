# Installing haven from the NixOS live ISO

Step-by-step checklist for a clean install of this flake onto `haven`.

Read this on your phone (GitHub web view) or directly on the live ISO
after cloning the repo:

```bash
git clone https://github.com/SChimera/dotfiles.git
cd dotfiles
less INSTALL.md
```

Starting point: you're sitting at `[nixos@nixos:~]$` on the live ISO.

---

## 1. Network

**Ethernet** — usually auto-connects, skip.

**Wi-Fi:**

```bash
sudo systemctl start wpa_supplicant
nmcli device wifi connect "YourSSID" password "YourPassword"
```

Verify:

```bash
ping -c 2 nixos.org
```

---

## 2. Get git

```bash
nix-shell -p git
```

Prompt changes — git is now on PATH for this shell.

---

## 3. Clone the dotfiles

```bash
git clone https://github.com/SChimera/dotfiles.git
cd dotfiles
```

---

## 4. Review `local.nix`

`local.nix` is committed with the values for each host. Open it
to confirm the entry for the machine you're installing on
(username, timezone, git identity, ssh key paths) is correct.
Edit if anything has drifted.

Save: **Ctrl+O, Enter, Ctrl+X**

---

## 5. Run disko

Wipes the three NVMe drives, partitions them, and mounts the new
filesystems under `/mnt`.

```bash
sudo nix --experimental-features 'nix-command flakes' \
  run github:nix-community/disko -- \
  --mode destroy,format,mount \
  --flake .#haven
```

Verify when it finishes:

```bash
mount | grep /mnt
```

Should list `/mnt`, `/mnt/boot`, `/mnt/nix`, `/mnt/home`, `/mnt/games`,
`/mnt/data`, plus snapshot subvolumes.

---

## 6. Generate hardware modules

```bash
sudo nixos-generate-config --root /mnt --no-filesystems
sudo cp /mnt/etc/nixos/hardware-configuration.nix nixos/hosts/
```

`--no-filesystems` matters — disko owns the filesystem definitions.

---

## 7. Wire the hardware file into the flake

```bash
nano nixos/hosts/haven.nix
```

Find line 6:

```nix
    # ./hardware-configuration.nix
```

Remove the `#` and the leading space:

```nix
    ./hardware-configuration.nix
```

Save and exit.

---

## 8. Install

```bash
sudo nixos-install --flake .#haven --no-root-password
```

Takes 20–60 min on first run. Downloads ~5–10 GB and builds the
full system. Walk away.

---

## 9. Set your user password (before reboot)

```bash
sudo nixos-enter --root /mnt -c 'passwd YOUR_USERNAME'
```

Replace `YOUR_USERNAME` with whatever you put in step 4.

Then:

```bash
reboot
```

Pull the Ventoy USB while the machine restarts.

---

## 10. Commit the hardware-configuration

After first login, push the generated hardware file so future
reinstalls of the same machine can skip step 6.

```bash
cd ~/dotfiles    # or wherever your clone is on the new system
git add nixos/hosts/hardware-configuration.nix
git commit -m "Add haven hardware-configuration.nix"
git push
```

---

## Sanity checks

```bash
nvidia-smi          # GPU recognised
hostname            # haven
fish --version      # shell
free -h             # RAM, including zram
btrfs filesystem df /
```

---

## If something goes wrong

- **disko fails partway:** safe to re-run — `destroy,format,mount`
  is idempotent.
- **nixos-install fails on a derivation:** read the error, fix the
  relevant `.nix` file, re-run install (it resumes from cache).
- **No internet on the live ISO:** check `ip a` and redo step 1.
- **Forgot user password:** boot the live ISO again, then:
  ```bash
  sudo mount /dev/disk/by-id/nvme-CT2000T705SSD3_2505E9A44AFF-part2 /mnt
  sudo nixos-enter --root /mnt
  passwd YOUR_USERNAME
  ```
- **Need to start over completely:** boot the ISO and re-run from
  step 3 — the repo is already on GitHub.

---

## Quick reference — disks

| Role  | Disk            | Path                                                   |
|-------|-----------------|--------------------------------------------------------|
| main  | Crucial T705    | `nvme-CT2000T705SSD3_2505E9A44AFF`                     |
| games | Samsung 990 PRO | `nvme-Samsung_SSD_990_PRO_2TB_S6Z2NJ0TA20804Y`         |
| data  | Samsung 990 PRO | `nvme-Samsung_SSD_990_PRO_2TB_S6Z2NJ0TA20813V`         |

Layout lives in `nixos/hosts/haven-disko.nix`.
