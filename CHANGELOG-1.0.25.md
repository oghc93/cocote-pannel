# 1.0.25
- lib.sh: akun Xray dianggap online hanya jika trafiknya bergerak dalam 40 detik terakhir (access.log hanya mencatat koneksi baru, sehingga sebelumnya akun terlihat online sampai 5 menit setelah putus). Jendela log dipendekkan jadi 2 menit.
- lib.sh: get_xray_user_online/get_xray_user_ips tidak lagi berhenti kalau statistik online Xray ada tapi kosong; lanjut ke access.log. Ini juga memperbaiki penegakan limit device Xray yang sebelumnya selalu melihat 0 device.
- menu/tools.sh: daftar online Xray dari access.log ikut disaring dengan aktivitas trafik.
