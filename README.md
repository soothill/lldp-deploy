# LLDP Deployment Ansible Playbooks

This repository contains Ansible playbooks to deploy and configure LLDP (Link Layer Discovery Protocol) on Linux servers.

## Files Included

- **deploy_lldp.yml**: Basic playbook for LLDP installation and service management
- **deploy_lldp_advanced.yml**: Enhanced playbook with configuration options and neighbor discovery
- **inventory.ini**: Example inventory file
- **lldpd.conf.j2**: Jinja2 template for LLDP configuration (used with advanced playbook)

## Prerequisites

- Ansible 2.9 or higher installed on your control node
- SSH access to target servers
- Sudo privileges on target servers
- Target servers running Debian/Ubuntu or RedHat/CentOS

## Quick Start - Basic Deployment

### 1. Edit the inventory file

```bash
nano inventory.ini
```

Add your server hostnames and IP addresses.

### 2. Deploy LLDP

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
- Enable the service to start on boot
- Start the service immediately
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

### Service not starting
- Check logs: `journalctl -u lldpd -n 50`
- Verify package installation: `dpkg -l | grep lldpd` (Debian/Ubuntu) or `rpm -qa | grep lldpd` (RedHat/CentOS)

### No neighbors detected
- Ensure network switch supports LLDP
- Check if LLDP is enabled on switch ports
- Verify network connectivity
- Wait 30-60 seconds for neighbor discovery

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
