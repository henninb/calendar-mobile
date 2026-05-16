#!/usr/bin/env bash
# Diagnoses and fixes the tun_wg0 interface losing its IP after a pfSense reboot.
# Root cause: wireguardd defers IP assignment to pfSense's interface_configure, which
# reads /tmp/config.cache. If the cache is stale the IP is never applied, breaking
# DNS replies and HTTPS traffic routed back through the WireGuard tunnel.
set -euo pipefail

WG_IF="tun_wg0"
WG_IP="10.0.0.1"
WG_MASK="24"
WG_NET="10.0.0.0"
PFSENSE_HOST="${PFSENSE_HOST:-pfsense}"

pf() { ssh "$PFSENSE_HOST" "$@"; }

check() {
    local has_ip has_route
    has_ip=$(pf "ifconfig $WG_IF 2>/dev/null | grep -c 'inet $WG_IP '" || true)
    has_route=$(pf "netstat -rn -f inet 2>/dev/null | grep -c '$WG_NET.*$WG_IF'" || true)
    echo "$has_ip $has_route"
}

read -r has_ip has_route <<< "$(check)"

echo "==> WireGuard interface: $WG_IF"
echo "    inet $WG_IP/$WG_MASK assigned : $([ "$has_ip"    -gt 0 ] && echo YES || echo NO)"
echo "    route $WG_NET via $WG_IF      : $([ "$has_route" -gt 0 ] && echo YES || echo NO)"

if [ "$has_ip" -gt 0 ] && [ "$has_route" -gt 0 ]; then
    echo "==> Everything looks correct. No fix needed."
    exit 0
fi

echo "==> Interface or route is missing — fixing..."

# Step 1: clear the stale config cache so wireguardd reads the updated config.xml
pf "rm -f /tmp/config.cache"
echo "    config cache cleared"

# Step 2: restart wireguardd so it re-reads config.xml and calls interface_configure
pf "service wireguardd restart"
sleep 4
echo "    wireguardd restarted"

# Step 3: verify — if wireguardd applied the IP we are done
read -r has_ip has_route <<< "$(check)"
if [ "$has_ip" -gt 0 ] && [ "$has_route" -gt 0 ]; then
    echo "==> Fixed by wireguardd restart."
else
    # Fallback: apply the IP directly (survives until next reboot)
    echo "    wireguardd did not apply IP — applying manually"
    pf "ifconfig $WG_IF inet $WG_IP/$WG_MASK"
    sleep 1
    read -r has_ip has_route <<< "$(check)"
fi

# Final verification
echo ""
echo "==> Final status"
pf "ifconfig $WG_IF"
pf "netstat -rn -f inet | grep $WG_NET || true"
echo ""
pf "wg show $WG_IF"

if [ "$has_ip" -gt 0 ] && [ "$has_route" -gt 0 ]; then
    echo ""
    echo "==> Fixed. DNS replies and HTTPS traffic will now route correctly to the phone."
else
    echo ""
    echo "ERROR: could not restore $WG_IF — check pfSense WireGuard config."
    exit 1
fi
