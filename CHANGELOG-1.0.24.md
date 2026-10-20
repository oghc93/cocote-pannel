# 1.0.24
- addon/real-ip-fix.sh (BARU): saat multiplex 443 aktif, HAProxy kini mengirim PROXY protocol ke Nginx dan Nginx memakainya sebagai IP asli. Sebelumnya semua pemakai terlihat 127.0.0.1 sehingga jumlah device Xray tidak terdeteksi dan limit device Xray tidak bisa jalan. Otomatis dijalankan oleh update, dengan backup + rollback bila config tidak valid.
- addon/enable-ssl-multiplex.sh dan lib.sh (regenerate_nginx_conf): instalasi baru langsung memakai PROXY protocol.
