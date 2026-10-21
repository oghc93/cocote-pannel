# 1.0.27
- Masa toleransi sebelum penalti limit device (SSH dan Xray): melebihi limit baru dihukum kalau terus-menerus selama PENALTY_GRACE_SECONDS (default 60 detik, atur di penalty.conf). Berpindah WiFi<->data sesaat tidak lagi memicu penalti.
- lib.sh: jendela IP access.log Xray dipendekkan jadi 45 detik supaya IP jaringan lama cepat hilang setelah pindah jaringan.
