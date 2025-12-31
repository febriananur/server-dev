#!/usr/bin/env bash
set -euo pipefail

# =============================
# AUTO SUDO
# =============================
if [[ $EUID -ne 0 ]]; then
  exec sudo -E "$0" "$@"
fi

USER_NAME="${SUDO_USER:-$USER}"
USER_HOME="$(eval echo "~$USER_NAME")"

# =============================
# CONFIG SOURCE
# =============================
RAW_BASE="https://raw.githubusercontent.com/febriananur/server-dev/main"

# =============================
# OS DETECTION
# =============================
if [[ -f /etc/arch-release ]]; then
  OS="arch"
elif [[ -f /etc/os-release ]]; then
  . /etc/os-release
  [[ "$ID" == "ubuntu" || "$ID_LIKE" == *"debian"* ]] && OS="ubuntu" || exit 1
else
  exit 1
fi




# =============================
# INSTALL GUM
# =============================
if ! command -v gum &>/dev/null; then
  if [[ "$OS" == "arch" ]]; then
    pacman -Sy --needed --noconfirm gum git curl gpg
  else
    apt update
    apt install -y curl gpg git
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key \
      | gpg --dearmor -o /etc/apt/keyrings/charm.gpg --yes
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" \
      > /etc/apt/sources.list.d/charm.list
    apt update && apt install -y gum
  fi
fi

# =============================
# UI
# =============================
gum style --border rounded --padding "1 3" --foreground 212 \
  "🚀 Dev Environment Installer"
gum confirm "Mulai instalasi?" || exit 0

# =============================
# PACKAGE SELECT
# =============================
set +e
SELECTED_PKGS=$(gum choose --no-limit --height 10 \
  zsh tmux fd zoxide lazydocker eza bat)
set -e

[[ -z "$SELECTED_PKGS" ]] && exit 0
PACKAGES=$(echo "$SELECTED_PKGS" | tr '\n' ' ')
TOTAL=$(echo "$PACKAGES" | wc -w)
STEP=0

arch_install() { pacman -S --needed --noconfirm "$@"; }
ubuntu_install() { apt install -y "$@"; }

log_step() {
  STEP=$((STEP + 1))
  gum log --level info "[$STEP/$TOTAL] $1"
}

# =============================
# TPM
# =============================
install_tpm() {
  local TPM_DIR="$USER_HOME/tpm"
  [[ -d "$TPM_DIR" ]] && return
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  chown -R "$USER_NAME:$USER_NAME" "$TPM_DIR"
}

# =============================
# INSTALL LOOP
# =============================
for pkg in $PACKAGES; do
  case "$pkg" in
    zsh)
      log_step "zsh"
      [[ "$OS" == "arch" ]] \
        && arch_install zsh zsh-autosuggestions zsh-syntax-highlighting \
        || ubuntu_install zsh zsh-autosuggestions zsh-syntax-highlighting
      ;;
    tmux)
      log_step "tmux"
      [[ "$OS" == "arch" ]] && arch_install tmux || ubuntu_install tmux
      install_tpm
      ;;
    fd)
      log_step "fd"
      [[ "$OS" == "arch" ]] && arch_install fd || ubuntu_install fd-find
      ln -sf "$(which fdfind 2>/dev/null || true)" /usr/local/bin/fd || true
      ;;
    zoxide)
      log_step "zoxide"
      if [[ "$OS" == "arch" ]]; then
          arch_install zoxide
      else
          curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
      fi

      # FIX DATA DIRECTORY UBUNTU/DEBIAN ONLY
      if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
          mkdir -p "$USER_HOME/.local/share/zoxide"
          chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.local/share/zoxide"
          chmod 700 "$USER_HOME/.local/share/zoxide"
      fi
      ;; 
    lazydocker)
      log_step "lazydocker"
      curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
      ;;
    eza)
      log_step "eza"
      [[ "$OS" == "arch" ]] && arch_install eza || ubuntu_install eza
      ;;
    bat)
      log_step "bat"
      [[ "$OS" == "arch" ]] && arch_install bat || ubuntu_install bat
      ln -sf "$(which batcat 2>/dev/null || true)" /usr/local/bin/bat || true
      ;;
  esac
done

# =============================
# CONFIG COPY (UPDATED)
# =============================
if gum confirm "Salin konfigurasi dari GitHub?"; then
  CONFIGS=$(gum choose --no-limit zsh tmux)

  for cfg in $CONFIGS; do
    case "$cfg" in
      zsh)
        gum log --level info "Copy .zshrc"
        curl -fsSL "$RAW_BASE/config/.zshrc" -o "$USER_HOME/.zshrc"
        chown "$USER_NAME:$USER_NAME" "$USER_HOME/.zshrc"
        ;;
      tmux)
        gum log --level info "Copy tmux config (XDG)"
        TMUX_DIR="$USER_HOME/.config/tmux"
        mkdir -p "$TMUX_DIR"
        curl -fsSL "$RAW_BASE/config/tmux.conf" -o "$TMUX_DIR/tmux.conf"
        chown -R "$USER_NAME:$USER_NAME" "$TMUX_DIR"
        ;;
    esac
  done
fi

# =============================
# DONE
# =============================
gum style --border rounded --padding "1 3" --border-foreground 42 \
"✅ Selesai!

tmux config:
~/.config/tmux/tmux.conf

TPM:
~/tpm

Next:
• tmux → prefix + I
• jalankan zsh

Happy hacking 😎"

