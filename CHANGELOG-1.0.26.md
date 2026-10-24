# 1.0.26
- lib.sh: IP Xray satu kisaran digabung jadi satu device (operator seluler memakai CGNAT, satu HP keluar lewat beberapa IP bersamaan). Default per /16 untuk IPv4 dan /64 untuk IPv6. Atur dengan XRAY_IP_GROUP_BITS (16/24/32) di /etc/vpn-script/penalty.conf.
- menu/tools.sh: daftar online Xray dari access.log memakai penggabungan yang sama.
