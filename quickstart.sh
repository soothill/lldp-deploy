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

read -p "Would you like to test connectivity now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    make test-connection
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    read -p "Would you like to proceed with LLDP installation? (y/n) " -n 1 -r
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
    echo "You can run 'make test-connection' to test connectivity later."
fi

echo ""
echo "================================================"
echo "For more information, see README.md"
echo "================================================"
