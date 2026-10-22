#!/bin/bash
# ============================================================
#   CHANELOG VPN SCRIPT - WEB PANEL
#   Pasang panel web (repo oghc93/cocote-3x-ui) dari menu.
#   Sudah terpasang -> tampilkan info + opsi update (vpn-update).
# ============================================================

SCRIPT_DIR="/etc/vpn-script"
source "$SCRIPT_DIR/lib.sh"

PANEL_RAW="https://raw.githubusercontent.com/oghc93/cocote-3x-ui/refs/heads/main/deploy"
PANEL_WEB="/var/www/vpn-panel/index.html"

panel_installed() { [[ -f "$PANEL_WEB" ]]; }

panel_install() {
  echo ""
  echo -e "  ${CYAN}[*]${NC} Mengunduh installer panel..."
  local tmp; tmp=$(mktemp)
  if ! wget -q --timeout=30 "$PANEL_RAW/install.sh" -O "$tmp" || [[ ! -s "$tmp" ]] || ! bash -n "$tmp" 2>/dev/null; then
    echo -e "  ${RED}[!] Gagal mengunduh installer panel dari:${NC}"
    echo -e "  ${DIM}$PANEL_RAW/install.sh${NC}"
    echo -e "  ${YELLOW}Cek koneksi VPS / pastikan file sudah ada di GitHub (repo cocote-3x-ui).${NC}"
    rm -f "$tmp"; return 1
  fi
  echo -e "  ${CYAN}$LINE${NC}"
  bash "$tmp"
  local rc=$?
  rm -f "$tmp"
  if [[ $rc -ne 0 ]]; then
    echo -e "\n  ${RED}[!] Instalasi panel gagal (kode $rc). Lihat pesan di atas.${NC}"
    return 1
  fi
  # pasang perintah vpn-update bila belum ada
  if ! command -v vpn-update >/dev/null 2>&1; then
    local vu; vu=$(mktemp)
    if wget -q --timeout=30 "$PANEL_RAW/update.sh" -O "$vu" && [[ -s "$vu" ]] && bash -n "$vu" 2>/dev/null; then
      install -m 755 "$vu" /usr/local/bin/vpn-update
    fi
    rm -f "$vu"
  fi
  echo -e "\n  ${GREEN}[OK]${NC} Panel terpasang. Buka: ${WHITE}https://$(get_domain)/panel/${NC}"
  return 0
}

panel_menu() {
  clear
  echo -e "${CYAN}$UI_BOX_TOP${NC}"
  ui_line_center "${WHITE}${BOLD}WEB PANEL${NC}"
  echo -e "${CYAN}$UI_BOX_MID${NC}"
  if panel_installed; then
    ui_line "Status : ${GREEN}terpasang${NC}"
    ui_line "Alamat : ${WHITE}https://$(get_domain)/panel/${NC}"
    echo -e "${CYAN}$UI_BOX_MID${NC}"
    ui_2col "$(ui_menu_num 01 'Update panel')" "$(ui_menu_num 02 'Pasang ulang panel')"
    ui_line "$(ui_menu_num 00 'Kembali' "$DIM")"
  else
    ui_line "Status : ${YELLOW}belum terpasang${NC}"
    echo -e "${CYAN}$UI_BOX_MID${NC}"
    ui_line "$(ui_menu_num 01 'Pasang panel sekarang')"
    ui_line "$(ui_menu_num 00 'Kembali' "$DIM")"
  fi
  echo -e "${CYAN}$UI_BOX_BOT${NC}"
  echo ""
  echo -ne "  ${WHITE}${BOLD}Pilih${NC} ${DIM}›${NC} "
  read -r c

  if panel_installed; then
    case "$c" in
      1) if command -v vpn-update >/dev/null 2>&1; then vpn-update; else echo -e "  ${RED}[!] vpn-update belum terpasang. Pilih 2 untuk pasang ulang.${NC}"; fi ;;
      2) echo -ne "  ${YELLOW}Pasang ulang panel? Ketik 'YA'${NC}: "; read -r y
         [[ "$y" == "YA" ]] && panel_install || echo -e "  ${YELLOW}[!] Dibatalkan${NC}" ;;
      0|"") bash "$SCRIPT_DIR/menu.sh"; return ;;
      *) echo -e "  ${RED}[!] Pilihan tidak valid${NC}" ;;
    esac
  else
    case "$c" in
      1) panel_install ;;
      0|"") bash "$SCRIPT_DIR/menu.sh"; return ;;
      *) echo -e "  ${RED}[!] Pilihan tidak valid${NC}" ;;
    esac
  fi
  echo ""
  read -rp "  Tekan Enter untuk kembali..." _
  panel_menu
}

panel_menu
