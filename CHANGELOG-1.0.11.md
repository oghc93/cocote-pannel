# 1.0.11
- Blok /api/ & /panel/ panel web dipindah ke snippet Nginx (vpn-panel-ui.conf) yang di-include dari
  config utama, jadi tidak hilang lagi saat config Nginx dibuat ulang (multiplex 443, change domain, dll).
- Multiplex 443: HAProxy meneruskan semua method HTTP (POST/PUT/DELETE/HEAD/OPTIONS/PATCH), bukan hanya GET,
  supaya API panel tetap jalan setelah multiplex diterapkan ulang.
