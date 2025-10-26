#!/bin/bash
# Helper script to create inventory.ini from example

if [ -f "inventory.ini" ]; then
    echo "inventory.ini already exists."
    echo "Current contents:"
    echo "=================="
    cat inventory.ini
    echo "=================="
    echo ""
    read -p "Do you want to recreate it from example? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing inventory.ini"
        exit 0
    fi
    mv inventory.ini inventory.ini.backup.$(date +%Y%m%d_%H%M%S)
    echo "Backed up existing inventory.ini"
fi

if [ ! -f "example_inventory.ini" ]; then
    echo "Error: example_inventory.ini not found!"
    echo "Please run 'git pull' first"
    exit 1
fi

cp example_inventory.ini inventory.ini
echo "Created inventory.ini from example_inventory.ini"
echo ""
echo "Next steps:"
echo "1. Edit inventory.ini with your server details:"
echo "   nano inventory.ini"
echo "2. Run the playbook:"
echo "   ansible-playbook -i inventory.ini deploy_lldp.yml"
echo ""
echo "Or use the test connection playbook first:"
echo "   ansible-playbook -i inventory.ini test_connection.yml"
