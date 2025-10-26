#!/bin/bash
# Quick Start Script for LLDP Deployment

set -e

echo "================================================"
echo "LLDP Deployment - Quick Start"
echo "================================================"
echo ""

# Check if make is installed
if ! command -v make &> /dev/null; then
    echo "❌ 'make' is not installed. Please install it:"
    echo "   Ubuntu/Debian: sudo apt install make"
    echo "   RedHat/CentOS: sudo yum install make"
    exit 1
fi

# Check if ansible is installed
if ! command -v ansible &> /dev/null; then
    echo "⚠️  Ansible is not installed."
    read -p "Would you like to install it now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        make requirements
    else
        echo "Please install Ansible manually and try again."
        exit 1
    fi
fi

echo "✅ Prerequisites satisfied"
echo ""

# Check if inventory file exists
if [ ! -f "inventory.ini" ]; then
    echo "⚠️  inventory.ini not found."
    if [ -f "example_inventory.ini" ]; then
        echo "Creating inventory.ini from example..."
        cp example_inventory.ini inventory.ini
        echo "✅ Created inventory.ini - Please edit it with your servers"
        echo "   Run: nano inventory.ini"
    else
        echo "Creating basic inventory.ini..."
        cat > inventory.ini <<EOF
[lldp_servers]
# Add your servers here
# server1.example.com ansible_host=192.168.1.10 ansible_user=youruser

[lldp_servers:vars]
lldp_custom_config=true
EOF
        echo "✅ Created inventory.ini - Please edit it with your servers"
    fi
    echo ""
    exit 0
fi

echo "📋 Available Commands:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Testing & Verification:"
echo "  make test-connection    # Test if you can reach all hosts"
echo "  make check              # See what would change (dry run)"
echo "  make list-hosts         # List all hosts in inventory"
echo ""
echo "Deployment:"
echo "  make install            # Deploy LLDP (basic)"
echo "  make install-advanced   # Deploy LLDP (advanced)"
echo ""
echo "Verification:"
echo "  make verify             # Check service status"
echo "  make neighbors          # Show LLDP neighbors"
echo "  make logs               # View service logs"
echo ""
echo "Get Help:"
echo "  make help               # Show all available commands"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

read -p "Would you like to run pre-flight checks now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Running pre-flight checks..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Test basic connectivity
    echo "1. Testing basic connectivity..."
    if ansible all -i inventory.ini -m ping > /dev/null 2>&1; then
        echo "   ✅ All hosts reachable"
    else
        echo "   ❌ Some hosts unreachable"
        echo "   Run: make test-connection"
        exit 1
    fi
    echo ""

    # Check sudo configuration
    echo "2. Checking sudo configuration..."
    echo "   (This checks for passwordless sudo and requiretty issues)"
    echo ""

    if ansible-playbook -i inventory.ini check_sudo.yml 2>&1 | tee /tmp/sudo_check.log | grep -q "Passwordless sudo FAILS"; then
        echo ""
        echo "⚠️  WARNING: Sudo configuration issues detected!"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        # Check for requiretty specifically
        if grep -q "sudo: a password is required" /tmp/sudo_check.log; then
            echo ""
            echo "❌ ISSUE: requiretty is enabled (common issue)"
            echo ""
            echo "This means sudo requires an interactive terminal, which"
            echo "Ansible doesn't provide. This is fixable!"
            echo ""
            echo "FIX OPTIONS:"
            echo ""
            echo "Option 1 (Automatic - Recommended):"
            echo "  ansible-playbook -i inventory.ini fix_requiretty.yml --ask-become-pass"
            echo ""
            echo "Option 2 (Manual - on each affected host):"
            echo "  See: FIX_REQUIRETTY.md for detailed instructions"
            echo ""
            read -p "Would you like to run the automatic fix now? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo ""
                echo "Running fix_requiretty.yml..."
                ansible-playbook -i inventory.ini fix_requiretty.yml --ask-become-pass
                echo ""
                echo "Verifying fix..."
                ansible-playbook -i inventory.ini check_sudo.yml
            fi
        else
            echo ""
            echo "For troubleshooting, see:"
            echo "  - FIX_SUDO_ISSUE.md"
            echo "  - FIX_REQUIRETTY.md"
        fi
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    else
        echo "   ✅ All hosts have proper sudo configuration"
        echo ""
    fi

    rm -f /tmp/sudo_check.log

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    read -p "Pre-flight checks complete. Proceed with installation? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "Starting LLDP deployment..."
        echo ""
        make install
        echo ""
        echo "✅ LLDP deployment complete!"
        echo ""
        echo "Verifying installation..."
        make verify
    else
        echo ""
        echo "You can run 'make install' when ready to deploy."
    fi
else
    echo ""
    echo "You can run these checks manually:"
    echo "  make test-connection              # Test connectivity"
    echo "  ansible-playbook -i inventory.ini check_sudo.yml  # Check sudo"
fi

echo ""
echo "================================================"
echo "For more information, see README.md"
echo "================================================"
