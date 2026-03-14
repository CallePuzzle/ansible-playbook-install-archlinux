# AGENTS.md - Ansible Playbook for Arch Linux Installation

## Project Overview

This repository contains Ansible playbooks for automating the installation and configuration of Arch Linux on various devices. It supports two main use cases:

1. **Fresh Arch Linux Installation** (`laptop/`): For installing Arch Linux from scratch on bare metal with LUKS encryption, LVM, and EFI boot
2. **Post-Installation Configuration** (`archlinux/`): For configuring user environment, desktop settings, and applications after base installation
3. **Steam Deck Configuration** (`steam-deck/`): For enabling desktop mode on Steam Deck devices running SteamOS

### Supported Hosts

| Host | Type | Description |
|------|------|-------------|
| `msi` | Laptop | MSI Modern 15 - Intel-based laptop |
| `tuxedo` | Laptop | Tuxedo device - AMD-based laptop |
| `desk` | Steam Deck | Steam Deck in desktop mode |

### Technology Stack

- **Automation**: Ansible (Core)
- **Encryption**: LUKS2 for full disk encryption
- **Volume Management**: LVM2 with logical volumes for swap and root
- **Boot**: EFI with systemd-boot style configuration via efibootmgr
- **Desktop Environment**: KDE Plasma with SDDM display manager
- **Shell**: Fish with fisher plugin manager
- **Editor**: Zed (primary), Emacs

## Project Structure

```
.
├── inventory.ini              # Main inventory defining all hosts
├── .vault-password-file       # Ansible vault password (excluded from git)
├── .gitignore                 # Excludes .venv and .vault-password-file
│
├── archlinux/                 # Post-installation configuration playbooks
│   ├── 000-base.yaml          # Base system: user creation, Xorg/Plasma, mirror ranking
│   ├── 010-configure.yaml     # User environment: packages, KDE settings, fish, SSH
│   └── 020-developer.yaml     # Developer tools: Zed editor configuration
│
├── laptop/                    # Fresh installation playbooks (run from Arch ISO)
│   ├── 000-platform-base.yaml # Disk partitioning, LUKS, LVM, base packages
│   ├── 005-mount-the-installation.yaml  # Mount existing installation
│   └── 010-configure-chroot-env.yaml    # Chroot configuration, bootloader
│
├── steam-deck/                # Steam Deck specific playbooks
│   ├── playbook.yaml          # Initial desktop mode setup
│   └── after-SO-upgrade.yaml  # Reinstall packages after SteamOS updates
│
├── host_vars/                 # Host-specific variables (encrypted with vault)
│   ├── msi.yaml              # MSI laptop: disk config, LUKS passwords, user hashes
│   └── tuxedo.yaml           # Tuxedo device: similar configuration
│
└── files/                     # Static files to deploy
    ├── git.config            # Git configuration template
    ├── id_rsa                # SSH private key (sensitive)
    ├── id_rsa.pub            # SSH public key
    ├── id_ed25519            # SSH Ed25519 private key (sensitive)
    └── id_ed25519.pub        # SSH Ed25519 public key
```

## Setup and Dependencies

### Initial Setup

```bash
# Create Python virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install Ansible
pip install ansible

# Install required Ansible collections
ansible-galaxy collection install community.crypto community.general kewlfft.aur
```

**Important**: Always activate the virtual environment before running playbooks:
```bash
source .venv/bin/activate
```

## Running Playbooks

### Laptop Fresh Installation

This is a two-phase process run from the Arch Linux Live ISO:

```bash
# Phase 1: Partition, encrypt, and install base system
ansible-playbook -i inventory.ini --vault-password-file .vault-password-file laptop/000-platform-base.yaml -k

# Phase 2: Configure chroot environment and bootloader
ansible-playbook -i inventory.ini --vault-password-file .vault-password-file laptop/010-configure-chroot-env.yaml -k
```

After installation, exit chroot and reboot:
```bash
root@archiso# exit
root@archiso# reboot
```

### Post-Installation Configuration

After the base system is installed and rebooted:

```bash
# First run (as root, requires SSH root login temporarily enabled)
ansible-playbook -i inventory.ini --vault-password-file .vault-password-file archlinux/000-base.yaml -k

# Subsequent runs (as user with sudo)
ansible-playbook -i inventory.ini --vault-password-file .vault-password-file archlinux/010-configure.yaml -kK
ansible-playbook -i inventory.ini --vault-password-file .vault-password-file archlinux/020-developer.yaml -kK
```

### Steam Deck Configuration

```bash
# Initial desktop mode setup
ansible-playbook -i inventory.ini --vault-password-file .vault-password-file steam-deck/playbook.yaml -kK

# After SteamOS upgrades (reinstalls packages)
ansible-playbook -i inventory.ini --vault-password-file .vault-password-file steam-deck/after-SO-upgrade.yaml -kK
```

## Host Variables Structure

Host variables in `host_vars/` define device-specific configuration:

```yaml
# Disk configuration
disk_name: "/dev/nvme0n1"
boot_partition: "/dev/nvme0n1p1"
boot_partition_size: "512MiB"

# LUKS encryption settings
luks_device:
  device: "/dev/nvme0n1p2"
  name: "cryptlvm"
  type: "luks2"
  uuid: "..."  # Optional, for boot cmdline

# Encrypted passphrase (ansible-vault encrypted)
luks_device_passphrase: !vault |
  $ANSIBLE_VAULT;1.1;AES256
  ...

# LVM partitions
lvm_partitions:
  - name: swap
    size: 16g        # Or 8g depending on host
    type: swap
  - name: root
    size: "100%FREE"
    type: ext4
    path: /

# Hardware settings
cpu_vendor: intel    # or amd

# User settings
user_name: cesar

# Encrypted password hashes (ansible-vault encrypted)
root_password_hash: !vault | ...
user_password_hash: !vault | ...
```

## Security Considerations

### Vault Usage

Sensitive data is encrypted with Ansible Vault:
- LUKS passphrases
- Root and user password hashes
- SSH private keys (in `files/`)

**Managing vault secrets:**

```bash
# Encrypt a string for use in variables
ansible-vault encrypt_string 'your_value' --name 'variable_name'

# Edit encrypted file
ansible-vault edit host_vars/msi.yaml

# View encrypted file
ansible-vault view host_vars/msi.yaml
```

### Password Hash Generation

Generate SHA-512 password hashes for vault storage:

```bash
# Using openssl (recommended)
openssl passwd -6

# Or using mkpasswd
mkpasswd --method=SHA-512
```

**Important**: Store hashes without trailing newlines. Use the `trim` filter in playbooks:
```yaml
password: "{{ user_password_hash | trim }}"
```

### SSH Keys

The `files/` directory contains SSH private keys that are deployed to hosts:
- `id_rsa` and `id_ed25519`: Private keys (mode 0600)
- `id_rsa.pub` and `id_ed25519.pub`: Public keys

These are git-tracked but marked as sensitive. Ensure proper permissions.

## Code Style Guidelines

### YAML Conventions

- **File naming**: Use 3-digit prefix for ordering (e.g., `000-base.yaml`)
- **Document start**: Always use `---` at the beginning
- **Indentation**: 2 spaces (Ansible requirement)
- **Key ordering**: name, hosts, vars, tasks

### Playbook Structure

```yaml
---
- name: Descriptive play name
  hosts: all
  vars:
    variable_name: value
  become: yes
  become_method: sudo
  tags:
    - tagname
  tasks:
    - name: Task description
      module_name:
        option1: value
        option2: value
```

### Module Usage

- **Prefer native modules** over `command`/`shell` when possible
- **FQCN (Fully Qualified Collection Names)** for clarity:
  - `community.crypto.luks_device`
  - `community.general.timezone`
  - `ansible.builtin.copy`
- **Use `remote_src: yes`** for operations on remote files

### Idempotency

- Use modules that support idempotency (`pacman`, `service`, `copy`, etc.)
- Avoid `command`/`shell` unless necessary
- For non-idempotent commands, use `changed_when` and `failed_when`

Example:
```yaml
- name: Rank mirrorlist
  shell: "rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist"
  when: not mirrorlist_backup.stat.exists
  changed_when: true
```

### Tags

Use tags for selective execution:
- `installation`: Initial installation tasks
- `packages`: Package installation
- `configuration`: System configuration
- `ssh`: SSH key deployment

## Testing and Validation

### Syntax Checking

```bash
# Check playbook syntax
ansible-playbook --syntax-check archlinux/000-base.yaml

# List all tasks without executing
ansible-playbook -i inventory.ini --list-tasks archlinux/000-base.yaml
```

### Dry Run (Check Mode)

```bash
# Check mode - shows what would change without applying
ansible-playbook -i inventory.ini --vault-password-file .vault-password-file --check archlinux/010-configure.yaml -kK
```

### Linting

```bash
# Install ansible-lint
pip install ansible-lint

# Lint specific playbook
ansible-lint archlinux/000-base.yaml

# Lint all playbooks
ansible-lint
```

## Testing with Molecule

The project uses **Molecule** with **Podman** for automated testing of Ansible playbooks in isolated Arch Linux containers.

### Why Molecule + Podman?

- **Rootless containers**: No daemon required, more secure
- **systemd support**: Can test service management (SDDM, NetworkManager, etc.)
- **Idempotency testing**: Automatically verifies playbooks can run multiple times without changes
- **Fast feedback**: Test changes locally before deploying to real hardware

### Setup

```bash
# Ensure virtual environment is activated
source .venv/bin/activate

# Install testing dependencies (already included in requirements)
pip install molecule molecule-podman ansible-compat

# Ensure podman is installed on your system
sudo pacman -S podman
```

### Test Structure

```
molecule/
└── default/
    ├── molecule.yml      # Main configuration (platforms, provisioner, verifier)
    ├── Dockerfile        # Arch Linux image with systemd
    ├── create.yml        # Create test container
    ├── destroy.yml       # Destroy test container
    ├── prepare.yml       # Prepare container (users, sudo, packages)
    ├── converge.yml      # Execute playbooks under test
    └── verify.yml        # Verify expected state after execution
```

### Running Tests

```bash
# Run full test sequence (destroy → create → prepare → converge → idempotence → verify → destroy)
molecule test

# Run specific steps during development
molecule create      # Create and start the container
molecule prepare     # Run prepare playbook
molecule converge    # Run playbooks under test
molecule idempotence # Verify idempotency (run converge again, expect no changes)
molecule verify      # Run verification tests
molecule destroy     # Clean up container

# Login to container for debugging
molecule login

# Run with verbose output
molecule --debug test
```

### Test Configuration

The default scenario tests:
1. **000-base.yaml**: User creation, Xorg/Plasma installation, timezone, services
2. **010-configure.yaml**: Packages, KDE settings, fish shell, SSH keys

To test individual playbooks, edit `molecule/default/converge.yml` and comment/uncomment the appropriate `include_tasks` sections.

### Adding New Tests

To add verifications to `verify.yml`:

```yaml
- name: Verify specific condition
  ansible.builtin.assert:
    that:
      - some_condition_is_met
    fail_msg: "Descriptive error message"
    success_msg: "Success message"
```

### CI/CD Integration

For GitHub Actions or similar CI:

```yaml
- name: Run Molecule tests
  run: |
    source .venv/bin/activate
    molecule test
```

### Known Limitations

- **AUR packages**: Building AUR packages in containers requires `base-devel` and can be slow
- **GUI applications**: Services like SDDM can be enabled but won't start properly without a display
- **Hardware-specific tasks**: Tasks depending on specific hardware (Bluetooth, graphics) may need mocking

## Troubleshooting

### Common Issues

1. **SSH connection failures**: Ensure target host has SSH running and credentials are correct
2. **Vault password errors**: Verify `.vault-password-file` contains correct password
3. **Collection not found**: Run `ansible-galaxy collection install` for required collections
4. **Permission denied**: Use `-k` for SSH password or `-kK` for both SSH and sudo passwords

### Inventory Connection Details

From `inventory.ini`:
- `msi`: localhost (used during chroot/installation), user: cesar
- `tuxedo`: 192.168.1.134, user: cesar
- `desk`: 192.168.22.25, user: deck

All hosts use `StrictHostKeyChecking=no` for easier automation.

## Workflow Summary

1. **New laptop setup**:
   - Boot Arch ISO → Start SSH → Run `laptop/000-platform-base.yaml` → Run `laptop/010-configure-chroot-env.yaml` → Reboot
   - Run `archlinux/000-base.yaml` → Run `archlinux/010-configure.yaml` → Run `archlinux/020-developer.yaml`

2. **Steam Deck setup**:
   - Switch to desktop mode → Run `steam-deck/playbook.yaml` → Run `archlinux/` playbooks

3. **After SteamOS update**:
   - Run `steam-deck/after-SO-upgrade.yaml` to restore packages
