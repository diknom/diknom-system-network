#!/bin/sh
# Pemasang dukungan Hotspot DikNom System Network.
# Memasang hostapd, dnsmasq, iptables, dan helper root.
set -eu

APP="DikNom System Network"
HELPER_SRC="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/diknom-hotspot-helper"
HELPER_DST="/usr/local/lib/diknom-network/diknom-hotspot-helper"
NM_CONF="/etc/NetworkManager/conf.d/99-diknom-hotspot.conf"

say()  { printf '%s\n' "$*"; }
die()  { printf 'Error: %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "Jalankan dengan sudo: sudo ./install-hotspot.sh"
[ -f "$HELPER_SRC" ] || die "diknom-hotspot-helper tidak ditemukan di folder ini"

say "== $APP — dukungan Hotspot =="
say "Memasang dependensi..."

if command -v apt-get >/dev/null 2>&1; then
    DEBIAN_FRONTEND=noninteractive apt-get install -y hostapd dnsmasq iptables
elif command -v dnf >/dev/null 2>&1; then
    dnf install -y hostapd dnsmasq iptables
elif command -v yum >/dev/null 2>&1; then
    yum install -y hostapd dnsmasq iptables
elif command -v pacman >/dev/null 2>&1; then
    pacman -S --needed --noconfirm hostapd dnsmasq iptables
elif command -v zypper >/dev/null 2>&1; then
    zypper --non-interactive install hostapd dnsmasq iptables
elif command -v apk >/dev/null 2>&1; then
    apk add hostapd dnsmasq iptables
elif command -v xbps-install >/dev/null 2>&1; then
    xbps-install -y hostapd dnsmasq iptables
else
    die "Package manager tidak dikenali. Pasang manual: hostapd, dnsmasq, iptables."
fi

for c in hostapd dnsmasq iptables iw; do
    command -v "$c" >/dev/null 2>&1 || die "$c tidak ditemukan setelah pemasangan."
done

mkdir -p "$(dirname "$HELPER_DST")"
install -m 0755 "$HELPER_SRC" "$HELPER_DST"
say "Helper: $HELPER_DST"

if [ -d /etc/NetworkManager ]; then
    mkdir -p "$(dirname "$NM_CONF")"
    cat > "$NM_CONF" <<'EOF'
# Dibuat oleh DikNom System Network: interface AP virtual jangan dikelola NM
[keyfile]
unmanaged-devices=interface-name:ap0
EOF
    if command -v nmcli >/dev/null 2>&1; then
        nmcli general reload conf >/dev/null 2>&1 || true
    fi
    say "NetworkManager: ap0 ditandai unmanaged."
fi

say ""
say "Selesai. Buka DikNom System Network → Hotspot, atur SSID/password, lalu klik Mulai Hotspot."
say "Saat pertama menyalakan, polkit akan meminta izin administrator."
