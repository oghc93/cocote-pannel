# 1.0.18
- Penalti limit device bertingkat untuk SSH (WS/SSL/nTLS) dan Xray: pelanggaran ke-1 diputus 2 menit, ke-2 30 menit, ke-3 2 jam, ke-4+ 24 jam, lalu akun aktif lagi otomatis. Atur di /etc/vpn-script/penalty.conf (PENALTY_STEPS, PENALTY_DECAY_HOURS).
- addon/dropbear-fastkick.sh: kini menghitung sesi Dropbear + OpenSSH per akun dan menegakkan penalti. addon/xray-maxlogin-daemon.sh: mencabut akun selama penalti, memulihkannya setelah habis.
- addon/ssh-maxlogin.sh: batas PAM = limit+1 supaya pelanggaran terdeteksi (sebelumnya sesi ke-3 hanya ditolak diam-diam).
- lib.sh: fungsi penalty_*; update routine menerapkan ulang batas PAM ke semua akun SSH.
- Panel: badge "Diputus s/d HH:MM (pelanggaran ke-N)" di kolom status.
