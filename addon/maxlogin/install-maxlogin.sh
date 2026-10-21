#!/bin/bash
# Pasang MaxLogin Xray (OPT-IN). Tidak mengubah SSHWS/Dropbear. Tidak menimpa config tanpa backup.
#   install-maxlogin.sh install     salin file + unit + config contoh (tidak menyalakan apa pun yang mengubah Xray)
#   install-maxlogin.sh check       cek nginx -t dengan include (tanpa reload)
#   install-maxlogin.sh rollback    hentikan service, lepas unit, pulihkan config Xray dari backup terbaru
set -u
SRC="$(cd "$(dirname "$0")" && pwd)"; DST=/etc/vpn-script/maxlogin
case "${1:-}" in
install)
  mkdir -p "$DST" /var/lib/vpn-script
  cp "$SRC"/maxlogin_core.py "$SRC"/maxlogin_service.py "$SRC"/xray_adapter.py "$SRC"/nginx-maxlogin*.inc "$DST"/
  [ -f /etc/vpn-script/maxlogin.json ] || cp "$SRC/maxlogin.json.example" /etc/vpn-script/maxlogin.json
  cp "$SRC/vpn-maxlogin.service" /etc/systemd/system/ && systemctl daemon-reload
  systemctl enable --now vpn-maxlogin && sleep 1 && curl -s http://127.0.0.1:10901/health; echo
  echo "Service jalan. Langkah berikut (manual, lihat docs/MAXLOGIN_XRAY.md): include Nginx + xray-sync."
  ;;
check)
  nginx -t ;;
rollback)
  systemctl disable --now vpn-maxlogin 2>/dev/null; rm -f /etc/systemd/system/vpn-maxlogin.service; systemctl daemon-reload
  B=$(ls -t /etc/xray/config.json.ml-bak.* 2>/dev/null | head -1)
  if [ -n "$B" ]; then cp "$B" /etc/xray/config.json && echo "config Xray dipulihkan dari $B (restart xray untuk menerapkan)"; else echo "tidak ada backup config Xray"; fi
  echo "Hapus baris include maxlogin di config Nginx secara manual lalu: nginx -t && systemctl reload nginx" ;;
*) echo "pakai: $0 install|check|rollback"; exit 1 ;;
esac
