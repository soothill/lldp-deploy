# Fixing "sudo: a password is required" (requiretty issue)

## The Problem

Your diagnostic shows:
```
nasbox.local: Passwordless sudo FAILS ❌ - Output: sudo: a password is required
```

But when you SSH manually and run `sudo`, it works without a password.

**This is the classic `requiretty` issue**: The sudoers configuration requires an interactive terminal (TTY), which Ansible doesn't provide by default.

## Quick Fix Option 1: Update ansible.cfg (Already Done)

The ansible.cfg has been updated with:
```ini
[ssh_connection]
pipelining = True
```

This helps bypass the requiretty check in many cases.

**Test if this fixes it:**
```bash
git pull
ansible-playbook -i inventory.ini check_sudo.yml
```

If nasbox.local still fails, proceed to Option 2.

## Fix Option 2: Disable requiretty for your user

Run this playbook to permanently fix the requiretty issue:

```bash
ansible-playbook -i inventory.ini fix_requiretty.yml --ask-become-pass --limit nasbox.local
```

This will:
1. Check if requiretty is enabled
2. Create a sudoers.d entry that disables requiretty for user `darren`
3. Ensure NOPASSWD is configured correctly

## Manual Fix (if playbook doesn't work)

SSH to nasbox.local and run:

```bash
# Create sudoers entry
sudo tee /etc/sudoers.d/darren <<EOF
# Managed by Ansible
# Allow darren to run commands without password and without TTY
Defaults:darren !requiretty
darren ALL=(ALL) NOPASSWD: ALL
EOF

# Set correct permissions
sudo chmod 0440 /etc/sudoers.d/darren

# Verify syntax
sudo visudo -c
```

## Verify the Fix

After applying the fix, test again:

```bash
# This should now show "Passwordless sudo WORKS ✅"
ansible-playbook -i inventory.ini check_sudo.yml

# If that works, deploy LLDP
ansible-playbook -i inventory.ini deploy_lldp.yml
```

## Why This Happens

Some Linux distributions (especially older ones) have this in `/etc/sudoers`:
```
Defaults requiretty
```

This security feature requires an interactive terminal for sudo commands. While good for security, it breaks automation tools like Ansible.

The fix adds `Defaults:darren !requiretty` which disables this requirement specifically for your user.
