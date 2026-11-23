#!/bin/sh
# DikNom System Network — pemasang lintas distro.
# Mendukung apt, dnf, yum, pacman, zypper, apk, dan xbps.
set -eu

APP="DikNom System Network"
SELF_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
APP_SRC="$SELF_DIR/diknom-network"
HELPER_SRC="$SELF_DIR/diknom-hotspot-helper"
ICON_SRC="$SELF_DIR/assets/diknom-network.png"
PREFIX="${PREFIX:-$HOME/.local}"
DEPS=1
HOTSPOT=1
SYSTEM=0

say() { printf '%s\n' "$*"; }
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

usage() {
    cat <<EOF
$APP installer

Pemakaian:
  ./install.sh                 pasang untuk pengguna ini (~/.local)
  ./install.sh --system        pasang ke /usr/local (perlu sudo)
  ./install.sh --prefix=DIR    pasang ke DIR
  ./install.sh --no-deps       jangan pasang paket sistem
  ./install.sh --no-hotspot    pasang aplikasi saja, tanpa helper hotspot
  ./install.sh --hotspot       pasang dukungan hotspot (bawaan)
  ./install.sh --help

Dependensi aplikasi: python3 + tkinter, NetworkManager (opsional),
iw, iproute2, polkit, hostapd, dnsmasq, iptables.
EOF
}

for arg in "$@"; do
    case "$arg" in
        --system) SYSTEM=1; PREFIX="/usr/local" ;;
        --prefix=*) PREFIX="${arg#--prefix=}" ;;
        --no-deps) DEPS=0 ;;
        --no-hotspot) HOTSPOT=0 ;;
        --hotspot) HOTSPOT=1 ;;
        --help|-h) usage; exit 0 ;;
        *) die "Opsi tidak dikenal: $arg (pakai --help)" ;;
    esac
done

[ -f "$APP_SRC" ] || die "diknom-network tidak ditemukan di $SELF_DIR"
case "$PREFIX" in
    /*) ;;
    *) die "Prefix harus berupa path absolut: $PREFIX" ;;
esac

# --system dijalankan dengan sudo agar menulis ke /usr/local.
if [ "$SYSTEM" -eq 1 ] && [ "$(id -u)" -ne 0 ]; then
    command -v sudo >/dev/null 2>&1 || die "Butuh root; jalankan sebagai root."
    exec sudo -E sh "$0" "$@"
fi

# --------------------------------------------------------------- package manager
PKG=""
for cmd in apt-get dnf yum pacman zypper apk xbps-install; do
    if command -v "$cmd" >/dev/null 2>&1; then PKG="$cmd"; break; fi
done

pkg_install() {
    case "$PKG" in
        apt-get) DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" ;;
        dnf|yum) "$PKG" install -y "$@" ;;
        pacman) pacman -S --needed --noconfirm "$@" ;;
        zypper) zypper --non-interactive install "$@" ;;
        apk) apk add "$@" ;;
        xbps-install) xbps-install -y "$@" ;;
        *) return 1 ;;
    esac
}

if [ "$DEPS" -eq 1 ]; then
    if [ -z "$PKG" ]; then
        say "Package manager tidak dikenali; lewati instalasi dependensi."
        say "Pasang manual: python3-tk, NetworkManager, iw, iproute2, polkit,"
        say "hostapd, dnsmasq, iptables (jika memakai hotspot)."
    else
        say "== Memasang dependensi ($PKG) =="
        case "$PKG" in
            apt-get)
                APP_PKGS="python3 python3-tk network-manager iw iproute2 policykit-1 procps"
                HOT_PKGS="hostapd dnsmasq iptables"
                ;;
            dnf|yum)
                APP_PKGS="python3 python3-tkinter NetworkManager iw iproute polkit procps"
                HOT_PKGS="hostapd dnsmasq iptables"
                ;;
            pacman)
                APP_PKGS="python python3-tk tk networkmanager iw iproute2 polkit procps"
                HOT_PKGS="hostapd dnsmasq iptables"
                ;;
            zypper)
                APP_PKGS="python3 python3-tk NetworkManager iw iproute2 polkit procps"
                HOT_PKGS="hostapd dnsmasq iptables"
                ;;
            apk)
                APP_PKGS="python3 python3-tkinter networkmanager iw iproute2 polkit procps"
                HOT_PKGS="hostapd dnsmasq iptables"
                ;;
            xbps-install)
                APP_PKGS="python3 python3-tkinter NetworkManager iw iproute2 polkit procps"
                HOT_PKGS="hostapd dnsmasq iptables"
                ;;
        esac
        for pkg in $APP_PKGS; do
            pkg_install "$pkg" >/dev/null 2>&1 || \
                say "Paket aplikasi tidak tersedia: $pkg"
        done
        if [ "$HOTSPOT" -eq 1 ]; then
            for pkg in $HOT_PKGS; do
                pkg_install "$pkg" >/dev/null 2>&1 || \
                    say "Paket hotspot tidak tersedia: $pkg"
            done
        fi
    fi
fi

PYTHON=""
for candidate in /usr/bin/python3 /usr/local/bin/python3 \
                 "$(command -v python3 2>/dev/null || true)"; do
    [ -n "$candidate" ] || continue
    if "$candidate" -c 'import tkinter' >/dev/null 2>&1; then
        PYTHON="$candidate"
        break
    fi
done
[ -n "$PYTHON" ] || die "Python 3 + tkinter tidak ditemukan. Pasang paket tkinter untuk distro ini."

# --------------------------------------------------------------- aplikasi
DATA_DIR="$PREFIX/share/diknom-network"
BIN_DIR="$PREFIX/bin"
DESKTOP_DIR="$PREFIX/share/applications"
ICON_DIR="$PREFIX/share/icons/hicolor/256x256/apps"
mkdir -p "$DATA_DIR" "$BIN_DIR" "$DESKTOP_DIR" "$ICON_DIR"
install -m 0755 "$APP_SRC" "$DATA_DIR/diknom-network"
cat > "$BIN_DIR/diknom-network" <<EOF
#!/bin/sh
exec "$PYTHON" "$DATA_DIR/diknom-network" "\$@"
EOF
chmod 0755 "$BIN_DIR/diknom-network"
if [ -f "$ICON_SRC" ]; then
    install -m 0644 "$ICON_SRC" "$ICON_DIR/diknom-network.png"
    ICON_LINE="Icon=$ICON_DIR/diknom-network.png"
else
    ICON_LINE="Icon=network-wireless"
fi
cat > "$DESKTOP_DIR/diknom-network.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=DikNom System Network
Comment=Panel jaringan dan hotspot DikNom
Exec=$BIN_DIR/diknom-network
$ICON_LINE
Terminal=false
Categories=Network;System;
Keywords=network;wifi;hotspot;diknom;
EOF

# --------------------------------------------------------------- helper hotspot
HELPER_DST="/usr/local/lib/diknom-network/diknom-hotspot-helper"
if [ "$HOTSPOT" -eq 1 ]; then
    if [ -f "$HELPER_SRC" ] && [ "$(id -u)" -eq 0 ]; then
        mkdir -p "$(dirname "$HELPER_DST")"
        install -m 0755 "$HELPER_SRC" "$HELPER_DST"
        say "Helper hotspot: $HELPER_DST"
        if [ -d /etc/NetworkManager ]; then
            NM_CONF="/etc/NetworkManager/conf.d/99-diknom-hotspot.conf"
            mkdir -p "$(dirname "$NM_CONF")"
            cat > "$NM_CONF" <<'EOF'
# Dibuat oleh DikNom System Network: interface AP virtual jangan dikelola NM
[keyfile]
unmanaged-devices=interface-name:ap0
EOF
            command -v nmcli >/dev/null 2>&1 && nmcli general reload conf >/dev/null 2>&1 || true
        fi
    elif [ -f "$HELPER_SRC" ]; then
        say "Aplikasi terpasang. Untuk hotspot, jalankan:"
        say "  sudo ./install-hotspot.sh"
    fi
fi

# --------------------------------------------------------------- deteksi distro
if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    DISTRO="${PRETTY_NAME:-${NAME:-Linux}}"
else
    DISTRO="Linux"
fi
say ""
say "== Selesai =="
say "Distro terdeteksi : $DISTRO"
say "Aplikasi          : $BIN_DIR/diknom-network"
say "Data              : $DATA_DIR"
say "Hotspot           : $([ "$HOTSPOT" -eq 1 ] && echo 'helper disiapkan' || echo 'tidak dipasang')"
say ""
say "Jalankan dari menu aplikasi atau:"
say "  $BIN_DIR/diknom-network"
say ""
say "Jika desktop tidak menemukan menu, logout/login sekali atau jalankan:"
say "  update-desktop-database $DESKTOP_DIR 2>/dev/null || true"
