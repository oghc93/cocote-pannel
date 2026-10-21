# 1.0.12
- install.sh: cek domain->IP tidak lagi bergantung pada `dig` (belum terpasang di VPS baru). Memakai dig/getent/host/nslookup/DoH, cocok jika salah satu IP domain = IP server.
- install.sh, lib.sh (change_domain), menu/changedomain.sh: penerbitan SSL pertama memakai `--server letsencrypt`. Sebelumnya memakai CA bawaan acme.sh (ZeroSSL) sehingga gagal diam-diam dan jatuh ke sertifikat self-signed (ikon "tidak aman" di browser). Sebab kegagalan sekarang ditampilkan.
