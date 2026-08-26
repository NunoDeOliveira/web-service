# Base System Administration

This document explains how I prepared the base Ubuntu Server system before configuring the network, SSH and NGINX.

The work covers:

- package maintenance;
- system identity;
- timezone and locale;
- users and groups;
- administrator privileges;
- passwords and account status;
- home directory permissions;
- final validation.

The main objective was to create a controlled Linux base with separate roles and clear permissions.

---

## 1. Check the Initial System

Before making changes, I checked the current system and the administrator account.

```bash
hostnamectl
cat /etc/os-release
uname -r
```

```bash
whoami
id
groups
```

`hostnamectl` shows the system hostname and basic system information.

`whoami` shows the current user.

`id` shows the UID, primary GID and additional groups of the current user.

`groups` shows the groups assigned to the user.

This check gives a known starting point before changing accounts or privileges.

![Current user validation](../screenshots/check-current-user.png)

---

## 2. Package Maintenance

Before installing new services, I updated the local APT package index:

```bash
sudo apt-get update
```

`apt-get update` downloads the current package information from the configured repositories. It does not install packages.

I then checked which packages could be upgraded:

```bash
apt list --upgradable
```

![Package list](../screenshots/list-packets.png)

I installed the normal available upgrades:

```bash
sudo apt-get upgrade
```

If some packages required dependency changes, I used:

```bash
sudo apt-get dist-upgrade
```

`upgrade` updates installed packages without removing installed packages.

`dist-upgrade` can also change dependencies when this is required to complete an upgrade.

I checked the system again:

```bash
apt list --upgradable
sudo dpkg --audit
```

`dpkg --audit` checks for packages that are only partly installed or have other package state problems.

![Upgradable packages](../screenshots/list-upgradable.png)

If the system reports that a reboot is required, I can check it with:

```bash
test -f /var/run/reboot-required \
    && cat /var/run/reboot-required \
    || echo "No reboot required"
```

A reboot is only made when required:

```bash
sudo reboot
```

This work is related to **LPIC-1 Objective 102.4 — Debian Package Management**.

---

## 3. System Identity

I used a clear hostname so the server can be identified in remote sessions, logs and administrative commands.

The hostname used for the server is:

```text
web-server
```

It can be configured with:

```bash
sudo hostnamectl set-hostname web-server
```

I checked the final configuration with:

```bash
hostnamectl
hostname
```

The static hostname is persistent across reboots.

---

## 4. Timezone Configuration

Correct time is important for logs, SSH events and troubleshooting because events from different services need correct timestamps.

I first listed the available timezones:

```bash
timedatectl list-timezones
```

I configured the server timezone:

```bash
sudo timedatectl set-timezone Europe/Madrid
```

I checked the result:

```bash
timedatectl
```

The command shows:

- local time;
- UTC time;
- configured timezone;
- synchronisation status.

Time and timezone management are related to **LPIC-1 Objective 108.1 — Maintain System Time**.

---

## 5. Locale Validation

The locale controls language and regional settings used by programs.

I checked the current locale with:

```bash
locale
```

I also checked the systemd locale configuration:

```bash
localectl status
```

Important variables include:

- `LANG` — default system locale;
- `LC_TIME` — date and time format;
- `LC_NUMERIC` — number format;
- `LC_MESSAGES` — language used by program messages;
- `LC_ALL` — overrides the other locale variables when it is defined.

The locale configuration is related to **LPIC-1 Objective 107.3 — Localisation and Internationalisation**.

![Time and locale validation](../screenshots/timedatectl-locale-a2.png)

---

# 6. User and Group Design

I did not want all accounts to have the same permissions.

I defined three role groups:

| Group | Purpose |
|---|---|
| `admin` | System administration |
| `developers` | Development tasks |
| `operators` | Monitoring and operational tasks |

The users are:

| User | Role group | Responsibility |
|---|---|---|
| `nuno` | `admin` | System administration |
| `dev` | `developers` | Development |
| `ops` | `operators` | Monitoring and operations |

The role groups are separate from the private primary group that Linux can create for each user.

This design gives a base for later access control without giving administrative privileges to every account.

User and group administration is part of **LPIC-1 Objective 107.1 — Manage user and group accounts and related system files**.

---

## 7. Create the Role Groups

Before creating them, I checked whether the groups already existed:

```bash
getent group admin
getent group developers
getent group operators
```

I created the groups:

```bash
sudo groupadd admin
sudo groupadd developers
sudo groupadd operators
```

I checked the result:

```bash
getent group admin
getent group developers
getent group operators
```

`groupadd` creates a new group.

`getent group` reads group information through the system account database and is useful for validation.

![Group creation](../screenshots/creating-groups.png)

---

# 8. Create the User Accounts

The administrator account `nuno` already existed because it was created during the Ubuntu installation.

I checked it first:

```bash
id nuno
getent passwd nuno
```

I then created the Development account:

```bash
sudo useradd -m -U -s /bin/bash dev
```

And the Operations account:

```bash
sudo useradd -m -U -s /bin/bash ops
```

The options mean:

| Option | Purpose |
|---|---|
| `-m` | Create the user's home directory |
| `-U` | Create a private group with the same name as the user |
| `-s /bin/bash` | Set Bash as the login shell |

For example:

```text
dev
├── home: /home/dev
├── primary group: dev
└── shell: /bin/bash
```

The files used as templates for new home directories come from:

```bash
ls -la /etc/skel
```

`/etc/skel` is also included in LPIC-1 Objective 107.1.

---

# 9. Assign the Role Groups

I added the administrator account to the `admin` role:

```bash
sudo usermod -aG admin nuno
```

I added `dev` to the Developers role:

```bash
sudo usermod -aG developers dev
```

I added `ops` to the Operators role:

```bash
sudo usermod -aG operators ops
```

The options are:

| Option | Purpose |
|---|---|
| `-G` | Set supplementary groups |
| `-a` | Append the group without removing existing supplementary groups |

The `-a` option is important when using `-G`. Without it, existing supplementary group memberships can be replaced.

I checked the result:

```bash
id nuno
id dev
id ops
```

And:

```bash
getent group admin
getent group developers
getent group operators
```

![Users and role groups](../screenshots/add-admin-add-users.png)

---

# 10. Configure Administrative Privileges

The custom `admin` group represents the system administration role.

On Ubuntu, command elevation is controlled by `sudo`.

I checked the Ubuntu sudo group:

```bash
getent group sudo
```

The administrator account was added to it when required:

```bash
sudo usermod -aG sudo nuno
```

I checked the final account:

```bash
id nuno
```

I also checked which commands the administrator can run with sudo:

```bash
sudo -l
```

The `dev` and `ops` accounts were not added to the `sudo` group.

This keeps administrative privileges separate from development and operations accounts.

The use of `sudo` and `/etc/sudoers` is covered by **LPIC-1 Objective 110.1 — Perform Security Administration Tasks**.

The sudo configuration should be changed with:

```bash
sudo visudo
```

rather than editing `/etc/sudoers` directly.

---

# 11. Configure User Passwords

I assigned passwords to the new interactive users:

```bash
sudo passwd dev
```

```bash
sudo passwd ops
```

`passwd` updates the authentication password of an account.

The password is not displayed while it is entered.

I did not store passwords in the repository or in screenshots.

I checked the password state with:

```bash
sudo passwd -S nuno
sudo passwd -S dev
sudo passwd -S ops
```

`passwd -S` shows account password status without displaying the password hash.

---

# 12. Check Password Ageing

I checked the password ageing information for the role accounts:

```bash
sudo chage -l dev
```

```bash
sudo chage -l ops
```

`chage -l` displays information such as:

- last password change;
- password expiry;
- minimum password age;
- maximum password age;
- warning period;
- account expiry.

This does not change the policy. It validates the current account configuration.

`chage` is part of **LPIC-1 Objective 107.1**.

![Password ageing](../screenshots/chage-l-dev-ops.png)

---

# 13. Check the Linux Account Databases

Linux stores account information in several important files.

I checked their permissions:

```bash
ls -l /etc/passwd /etc/group /etc/shadow /etc/gshadow
```

The files have different purposes:

| File | Purpose |
|---|---|
| `/etc/passwd` | User account information |
| `/etc/group` | Group information |
| `/etc/shadow` | Protected password and ageing information |
| `/etc/gshadow` | Protected group information |

`/etc/passwd` and `/etc/group` can be read by normal users because they contain account information needed by the system.

The sensitive password information is stored in `/etc/shadow`, which has restricted access.

I used `getent` to read the account information without directly publishing sensitive files:

```bash
getent passwd nuno
getent passwd dev
getent passwd ops
```

```bash
getent group admin
getent group developers
getent group operators
```

The final account membership was checked with:

```bash
id nuno
id dev
id ops
```

![Final user and group validation](../screenshots/check-groups-and-users.png)

This screenshot is important because it shows the **final result**, not only the commands used to create the accounts.

---

# 14. Home Directory Permissions

I checked the home directories:

```bash
ls -ld /home/nuno /home/dev /home/ops
```

The administrator home directory was restricted:

```bash
sudo chmod 700 /home/nuno
```

For the role accounts I used:

```bash
sudo chmod 750 /home/dev
sudo chmod 750 /home/ops
```

The octal permissions mean:

### `700`

```text
Owner:  rwx
Group:  ---
Others: ---
```

Only the owner can access the directory.

### `750`

```text
Owner:  rwx
Group:  r-x
Others: ---
```

The owner has full access, the group has read and execute permissions, and other users have no access.

I validated the result:

```bash
ls -ld /home/nuno /home/dev /home/ops
```

![Home directory permissions](../screenshots/checking-the-permits.png)

File permissions and ownership are covered by **LPIC-1 Objective 104.5 — Manage File Permissions and Ownership**.

---

# 15. Validate Role Separation

I checked every account separately:

```bash
id nuno
id dev
id ops
```

Expected role separation:

```text
nuno -> admin + sudo
dev  -> developers
ops  -> operators
```

I also checked that only the administrator has sudo privileges:

```bash
sudo -l -U nuno
```

The Development and Operations users should not receive general root privileges.

Their group memberships can be checked with:

```bash
groups dev
groups ops
```

This validates the access model before SSH and service permissions are configured.

---

# 16. Test the Accounts

A login shell can be opened as another account with:

```bash
sudo su - dev
```

I checked:

```bash
whoami
pwd
groups
```

The expected home directory is:

```text
/home/dev
```

I returned to the administrator account:

```bash
exit
```

I repeated the test for Operations:

```bash
sudo su - ops
```

Then:

```bash
whoami
pwd
groups
```

And returned:

```bash
exit
```

This verifies that the accounts have valid home directories, login shells and group memberships.

---

# 17. Final System Validation

At the end of the phase, I performed a final validation.

### System identity

```bash
hostnamectl
```

### Time

```bash
timedatectl
```

### Locale

```bash
locale
```

### Users

```bash
id nuno
id dev
id ops
```

### Groups

```bash
getent group admin
getent group developers
getent group operators
getent group sudo
```

### Password status

```bash
sudo passwd -S nuno
sudo passwd -S dev
sudo passwd -S ops
```

### Password ageing

```bash
sudo chage -l dev
sudo chage -l ops
```

### Home directory permissions

```bash
ls -ld /home/nuno /home/dev /home/ops
```

### Package state

```bash
sudo dpkg --audit
apt list --upgradable
```

### General system state

```bash
systemctl is-system-running
systemctl --failed
```

This final validation is more useful than only showing the creation commands because it checks the real state of the server after the changes.

---

# 18. Evidence

I kept evidence of the final configuration rather than taking a screenshot of every command.

The main evidence for this phase is:

| Evidence | What it proves |
|---|---|
| `list-upgradable.png` | Package maintenance |
| `timedatectl-locale-a2.png` | Timezone and locale configuration |
| `creating-groups.png` | Creation of role groups |
| `check-groups-and-users.png` | Final user and group membership |
| `chage-l-dev-ops.png` | Password ageing and account status |
| `checking-the-permits.png` | Filesystem permissions |

Creation commands are useful as procedure evidence, but the final validation screenshots are more important because they show that the configuration was applied correctly.

---

# 19. LPIC-1 Mapping

| Implementation | LPIC-1 objective | Practical use |
|---|---|---|
| APT update and upgrade | 102.4 — Debian Package Management | Maintain the installed operating system |
| File and directory permissions | 104.5 — Manage File Permissions and Ownership | Restrict access to user data |
| Users and groups | 107.1 — Manage User and Group Accounts | Create and manage role-based accounts |
| `passwd` and `chage` | 107.1 — Manage User and Group Accounts | Manage authentication and account ageing |
| `/etc/passwd`, `/etc/shadow`, `/etc/group` | 107.1 | Validate Linux account databases |
| Locale | 107.3 — Localisation and Internationalisation | Configure regional system behaviour |
| Timezone and time | 108.1 — Maintain System Time | Keep correct timestamps for system events |
| `sudo` privileges | 110.1 — Security Administration Tasks | Control privileged administration |





