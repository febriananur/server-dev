#  ╔═╗╔═╗╦ ╦╦═╗╔═╗
#  ╔═╝╚═╗╠═╣╠╦╝║
#  ╚═╝╚═╝╩ ╩╩╚═╚═╝

[[ $- != *i* ]] && return

# ================= ENV =================
export EDITOR='geany'
export VISUAL="$EDITOR"
export BROWSER='firefox'
export BAT_THEME="base16"
export HISTORY_IGNORE="(ls|cd|pwd|exit|history)"
export SUDO_PROMPT="Deploying root access for %u. Password pls: "

[[ -d "$HOME/.local/bin" ]] && PATH="$HOME/.local/bin:$PATH"

# ================= COMPLETION =================
autoload -Uz compinit
zcompdump="$HOME/.config/zsh/zcompdump"
compinit -d "$zcompdump"

autoload -Uz add-zsh-hook vcs_info
precmd() { vcs_info }

zstyle ':completion:*' menu select
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# ================= HISTORY =================
HISTFILE=~/.config/zsh/zhistory
HISTSIZE=5000
SAVEHIST=5000
setopt appendhistory sharehistory hist_ignore_all_dups

# ================= PROMPT =================
zstyle ':vcs_info:*' formats ' [%F{magenta}%f %F{yellow}%b%f]'
PS1='%F{blue} %f%F{magenta}%n%f %F{cyan}%~%f${vcs_info_msg_0_} %(?.%F{green}❯❯.%F{red}❯❯)%f '

# ================= ZLE WIDGET =================
expand-or-complete-with-dots() {
  echo -n "\e[31m…\e[0m"
  zle expand-or-complete
  zle redisplay
}
zle -N expand-or-complete-with-dots
bindkey '^I' expand-or-complete-with-dots

clear-keep-buffer() {
  zle clear-screen
}
zle -N clear-keep-buffer
bindkey '^xl' clear-keep-buffer

# ================= PLUGIN LOADER =================
source_if_exists() { [[ -f "$1" ]] && source "$1"; }

# fzf-tab
source_if_exists /usr/share/zsh/plugins/fzf-tab-git/fzf-tab.plugin.zsh
source_if_exists /usr/share/zsh-fzf-tab/fzf-tab.plugin.zsh

# autosuggestions
source_if_exists /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source_if_exists /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# history substring search  (HARUS SEBELUM bindkey)
source_if_exists /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
source_if_exists /usr/share/zsh-history-substring-search/zsh-history-substring-search.zsh

# ================= KEYBIND =================
# guard biar aman
if zle -l | grep -q history-substring-search-up; then
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
fi

bindkey '^[[3~' delete-char
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line

# ================= TOOLS =================
eval "$(zoxide init zsh)"

_auto_venv() {
  [[ -n "$VIRTUAL_ENV" && ! -f main.py ]] && deactivate 2>/dev/null
  [[ -z "$VIRTUAL_ENV" && -f .venv/bin/activate ]] && source .venv/bin/activate
}
add-zsh-hook chpwd _auto_venv

# ================= ALIAS =================
alias ls='eza --icons --color=always -a'
alias ll='eza --icons --color=always -la'
alias cat='bat --theme=base16'
alias n='nvim'
alias z='zoxide'

# =================================================
# 🚨 ABSOLUTELY LAST LINE – DO NOT PUT ANYTHING BELOW
# =================================================
source_if_exists /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source_if_exists /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

