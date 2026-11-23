#!/bin/sh
# DikNom System Network — uninstaller.
set -eu

PREFIX="${PREFIX:-$HOME/.local}"
PURGE=0
for arg in "$@"; do
    case "$arg" in
        --system) PREFIX="/usr/local" ;;
        --prefix=*) PREFIX="${arg#--prefix=}" ;;
        --purge) PURGE=1 ;;
        --help|-h)
            printf '%s\n' "Pemakaian: ./uninstall.sh [--system] [--prefix=DIR] [--purge]"
            printf '%s\n' "--purge juga menghapus helper hotspot dan konfigurasi NM."
            exit 0 ;;
        *) printf 'Opsi tidak dikenal: %s\n' "$arg" >&2; exit 1 ;;
    esac
done

rm -f "$PREFIX/bin/diknom-network"
rm -rf "$PREFIX/share/diknom-network"
rm -f "$PREFIX/share/applications/diknom-network.desktop"
rm -f "$PREFIX/share/icons/hicolor/256x256/apps/diknom-network.png"
printf 'Aplikasi di %s dihapus.\n' "$PREFIX"
printf 'Konfigurasi pengguna tetap di ~/.config/diknom-network.\n'

if [ "$PURGE" -eq 1 ]; then
    if [ "$(id -u)" -ne 0 ]; then
        printf 'Untuk --purge helper, jalankan dengan sudo.\n' >&2
        exit 1
    fi
    rm -f /usr/local/lib/diknom-network/diknom-hotspot-helper
    rmdir /usr/local/lib/diknom-network 2>/dev/null || true
    rm -f /etc/NetworkManager/conf.d/99-diknom-hotspot.conf
    printf 'Helper hotspot dan konfigurasi NetworkManager dihapus.\n'
fi
