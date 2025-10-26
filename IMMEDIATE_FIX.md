# IMMEDIATE FIX for nasbox.local

## The Problem
Your inventory.ini has `ansible_become=yes` on the nasbox.local line. This makes Ansible try to use sudo for EVERY task, even simple ones like `ping`.

## The Fix

Edit your `inventory.ini` file and change this line:

**FROM:**
```ini
nasbox.local ansible_user=darren ansible_become=yes
```

**TO:**
```ini
nasbox.local ansible_user=darren
```

## Complete Fixed Inventory

Your entire inventory.ini should look like this:

```ini
[lldp_servers]
pbs.local ansible_user=root ansible_become=no
z620.local ansible_user=root ansible_become=no
nasbox.local ansible_user=darren

[lldp_servers:vars]
lldp_custom_config=true
```

## Why This Works

1. The `ansible.cfg` file already sets `become = True` globally in the `[privilege_escalation]` section
2. When you add `ansible_become=yes` on the host line, it overrides this for ALL tasks (even ping)
3. By removing `ansible_become=yes`, the host will use the global settings from ansible.cfg
4. The ansible.cfg has `become_ask_pass = False` which tells it not to prompt for passwords

## Test After Fixing

```bash
# Test basic connectivity (should work now)
ansible nasbox.local -i inventory.ini -m ping

# Run the full check
ansible-playbook -i inventory.ini check_sudo.yml

# Deploy LLDP
ansible-playbook -i inventory.ini deploy_lldp.yml
```

## If You Still Get Errors

If nasbox.local user `darren` doesn't have passwordless sudo configured, add it manually:

```bash
# SSH to nasbox.local
ssh darren@nasbox.local

# Add passwordless sudo
echo "darren ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/darren
sudo chmod 0440 /etc/sudoers.d/darren

# Test it
sudo -n whoami  # Should print "root" without asking for password
```
