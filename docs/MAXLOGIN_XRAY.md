# MaxLogin Xray (prototipe) — VLESS / VMess / Trojan lewat WS TLS

STATUS: **prototipe, belum diuji di VPS nyata.** Teruji di sandbox: unit + integrasi Nginx/Xray asli (lihat "Hasil tes").
Cakupan: hanya transport WS (443 lewat HAProxy→Nginx). gRPC/TCP/HTTPUpgrade/XHTTP belum.

## Hasil audit (Xray 26.3.27)
- Xray-core resmi **tidak punya** batas perangkat per akun (hanya usulan, issue #3667). Fork pihak ketiga ada, tidak diaudit.
- `xray api`: statsonline / statsonlineiplist / adu / rmu / sib dll. ada, tapi **bukan** MaxLogin: statsonline ≠ jumlah perangkat; `adu/rmu` hanya mengubah daftar akun.
- **Terbukti di tes:** `rmu` TIDAK memutus koneksi yang sudah berjalan. Mencabut akun tidak menendang sesi aktif.
- `adu` keluar kode 0 walau gagal ("Added 0 user(s)"); adapter membaca keluarannya.
- Xray tidak menyediakan hook "tolak koneksi baru bila penuh". Maka pengecekan dipasang **sebelum** Xray, di Nginx `auth_request`.

## Arsitektur
```
klien --TLS--> HAProxy --> Nginx --auth_request--> maxlogin_service (SQLite, 127.0.0.1:10901)
                             | (jika 200) rewrite /<proto>-ws/<token> -> /<proto>-ml
                             v
                       Xray inbound "-ml" (127.0.0.1:10102 vless, 10101 vmess, 10105 trojan)
```
- Tiap akun berlimit N punya N **slot**, tiap slot satu token acak di path link: `/vless-ws/<token>`. Token milik akun → batas berlaku lintas protokol (token yang sama bisa dipakai di vless/vmess/trojan).
- Slot terikat ke "tanda asal" (IP dikelompokkan: pool XL/Axis, /16, IPv6 /64) selama aktif. Asal lain di slot aktif → **403 device_limit**; perangkat lama tidak diputus oleh penolakan itu. Banyak koneksi dari satu asal = satu perangkat.
- TTL (`ttl_seconds`) membebaskan slot yang tidak terlihat; sweeper juga memperbarui "terakhir terlihat" bila trafik akun bergerak (statsquery). Atomik: SQLite WAL + `BEGIN IMMEDIATE`.
- Akun berlimit **dipindah** dari inbound lama ke inbound `-ml` (`xray-sync`), supaya UUID yang sama tak bisa dipakai di path polos `/vless-ws` (bypass terbukti ada sebelum dipindah).
- Akun expired/dinonaktifkan/dihapus di db script → akun MaxLogin dinonaktifkan; token diputar ulang bila dihidupkan lagi.
- Log JSON per baris `/var/log/vpn-maxlogin.log`: `login_allowed`, `login_denied` (+reason), `session_ended`, `account_disabled`, `xray_sync`.

## Keterbatasan (jujur)
1. "device_id" tidak bisa benar-benar terverifikasi: token bisa disalin bersama link. Perlindungan = satu token hanya satu asal pada satu waktu (artinya masih bergantung IP). Dua jaringan berbeda pada satu HP (mis. WiFi + data) dihitung 2 asal bila beda kelompok IP.
2. Tidak ada heartbeat nyata untuk WS yang sudah tersambung. TTL + trafik adalah pendekatan; koneksi diam >TTL melepas slotnya walau soketnya hidup.
3. Pencabutan tidak memutus sesi aktif (sifat Xray). Untuk menendang: restart Xray (memutus semua) atau tunggu sesi berakhir.
4. Menambah inbound `-ml` pertama kali **butuh sekali restart Xray** (memutus semua pengguna sebentar). Setelah itu akun ditambah/dipindah via API tanpa restart.
5. Layanan MaxLogin mati → Nginx membalas 5xx = **fail-closed** (koneksi baru ditolak, tidak ada bypass). `on_error` hanya mengatur kesalahan internal di dalam service. Fail-open sengaja tidak dipakai karena membuka bypass.
6. Redis tidak dipakai (satu VPS cukup SQLite). Banyak VPS berbagi batas → perlu store bersama (belum).
7. Link lama (path polos) untuk akun berlimit berhenti bekerja; pembeli harus memakai link bertoken (`links USER`).

## File
- `addon/maxlogin/maxlogin_core.py` kebijakan + registri sesi/slot (SQLite)
- `addon/maxlogin/maxlogin_service.py` HTTP `/auth`, sweeper, CLI
- `addon/maxlogin/xray_adapter.py` pindah akun ke inbound -ml (backup + API adu/rmu)
- `addon/maxlogin/nginx-maxlogin.inc`, `nginx-maxlogin-http.inc`, `vpn-maxlogin.service`, `maxlogin.json.example`, `install-maxlogin.sh`
- `tests/maxlogin/test_policy.py` (unit), `integration.py`, `test_xray_adapter.py` (integrasi nyata)
Tidak menyentuh SSHWS/Dropbear. Belum dimasukkan ke `run_update` (sengaja, opt-in).

## Hasil tes (sandbox)
- Unit `test_policy.py`: 18/18 (logika, bukan Xray).
- Integrasi `integration.py` (Nginx + Xray + klien Xray asli, snippet asli): 20/20 — limit 2 perangkat, perangkat ke-3 ditolak 403, perangkat lama tetap jalan, lintas protokol, TTL, rotate, disable, service mati/restart, 8 perangkat berebut 1 slot → tepat 1 lolos.
- Integrasi `test_xray_adapter.py` (Xray asli): 11/11 — path polos akun berlimit ditolak, jalur -ml jalan, tanpa restart via API.
- BELUM: HAProxy+TLS+real-IP penuh, CGNAT/ISP nyata, aplikasi klien nyata (HTTP Injector, v2rayNG), beban.

## Pasang (di VPS TES dulu)
1. Upload repo, lalu: `bash /etc/vpn-script/addon/maxlogin/install-maxlogin.sh install` (service saja).
2. `cp /etc/vpn-script/maxlogin.json` periksa; `python3 /etc/vpn-script/maxlogin/maxlogin_service.py sync` lalu `... links USER`.
3. Nginx (backup dulu): `cp /etc/nginx/conf.d/<file>.conf{,.bak}`; letakkan `include /etc/vpn-script/maxlogin/nginx-maxlogin-http.inc;` di blok http, `include /etc/vpn-script/maxlogin/nginx-maxlogin.inc;` di blok server 8443 sebelum location lama; `nginx -t && systemctl reload nginx`.
4. Xray: `python3 .../maxlogin_service.py xray-sync` (menulis config + backup), `systemctl restart xray` (sekali). Setelah itu set `"xray_manage": true` bila ingin otomatis.
5. Tes: pakai 2 perangkat dengan link slot yang sama → perangkat kedua harus ditolak.

## Rollback
`bash install-maxlogin.sh rollback`, hapus 2 baris include Nginx, `nginx -t && systemctl reload nginx`, `systemctl restart xray`. Backup: `/etc/xray/config.json.ml-bak.<ts>`.
