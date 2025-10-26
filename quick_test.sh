#!/bin/bash
# Quick test script to verify connectivity before deploying

set -e

echo "==========================================="
echo "Quick Connectivity Test for LLDP Deployment"
echo "==========================================="
echo ""

echo "Testing basic connectivity (no sudo)..."
echo "-------------------------------------------"
ansible all -i inventory.ini -m ping
echo ""

echo "✅ All hosts are reachable!"
echo ""
echo "Now you can run:"
echo "  ansible-playbook -i inventory.ini deploy_lldp.yml"
echo ""
