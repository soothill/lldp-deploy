# Fixing "Missing sudo password" Error

## The Problem
The error `fatal: [nasbox.local]: FAILED! => {"msg": "Missing sudo password"}` means that:
1. Ansible is trying to use `sudo` on nasbox.local
2. The user `darren` either doesn't have passwordless sudo, OR
3. The inventory configuration is incorrect

## Step-by-Step Fix

### Step 1: Check Current Sudo Status
```bash
ansible-playbook -i inventory.ini check_sudo.yml
```

This will tell you exactly which hosts have passwordless sudo working and which don't.

### Step 2A: If nasbox.local FAILS the sudo test

The user `darren` needs passwordless sudo configured. Run this playbook:

```bash
ansible-playbook -i inventory.ini setup_passwordless_sudo.yml --ask-become-pass --limit nasbox.local
```

You'll be prompted for the sudo password ONCE, then the playbook will configure passwordless sudo for future use.

### Step 2B: If nasbox.local PASSES the sudo test

The issue is with your inventory configuration. Edit your `inventory.ini`:

**Current (probably wrong):**
```ini
nasbox.local ansible_user=darren ansible_become=yes
```

**Should be:**
```ini
nasbox.local ansible_user=darren
```

Or if you want to be explicit:
```ini
nasbox.local ansible_user=darren ansible_become=no
```

### Step 3: Verify the Fix
```bash
ansible-playbook -i inventory.ini check_sudo.yml
```

All hosts should now show "Passwordless sudo WORKS ✅" or be running as root.

### Step 4: Deploy LLDP
```bash
ansible-playbook -i inventory.ini deploy_lldp.yml
```

## Quick Reference: Your Inventory Should Look Like This

```ini
[lldp_servers]
# Hosts running as root
pbs.local ansible_user=root ansible_become=no
z620.local ansible_user=root ansible_become=no

# Host with regular user (will use passwordless sudo from ansible.cfg)
nasbox.local ansible_user=darren

[lldp_servers:vars]
lldp_custom_config=true
```

## Manual Fix (if playbooks don't work)

SSH into nasbox.local and run:
```bash
echo "darren ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/darren
sudo chmod 0440 /etc/sudoers.d/darren
sudo visudo -c  # Verify syntax is correct
```

Then test:
```bash
sudo -n whoami  # Should print "root" without asking for password
```

## Still Not Working?

If you're still getting the error, the issue might be:

1. **SSH Key Authentication**: Make sure you can SSH to nasbox.local without a password
2. **Ansible User**: Verify `darren` is the correct username
3. **Network/Firewall**: Ensure nasbox.local is reachable

Test basic connectivity:
```bash
ansible nasbox.local -i inventory.ini -m ping
```
