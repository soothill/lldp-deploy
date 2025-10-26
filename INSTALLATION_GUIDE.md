# Complete Installation Guide

## Overview

This guide covers everything you need to successfully deploy LLDP on your Linux servers, including how to handle common issues like the requiretty problem.

## Prerequisites

- Ansible 2.9 or higher on your control machine
- SSH access to target servers
- Sudo access on target servers (will be configured for passwordless operation)

## Installation Methods

### Method 1: Automated (Recommended for First-Time Users)

The quickstart script handles everything automatically, including detecting and fixing common issues:

```bash
./quickstart.sh
```

**What it does:**
1. ✅ Checks that Ansible and Make are installed
2. ✅ Helps you create inventory.ini if needed
3. ✅ Tests connectivity to all hosts
4. ✅ **Checks for sudo issues (including requiretty)**
5. ✅ **Automatically offers to fix detected issues**
6. ✅ Deploys LLDP if all checks pass
7. ✅ Verifies the installation

If it detects the requiretty issue, it will:
- Explain what requiretty is in plain language
- Show you the exact command to fix it
- Offer to run the fix automatically
- Verify the fix worked

### Method 2: Manual (For Experienced Users)

#### Step 1: Create Inventory

```bash
cp example_inventory.ini inventory.ini
nano inventory.ini
```

Example inventory:
```ini
[lldp_servers]
server1.local ansible_user=username
server2.local ansible_user=root ansible_become=no

[lldp_servers:vars]
lldp_custom_config=true
```

**Important:** Don't add `ansible_become=yes` to individual hosts!

#### Step 2: Pre-flight Checks

```bash
# Test connectivity
ansible all -i inventory.ini -m ping

# Check sudo configuration
ansible-playbook -i inventory.ini check_sudo.yml
```

#### Step 3: Fix Issues (if needed)

If you see "sudo: a password is required":

```bash
ansible-playbook -i inventory.ini fix_requiretty.yml --ask-become-pass
```

#### Step 4: Deploy

```bash
ansible-playbook -i inventory.ini deploy_lldp.yml
```

## Common Issues and Solutions

### Issue 1: "sudo: a password is required"

**Cause:** The requiretty setting is enabled in sudoers, which requires an interactive terminal that Ansible doesn't provide.

**Symptoms:**
- Manual SSH and sudo works fine
- Ansible fails with "sudo: a password is required"

**Fix:**
```bash
ansible-playbook -i inventory.ini fix_requiretty.yml --ask-become-pass
```

**Manual fix** (on each affected host):
```bash
sudo tee /etc/sudoers.d/yourusername <<EOF
Defaults:yourusername !requiretty
yourusername ALL=(ALL) NOPASSWD: ALL
EOF
sudo chmod 0440 /etc/sudoers.d/yourusername
```

See [FIX_REQUIRETTY.md](FIX_REQUIRETTY.md) for details.

### Issue 2: "Missing sudo password"

**Cause:** Multiple possible causes - wrong inventory config, no passwordless sudo, or become settings.

**Fix:**
```bash
# Run diagnostic
ansible-playbook -i inventory.ini check_sudo.yml

# Follow the specific fix it recommends
```

See [FIX_SUDO_ISSUE.md](FIX_SUDO_ISSUE.md) for details.

### Issue 3: lldpd service won't start

**For lldpd 1.0.x:** The current playbooks automatically handle version compatibility. The older `-g` flag issue is fixed using systemd overrides.

**Check logs:**
```bash
make logs
# or
journalctl -u lldpd -n 50
```

### Issue 4: Non-root users can't run lldpctl

After installation, users need to activate their group membership:

```bash
# Option 1: Log out and back in
logout

# Option 2: Activate group in current session
newgrp lldpd
```

Then test:
```bash
lldpctl show chassis
```

## Verification

After installation:

```bash
# Check service status
make verify

# Show LLDP neighbors
make neighbors

# Show chassis information
make info
```

## File Reference

- **quickstart.sh** - Interactive installation script (recommended)
- **check_sudo.yml** - Diagnostic playbook for sudo issues
- **fix_requiretty.yml** - Fixes the requiretty issue
- **setup_passwordless_sudo.yml** - Configures passwordless sudo
- **deploy_lldp.yml** - Main deployment playbook
- **deploy_lldp_advanced.yml** - Advanced deployment with custom config
- **FIX_REQUIRETTY.md** - Detailed requiretty troubleshooting
- **FIX_SUDO_ISSUE.md** - Detailed sudo troubleshooting
- **inventory_fixed.ini** - Example inventory with correct configuration

## Support

For issues not covered here:
1. Check the [Troubleshooting section in README.md](README.md#troubleshooting)
2. Review the specific fix guides (FIX_*.md files)
3. Run `./quickstart.sh` for automated diagnosis

## Architecture Notes

### Non-Root Access Implementation

The playbooks configure non-root access to lldpctl by:
1. Creating an `lldpd` system group
2. Adding users to this group
3. Using systemd service overrides to set socket permissions (compatible with lldpd 1.0.x)
4. Setting socket group to `lldpd` and mode to `0660`

This works even on older lldpd versions that don't support the `-g` flag.

### Why requiretty is an Issue

The `Defaults requiretty` setting in sudoers requires an interactive TTY for security:
- Prevents automated scripts from using sudo
- Good for security in some scenarios
- Breaks automation tools like Ansible

Our fix adds `Defaults:username !requiretty` which disables this requirement for specific users while keeping NOPASSWD restrictions.
