# LLDP Deployment Ansible Playbooks

This repository contains Ansible playbooks to deploy and configure LLDP (Link Layer Discovery Protocol) on Linux servers.

## Files Included

- **deploy_lldp.yml**: Basic playbook for LLDP installation and service management
- **deploy_lldp_advanced.yml**: Enhanced playbook with configuration options and neighbor discovery
- **example_inventory.ini**: Example inventory file (copy to inventory.ini)
- **ansible.cfg**: Ansible configuration with passwordless sudo support
- **lldpd.conf.j2**: Jinja2 template for LLDP configuration (used with advanced playbook)

## Prerequisites

- Ansible 2.9 or higher installed on your control node
- SSH access to target servers
- Sudo privileges on target servers
- Target servers running Debian/Ubuntu or RedHat/CentOS

## Quick Start - Automated Setup (Recommended)

The easiest way to get started is using the interactive quickstart script:

```bash
./quickstart.sh
```

This will:
- Check prerequisites (Ansible, Make)
- Help you create inventory.ini
- Run pre-flight checks (connectivity, sudo configuration)
- **Automatically detect and fix common issues like requiretty**
- Guide you through the installation process

## Quick Start - Manual Deployment

### 1. Create your inventory file

Copy the example inventory and customize it for your environment:

```bash
cp example_inventory.ini inventory.ini
nano inventory.ini
```

Add your server hostnames, IP addresses, and customize usernames as needed.

### 2. Run Pre-flight Checks (Recommended)

Before deploying, check for common issues:

```bash
# Test basic connectivity
ansible all -i inventory.ini -m ping

# Check sudo configuration (detects requiretty and other sudo issues)
ansible-playbook -i inventory.ini check_sudo.yml
```

If you see "Passwordless sudo FAILS" or "sudo: a password is required", see the [Troubleshooting](#troubleshooting) section.

### 3. Deploy LLDP

#### Using Make (Recommended)

```bash
make install
```

#### Using Ansible directly

```bash
ansible-playbook -i inventory.ini deploy_lldp.yml
```

This will:
- Install lldpd package
- Configure non-root access (creates lldpd group)
- Enable the service to start on boot
- Start the service immediately
- Configure socket permissions for non-root access
- Verify the service is running

## Using the Makefile

The Makefile provides convenient shortcuts for common operations. See all available commands:

```bash
make help
```

### Common Make Targets

```bash
# Deploy LLDP (basic)
make install

# Deploy LLDP (advanced with configuration)
make install-advanced

# Dry run to see what would change
make check

# Deploy to specific host(s)
make limit LIMIT=server1.example.com

# Test connectivity to all hosts
make test-connection

# Verify LLDP service status
make verify

# Show LLDP neighbors
make neighbors

# View LLDP logs
make logs

# Restart LLDP service
make restart
```

## Advanced Deployment

The advanced playbook includes additional features:

### Features

- Custom LLDP configuration via template
- Service status verification
- LLDP neighbor discovery
- Configurable system description and platform
- Management interface patterns

### Usage

```bash
ansible-playbook -i inventory.ini deploy_lldp_advanced.yml
```

### Custom Configuration

To use custom LLDP configuration, set `lldp_custom_config=true` in your inventory or pass it as an extra variable:

**Using Make:**
```bash
make install-custom
```

**Using Ansible:**
```bash
ansible-playbook -i inventory.ini deploy_lldp_advanced.yml -e "lldp_custom_config=true"
```

## Make Targets Reference

| Target | Description |
|--------|-------------|
| `make help` | Show all available targets |
| `make install` | Deploy basic LLDP |
| `make install-advanced` | Deploy with advanced configuration |
| `make install-custom` | Deploy with custom config enabled |
| `make check` | Dry run (no changes) |
| `make check-advanced` | Dry run for advanced playbook |
| `make test-connection` | Test connectivity to hosts |
| `make verify` | Check LLDP service status |
| `make neighbors` | Show LLDP neighbors |
| `make info` | Show chassis information |
| `make logs` | View LLDP logs |
| `make restart` | Restart LLDP service |
| `make limit LIMIT=host` | Deploy to specific host |
| `make lint` | Lint playbooks |
| `make syntax` | Check syntax |
| `make list-hosts` | List all inventory hosts |
| `make uninstall` | Remove LLDP (with confirmation) |

## Configuration Variables

You can override these variables in your inventory file or pass them via `-e`:

```yaml
lldp_package: lldpd                    # Package name
lldp_service: lldpd                    # Service name
lldp_system_description: "hostname"    # System description
lldp_system_platform: "Linux"          # Platform description
lldp_enable_snmp: no                   # Enable SNMP support
lldp_mgmt_pattern: "!dummy*,!veth*"   # Interface pattern
```

## Examples

### Run on specific hosts

```bash
ansible-playbook -i inventory.ini deploy_lldp.yml --limit server1.example.com
```

### Check mode (dry run)

```bash
ansible-playbook -i inventory.ini deploy_lldp.yml --check
```

### Verbose output

```bash
ansible-playbook -i inventory.ini deploy_lldp.yml -v
```

## Verifying LLDP Installation

After deployment, you can verify LLDP is working:

### Check service status
```bash
ansible all -i inventory.ini -a "systemctl status lldpd"
```

### View LLDP neighbors
```bash
ansible all -i inventory.ini -a "lldpcli show neighbors"
```

### Show local chassis information
```bash
ansible all -i inventory.ini -a "lldpcli show chassis"
```

## Troubleshooting

### "Missing sudo password" Error

This is the most common issue. The quickstart script will detect and help fix this automatically, but you can also run:

```bash
ansible-playbook -i inventory.ini check_sudo.yml
```

**Common causes:**

1. **requiretty enabled** (Most common - shows "sudo: a password is required")
   - Fix: `ansible-playbook -i inventory.ini fix_requiretty.yml --ask-become-pass`
   - Manual fix: See [FIX_REQUIRETTY.md](FIX_REQUIRETTY.md)

2. **Passwordless sudo not configured**
   - Fix: `ansible-playbook -i inventory.ini setup_passwordless_sudo.yml --ask-become-pass`
   - Manual fix: See [FIX_SUDO_ISSUE.md](FIX_SUDO_ISSUE.md)

3. **Incorrect inventory configuration**
   - Don't add `ansible_become=yes` to individual host lines
   - Let playbooks control when sudo is needed
   - See [inventory_fixed.ini](inventory_fixed.ini) for examples

### Service not starting

If lldpd service fails to start, check:

```bash
# View detailed logs
make logs

# Or manually
journalctl -u lldpd -n 50
```

**Common issues:**
- **lldpd 1.0.x doesn't support `-g` flag**: Fixed in current playbooks (uses systemd override instead)
- **Socket permission issues**: The playbooks now handle this automatically
- Verify package installation: `dpkg -l | grep lldpd` (Debian/Ubuntu) or `rpm -qa | grep lldpd` (RedHat/CentOS)

### Non-root users can't run lldpctl

After installation, users need to:
1. Log out and log back in, OR
2. Run `newgrp lldpd`

This activates the group membership that allows non-root access to lldpctl.

### No neighbors detected
- Ensure network switch supports LLDP
- Check if LLDP is enabled on switch ports
- Verify network connectivity
- Wait 30-60 seconds for neighbor discovery

### Pre-flight Checks

Run pre-flight checks before deploying:

```bash
./quickstart.sh  # Interactive with automatic detection and fixes
```

Or manually:
```bash
ansible all -i inventory.ini -m ping                    # Test connectivity
ansible-playbook -i inventory.ini check_sudo.yml        # Check sudo configuration
```

## Supported Distributions

- Ubuntu 18.04, 20.04, 22.04, 24.04
- Debian 10, 11, 12
- CentOS 7, 8, 9
- RHEL 7, 8, 9
- Rocky Linux 8, 9

## Additional Resources

- LLDP Documentation: https://lldpd.github.io/
- Ansible Documentation: https://docs.ansible.com/

## License

MIT
