## Operating System Installation

This document explains how I installed and prepared the Ubuntu Server system used by the Web Server.

The objective was not only to install Linux, but also to create a storage layout that can be maintained and extended later.

---

## 1. Virtual Machine Preparation

I created the virtual machine with QEMU/KVM and managed it through libvirt and virt-manager.

The initial resources were:

| Resource | Configuration |
|---|---|
| Operating System | Ubuntu Server 24.04 LTS |
| CPU | 2 vCPU |
| RAM | 4 GiB |
| Disk | 25 GiB |
| Firmware | BIOS |
| Virtualisation | QEMU/KVM |

I used Ubuntu Server without a graphical desktop because this system is designed to run as a server.

During installation, the VM used DHCP through the libvirt NAT network. This provided temporary network access for package installation.

---

## 2. Operating System Installation

The installation followed these main steps:

1. Create the virtual machine in virt-manager.
2. Assign 2 vCPU, 4 GiB RAM and a 25 GiB disk.
3. Select BIOS firmware.
4. Attach the Ubuntu Server 24.04 LTS ISO.
5. Configure language and keyboard.
6. Use DHCP for the initial network configuration.
7. Use the default Ubuntu package mirror.
8. Create the initial administrative user.
9. Configure the disk manually.
10. Install OpenSSH Server.
11. Install Ubuntu and GRUB.
12. Restart the VM and remove the installation ISO.

The storage configuration was created manually because I wanted to control the partitions, mount points and LVM layout.

---

## 3. Physical Disk Layout

The virtual disk `/dev/vda`, with 25 GiB, uses a GPT partition table.

Before starting the installation, I created this layout:

![Storage Configuration](screenshots/storage-configuration.png)

Three physical partitions were created:

| Partition | Size | Purpose |
|---|---:|---|
| `/dev/vda1` | 1 MiB | BIOS boot partition for GRUB |
| `/dev/vda2` | 1 GiB | ext4 filesystem mounted on `/boot` |
| `/dev/vda3` | ~24 GiB | LVM Physical Volume |

**`/dev/vda1` - BIOS boot:** The VM uses BIOS firmware together with GPT. For this configuration, GRUB needs a small BIOS boot partition. It does not contain a filesystem and it is not mounted.

**`/dev/vda2` - `/boot`:** I created a separate 1 GiB ext4 filesystem for `/boot`. It stores the Linux kernel, `initramfs` images and GRUB files.

**`/dev/vda3` - LVM:** The remaining space was assigned to LVM. This allows the storage to be managed more flexibly than using only fixed partitions.

After installation, I checked the physical disk with:

```bash
sudo fdisk -l /dev/vda
lsblk -f
```

`fdisk` confirms the GPT partition table and physical partitions. `lsblk` shows the relationship between partitions, LVM volumes, filesystems and mount points.

![Physical partitions](screenshots/fdisk-dev-vda.png)

---

## 4. LVM Configuration

I configured `/dev/vda3` as the LVM Physical Volume and created the volume group:

```text
vg-ubuntu
```

Inside this volume group, I created:

| Logical Volume |   Size | Mount point / use |
| -------------- | -----: | ----------------- |
| `lv-root`      | 10 GiB | `/`               |
| `lv-var`       |  8 GiB | `/var`            |
| `lv-swap`      |  2 GiB | Swap              |
| Free space     | ~4 GiB | Future expansion  |

The LVM structure is:

```text
/dev/vda3
    |
    +-- Physical Volume
            |
            +-- vg-ubuntu
                    |
                    +-- lv-root  -> /
                    +-- lv-var   -> /var
                    +-- lv-swap  -> swap
                    +-- ~4 GiB free
```

I validated this configuration with:

```bash
sudo pvs
sudo vgs
sudo lvs
```

![LVM configuration](screenshots/lvm-pvs-vgs-lvs.png)

---

## 5. Root Filesystem

`lv-root` has 10 GiB and is mounted on `/`.

It contains the operating system, installed applications and directories that do not use a separate filesystem.

Because `/var` has its own logical volume, the root filesystem does not need to store the main variable service data.

---

## 6. Separate `/var` Filesystem

I created `lv-var` with 8 GiB and mounted it on `/var`. This directory contains data that can grow over time, such as:

* system logs;
* NGINX logs;
* package caches;
* temporary service data.

If `/var` uses all available space when it shares the root filesystem, important system operations can fail.

A separate `/var` limits this risk because its growth does not directly consume all free space on `/`.

This separation does not replace log rotation or disk monitoring.

---

## 7. Swap

I created a 2 GiB logical volume called:

```text
lv-swap
```

Swap provides additional virtual memory when the system has memory pressure.

I verified that it was active with:

```bash
swapon --show
free -h
```

`swapon --show` confirms the active swap device. `free -h` shows physical memory and swap usage.

---

## 8. Reserved LVM Capacity

I intentionally left approximately 4 GiB free inside `vg-ubuntu`.

This space can later be used to extend `/` or `/var` without changing the physical partition table.

For example, if NGINX logs require more space in the future, `lv-var` can be extended using this reserved capacity.

This is one of the main reasons why I selected LVM.

---

## 9. Persistent Mounts

After installation, I checked the persistent filesystem configuration:

```bash
grep -vE '^[[:space:]]*#|^[[:space:]]*$' /etc/fstab
```

This verifies that the required filesystems and swap are configured to be available after reboot.

The expected persistent storage includes:

* `/`;
* `/boot`;
* `/var`;
* swap.

---

## 10. GRUB Validation

GRUB was installed by the Ubuntu installer.

After the first boot, I verified the bootloader instead of reinstalling it:

```bash
dpkg -l grub-pc grub-common | grep '^ii'
sudo update-grub
ls -lh /boot/grub/grub.cfg
```

These commands confirm that GRUB is installed and that its configuration can detect the installed kernel and `initramfs`.

`/boot/grub/grub.cfg` is generated automatically and should not be edited directly.

---

## 11. Initial System Update

After the first successful boot, I updated the package information and installed available updates:

```bash
sudo apt update
apt list --upgradable
sudo apt upgrade
```

I then checked the package state:

```bash
sudo dpkg --audit
```

This confirms that there are no incomplete package installations.

---

## 12. Final Validation

I performed a final check of the installed system.

**Operating system and virtualisation**

```bash
hostnamectl
cat /etc/os-release
uname -r
systemd-detect-virt
```

### Storage

```bash
sudo fdisk -l /dev/vda
lsblk -f
sudo pvs
sudo vgs
sudo lvs
swapon --show
```

These checks confirm that the operating system, boot configuration, partitions, LVM volumes, filesystems and swap match the planned design.

---

## 13. Result

The final storage design provides:

* a dedicated BIOS boot partition for GRUB;
* a separate `/boot` filesystem;
* LVM for flexible storage management;
* a separate `/var` filesystem;
* active swap;
* approximately 4 GiB reserved for future LVM expansion;
* persistent filesystems across reboots.

This configuration gives the server a clear storage structure and allows future capacity changes without redesigning the complete virtual disk.


## References

- LPIC-1 - Objective 102.1: Design Hard Disk Layout. mount points, swap and LVM. 
- LPIC-1 - Objective 102.2: Install a Boot Manager. GRUB and boot configuration
- LPIC-1 - Objective 104.1: Create Partitions and Filesystems. GPT, filesystems and swap.
- LPIC-1 — Objective 104.3: Control Mounting and Unmounting of Filesystems: persistent mounts and `/etc/fstab`.
