# 1.0.14
- install.sh: setelah langkah SSL, tampilkan Subject, Issuer, dan masa berlaku sertifikat yang benar-benar terpasang. Jika self-signed (cadangan), tampilkan peringatan dan cara menerbitkan ulang, tidak lagi selalu "[OK]".
- install.sh: pendaftaran akun acme.sh memakai `--server letsencrypt` (sebelumnya ke CA bawaan ZeroSSL sehingga bisa tertahan lama saat ZeroSSL error 502).
- install.sh: variabel warna DIM didefinisikan (sebelumnya kosong).
