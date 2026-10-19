# 1.0.17
- addon/quota-limiter.sh (BARU): cron tiap menit. Mencatat pemakaian per akun (Xray + SSH) ke buku besar permanen `db/usage.db` yang tidak hilang saat xray restart/reload. Akun yang melewati kuota otomatis dinonaktifkan (Xray: client dicabut; SSH: akun dikunci + sesi dimatikan) dan dikirim notifikasi Telegram. Matikan penegakan: `touch /etc/vpn-script/.quota-enforce-off`.
- lib.sh: deteksi device Xray lewat daftar IP (statsonlineiplist, lalu access.log sebagai perkiraan); `ledger_reset` dipanggil saat reset trafik/edit limit; `setup_quota_limiter`; `UPDATE_FILES` + update routine memasang quota-limiter.
- install.sh: quota-limiter ikut diunduh dan diaktifkan.
- menu/tools.sh: User Online Xray menampilkan jumlah device + IP-nya.
