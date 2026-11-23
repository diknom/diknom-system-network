# Contributing

Terima kasih sudah ingin mengembangkan **DikNom System Network**.

## Sebelum membuka issue atau pull request

- Jangan menyertakan data pribadi: SSID, IP, MAC/BSSID, hostname, nama
  koneksi, password, token, atau screenshot mentah.
- Untuk bug jaringan, sertakan distro, versi kernel, driver Wi-Fi, dan pesan
  error yang sudah disamarkan.
- Cek issue yang sudah ada sebelum membuat issue baru.

## Pull request

1. Fork repo dan buat branch dari `main`.
2. Jaga perubahan tetap fokus dan kecil.
3. Uji dengan Python 3 + Tkinter:
   ```bash
   python3 -m py_compile diknom-network diknom-hotspot-helper
   ./install.sh --no-deps --no-hotspot --prefix=/tmp/diknom-test
   ```
4. Jangan menambahkan dependensi berat atau driver DKMS tanpa diskusi.
5. Jelaskan perubahan, cara menguji, dan dampaknya pada distro lain.

## Gaya kode

- Python 3, Tkinter, tanpa framework web/Electron.
- Pertahankan fallback sysfs dan kompatibilitas lintas distro.
- Semua aksi root harus lewat helper/pkexec; jangan meminta password di chat
  atau mencetaknya ke log.
- Jangan commit `~/.config/diknom-network/config.json`, screenshot mentah,
  atau file cache.

## Lisensi kontribusi

Dengan mengirim pull request, kamu setuju kontribusi dilisensikan di bawah
MIT License yang sama dengan proyek ini.
