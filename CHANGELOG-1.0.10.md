# 1.0.10
- Multiplex 443: tambah jalur OpenVPN-over-SSL. HP bisa pakai OpenVPN di HTTP Custom mode SNI saja
  (tanpa payload, tanpa proxy) lewat remote domain:443, sama seperti SSH-SSL. Dideteksi dari paket
  pembuka OpenVPN (HARD_RESET V2/V3) setelah TLS dibuka HAProxy, lalu diteruskan ke OpenVPN TCP.
- Update Script menerapkan jalur ini otomatis di VPS yang multiplex 443-nya aktif (ada verifikasi + rollback).
- Jalur WebSocket lama (payload GET /ovpn-ws) tetap jalan.
