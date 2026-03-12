# AGENTS.md - Ansible Playbook for Arch Linux Installation

## Overview

This repository contains Ansible playbooks for installing and configuring Arch Linux on various devices:
- **laptop/**: Playbooks for initial Arch Linux installation via chroot
- **archlinux/**: Post-installation configuration (user setup, desktop environment, AUR packages)
- **steam-deck/**: Steam Deck desktop mode configuration

## Project Structure

```
├── inventory.ini           # Ansible inventory with host definitions
├── archlinux/              # Main configuration playbooks (numbered for order)
│   ├── 000-base.yaml       # Base system configuration
│   ├── 010-configure.yaml # System configuration
│   ├── 020-msi.yaml        # MSI-specific settings
│   ├── 030-nas.yaml        # NAS configuration
│   ├── 040-aur.yaml        # AUR package installation
│   ├── 050-developer.yaml  # Developer tools
│   ├── 100-configure-arch-linux.yaml  # Final configuration
│   └── 110-nuria.yaml      # User-specific settings
├── laptop/                 # Installation playbooks
├── steam-deck/             # Steam Deck configuration
├── files/                  # Config files to deploy
├── host_vars/              # Host-specific variables
└── .vault-password-file    # Ansible vault password (not in git)
```

## Build/Lint/Test Commands

### Setup Dependencies

```bash
# Create virtual environment
python3 -m venv .venv
source .venv/bin/activate
pip install ansible

# Install required collections
ansible-galaxy collection install community.crypto kewlfft.aur
```

### Running Playbooks

```bash
# Dry run (check mode)
ansible-playbook -i inventory.ini --vault-password-file .vault-password-file --check archlinux/000-base.yaml

# Run specific playbook with vault password
ansible-playbook -i inventory.ini --vault-password-file .vault-password-file archlinux/000-base.yaml -kK

# Run with tags
ansible-playbook -i inventory.ini --vault-password-file .vault-password-file archlinux/040-aur.yaml -kK --tags installation
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

### Syntax Checking

```bash
# Check playbook syntax
ansible-playbook --syntax-check archlinux/000-base.yaml

# List all tasks without executing
ansible-playbook -i inventory.ini --list-tasks archlinux/000-base.yaml
```

## Code Style Guidelines

### YAML Structure

- **File naming**: Use 3-digit prefix + descriptive name (e.g., `010-configure.yaml`)
- **Document start**: Always use `---` at the beginning of each YAML file
- **Indentation**: 2 spaces (Ansible requirement)
- **Key ordering**: name, hosts, vars, tasks, handlers, roles

### Playbook Conventions

```yaml
---
- name: Descriptive play name       # Required: describes what this play does
  hosts: all                        # Target hosts
  vars:                             # Play-specific variables
    variable_name: value
  become: yes                       # Use privilege escalation when needed
  become_method: sudo              # Method for privilege escalation
  tags:
    - tagname                      # Tag plays/tasks for selective execution
  tasks:
    - name: Task description       # Required: describes the task
      module_name:
        option1: value
        option2: value
```

### Module Usage

- **FQB module names**: Use fully qualified names when ambiguous:
  - `ansible.builtin.copy` (not just `copy`)
  - `ansible.builtin.git` (not just `git`)
- **Prefer native modules**: Use `package`, `service`, `user` over `command` when possible
- **Remote modules**: Use `remote_src: yes` for copy/template operations from remote

### Variable Naming

- **Variable names**: snake_case (e.g., `user_name`, `package_list`)
- **Host variables**: Define in `host_vars/` directory per host
- **Vault secrets**: Store sensitive data in vault-encrypted files

### Idempotency

- **Always**: Use Ansible modules that support idempotency (package, service, copy, etc.)
- **Avoid**: `command` and `shell` modules unless absolutely necessary
- **when conditions**: Use `changed_when` and `check_mode` for command idempotency
- **Known issues**: Document non-idempotent tasks with `# TODO idempotence` comment

### Error Handling

- **Ignore errors**: Use `ignore_errors: yes` sparingly and with comment explaining why
- **Failed when**: Use `failed_when` for complex error conditions
- **Until/retry**: Use `until`, `retries`, `delay` for retry logic

### Tags

Use tags for selective execution:
- `installation`: Initial installation tasks
- `packages`: Package installation
- `configuration`: System configuration
- `always`: Tasks that should always run

### Privilege Escalation

```yaml
- name: Task requiring root
  become: yes
  become_method: sudo
  # task content
```

### Best Practices

1. **Always include task names**: Required for readability and logging
2. **Use loops sparingly**: Prefer module-native list parameters
3. **Group related tasks**: Use blocks for related operations
4. **Keep playbooks focused**: One playbook per concern
5. **Use role defaults**: Define defaults in roles for optional behavior

### Vault

```bash
# Encrypt a file
ansible-vault encrypt secrets.yaml

# Edit encrypted file
ansible-vault edit secrets.yaml

# View encrypted file
ansible-vault view secrets.yaml
```

### Gitignore

The following are ignored:
- `.vault-password-file` - Vault password
- `.venv/` - Python virtual environment
