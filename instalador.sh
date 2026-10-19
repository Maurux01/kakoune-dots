#!/usr/bin/env bash
# instalador.sh — kakoune-dots fullstack + tmux para Arch y Debian/Ubuntu
# Copia y REEMPLAZA los archivos en las rutas destino (con backup .bak).
#
# Uso:
#   ./instalador.sh                    # todo: paquetes + config + tmux + lsp
#   ./instalador.sh --only-config      # solo copiar configs (sin sudo/paquetes)
#   ./instalador.sh -f -y              # reemplazar sin preguntar
#   ./instalador.sh --no-tmux --no-lsp # sin tmux ni language servers
#   ./instalador.sh --help
#
# Destinos (Arch y Debian usan las mismas rutas XDG):
#   kakrc            -> ~/.config/kak/kakrc
#   autoload/*.kak   -> ~/.config/kak/autoload/
#   colors/*.kak     -> ~/.config/kak/colors/
#   scripts/*.py     -> ~/.config/kak/scripts/  (live server + markdown preview)
#   plugged/*        -> ~/.config/kak/plugged/ (plug.kak, gestionado por kak)
#   kak-lsp.toml     -> ~/.config/kak-lsp/kak-lsp.toml
#   tmux/tmux.conf   -> ~/.config/tmux/tmux.conf (+ ~/.tmux.conf fallback)

set -euo pipefail

# ── colores log ──────────────────────────────────────────────────────────────
if [ -t 1 ]; then
  BOLD=$'\e[1m'; DIM=$'\e[2m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; RED=$'\e[31m'; CYAN=$'\e[36m'; RESET=$'\e[0m'
else
  BOLD=''; DIM=''; GREEN=''; YELLOW=''; RED=''; CYAN=''; RESET=''
fi
log()  { printf '%s[*]%s %s\n' "$CYAN" "$RESET" "$*"; }
ok()   { printf '%s[ok]%s %s\n' "$GREEN" "$RESET" "$*"; }
warn() { printf '%s[!]%s %s\n' "$YELLOW" "$RESET" "$*" >&2; }
die()  { printf '%s[x]%s %s\n' "$RED" "$RESET" "$*" >&2; exit 1; }

# ── flags ────────────────────────────────────────────────────────────────────
ONLY_CONFIG=false
WITH_TMUX=true
WITH_LSP=true
WITH_PLUGINS=true
FORCE=false
ASSUME_YES=false

usage() {
  sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
  echo "Flags: [--only-config] [--no-tmux] [--no-lsp] [--no-plugins] [-f|--force] [-y|--yes] [--help]"
}

for arg in "$@"; do
  case "$arg" in
    --only-config) ONLY_CONFIG=true ;;
    --no-tmux) WITH_TMUX=false ;;
    --no-lsp) WITH_LSP=false ;;
    --no-plugins) WITH_PLUGINS=false ;;
    -f|--force) FORCE=true ;;
    -y|--yes) ASSUME_YES=true ;;
    -h|--help) usage; exit 0 ;;
    *) die "flag desconocido: $arg (usa --help)" ;;
  esac
done

# ── repo root (donde está este script) ───────────────────────────────────────
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_KAKRC="$REPO_DIR/kakrc"
SRC_AUTOLOAD="$REPO_DIR/autoload"
SRC_COLORS="$REPO_DIR/colors"
SRC_SCRIPTS="$REPO_DIR/scripts"
SRC_KAK_LSP="$REPO_DIR/kak-lsp/kak-lsp.toml"
SRC_TMUX="$REPO_DIR/tmux/tmux.conf"

[ -f "$SRC_KAKRC" ] || die "no se encontró $SRC_KAKRC (¿ejecutas desde el repo?)"
[ -d "$SRC_AUTOLOAD" ] || die "no se encontró $SRC_AUTOLOAD/"
[ -d "$SRC_COLORS" ] || die "no se encontró $SRC_COLORS/"
[ -d "$SRC_SCRIPTS" ] || die "no se encontró $SRC_SCRIPTS/"

# ── destinos ─────────────────────────────────────────────────────────────────
XDG_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
DST_KAK_DIR="$XDG_CONFIG/kak"
DST_AUTOLOAD="$DST_KAK_DIR/autoload"
DST_COLORS="$DST_KAK_DIR/colors"
DST_SCRIPTS="$DST_KAK_DIR/scripts"
DST_KAKRC="$DST_KAK_DIR/kakrc"
DST_KAK_LSP_DIR="$XDG_CONFIG/kak-lsp"
DST_KAK_LSP="$DST_KAK_LSP_DIR/kak-lsp.toml"
DST_TMUX_DIR="$XDG_CONFIG/tmux"
DST_TMUX="$DST_TMUX_DIR/tmux.conf"
DST_TMUX_FALLBACK="$HOME/.tmux.conf"

STAMP="$(date +%Y%m%d-%H%M%S)"

backup_if_exists() {
  local dst="$1"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    local bak="${dst}.bak-${STAMP}"
    log "backup: $dst -> $bak"
    mkdir -p "$(dirname "$bak")"
    mv -f "$dst" "$bak"
  fi
}

# copia y reemplaza un archivo (con backup salvo --force puro + aviso)
install_file() {
  local src="$1" dst="$2"
  [ -f "$src" ] || { warn "origen no existe, salto: $src"; return 0; }
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && ! $FORCE; then
    if ! $ASSUME_YES; then
      warn "existe $dst — se respaldará y reemplazará."
    fi
  fi
  backup_if_exists "$dst"
  cp -f "$src" "$dst"
  chmod 644 "$dst"
  ok "instalado: $dst"
}

# copia y reemplaza un directorio completo (autoload/, colors/)
install_dir() {
  local src="$1" dst="$2"
  [ -d "$src" ] || { warn "origen no existe, salto: $src"; return 0; }
  mkdir -p "$dst"
  # backup de archivos que serán sobrescritos
  while IFS= read -r -d '' f; do
    rel="${f#$src/}"
    if [ -e "$dst/$rel" ]; then
      backup_if_exists "$dst/$rel"
    fi
    mkdir -p "$(dirname "$dst/$rel")"
    cp -f "$f" "$dst/$rel"
    chmod 644 "$dst/$rel"
  done < <(find "$src" -type f -print0)
  ok "instalado: $dst/ ($(find "$src" -type f | wc -l) archivos)"
}

# ── detección distro ─────────────────────────────────────────────────────────
detect_distro() {
  if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    printf '%s' "${ID_LIKE:-$ID}"
  else
    printf 'unknown'
  fi
}
DISTRO_LIKE="$(detect_distro)"
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then SUDO="sudo"; else SUDO=""; fi
fi

is_arch()   { [[ "$DISTRO_LIKE" == *"arch"* ]] || command -v pacman >/dev/null 2>&1; }
is_debian() { [[ "$DISTRO_LIKE" == *"debian"* ]] || [[ "$DISTRO_LIKE" == *"ubuntu"* ]] || command -v apt-get >/dev/null 2>&1; }

# ── paquetes por distro ──────────────────────────────────────────────────────
install_pkgs_arch() {
  log "Arch: instalando con pacman…"
  $SUDO pacman -Sy --needed --noconfirm \
    kakoune tmux git curl fzf ripgrep fd bat python pandoc \
    kak-lsp nodejs npm python-pipx go rust-analyzer \
    shellcheck shfmt lua-language-server bash-language-server \
    yaml-language-server clang pyright eslint 2>/dev/null || {
    warn "algunos paquetes de Arch fallaron; continúo con lo disponible."
    $SUDO pacman -Sy --needed --noconfirm kakoune tmux git curl fzf ripgrep fd python pandoc || true
  }
  # LSPs de Node globales (si npm existe)
  if command -v npm >/dev/null 2>&1; then
    log "npm: instalando language servers globales…"
    $SUDO npm i -g typescript-language-server typescript vscode-langservers-extracted \
      tailwindcss-language-server eslint_d prettier \
      pyright dockerfile-language-server docker-langserver sqls 2>/dev/null || warn "npm -g falló parcialmente (quizá sin sudo/npm)."
  fi
  if command -v pipx >/dev/null 2>&1; then
    pipx install 'python-lsp-server[all]' ruff black 2>/dev/null || true
  fi
  if command -v cargo >/dev/null 2>&1; then
    cargo install taplo-cli marksman 2>/dev/null || true
  fi
  if command -v go >/dev/null 2>&1; then
    go install golang.org/x/tools/gopls@latest 2>/dev/null || true
  fi
}

install_pkgs_debian() {
  log "Debian/Ubuntu: instalando con apt…"
  $SUDO apt-get update
  $SUDO apt-get install -y \
    kakoune tmux git curl fzf ripgrep fd-find bat \
    nodejs npm python3 python3-pip pipx golang-go \
    pandoc shellcheck shfmt lua5.4 luarocks yamllint clangd 2>/dev/null || {
    warn "algunos paquetes apt fallaron; instalo el mínimo."
    $SUDO apt-get install -y kakoune tmux git curl fzf ripgrep python3 pandoc || true
  }
  # kak-lsp rara vez está en repos Debian estables → cargo / binario
  if ! command -v kak-lsp >/dev/null 2>&1 && $WITH_LSP; then
    if command -v cargo >/dev/null 2>&1; then
      log "compilando kak-lsp con cargo…"
      cargo install --locked kakoune-lsp 2>/dev/null || warn "cargo install kak-lsp falló."
    else
      warn "kak-lsp no está instalado. Instala cargo o descarga el binario de https://github.com/kakoune-lsp/kakoune-lsp/releases"
    fi
  fi
  if command -v npm >/dev/null 2>&1; then
    log "npm: instalando language servers globales…"
    $SUDO npm i -g typescript-language-server typescript vscode-langservers-extracted \
      tailwindcss-language-server bash-language-server yaml-language-server \
      eslint_d prettier pyright dockerfile-language-server 2>/dev/null || warn "npm -g falló parcialmente."
  fi
  if command -v pipx >/dev/null 2>&1; then
    pipx install 'python-lsp-server[all]' ruff black 2>/dev/null || pipx install ruff 2>/dev/null || true
  fi
  if command -v go >/dev/null 2>&1; then
    go install golang.org/x/tools/gopls@latest 2>/dev/null || true
    export PATH="$PATH:$HOME/go/bin"
  fi
  # rust-analyzer vía rustup si no vino por apt
  if ! command -v rust-analyzer >/dev/null 2>&1 && command -v rustup >/dev/null 2>&1; then
    rustup component add rust-analyzer 2>/dev/null || true
  fi
}

install_packages() {
  if is_arch; then
    install_pkgs_arch
  elif is_debian; then
    install_pkgs_debian
  else
    warn "distro no reconocida ($DISTRO_LIKE). Salto instalación de paquetes; solo copiaré configs."
    warn "instala manual: kakoune tmux git fzf ripgrep fd kak-lsp nodejs npm python go."
  fi
}

# ── plug.kak ─────────────────────────────────────────────────────────────────
install_plug() {
  local plug_dir="$DST_KAK_DIR/plugged/plug.kak"
  if [ -d "$plug_dir/.git" ]; then
    log "plug.kak ya existe, actualizando…"
    git -C "$plug_dir" pull --ff-only 2>/dev/null || warn "no se pudo actualizar plug.kak."
  else
    log "instalando plug.kak en $plug_dir…"
    mkdir -p "$(dirname "$plug_dir")"
    git clone -q https://github.com/andreyorst/plug.kak.git "$plug_dir" \
      || die "no se pudo clonar plug.kak (¿hay git + red?)."
  fi
  ok "plug.kak listo"
}

# ── main ─────────────────────────────────────────────────────────────────────
main() {
  echo "${BOLD}kakoune-dots — instalador fullstack+tmux (Arch/Debian)${RESET}"
  echo "${DIM}repo: $REPO_DIR | distro: $DISTRO_LIKE${RESET}"

  if ! $ONLY_CONFIG; then
    install_packages
  else
    log "--only-config: salto instalación de paquetes."
  fi

  log "copiando configs (copia y reemplaza)…"
  install_file "$SRC_KAKRC" "$DST_KAKRC"
  install_dir "$SRC_AUTOLOAD" "$DST_AUTOLOAD"
  install_dir "$SRC_COLORS" "$DST_COLORS"
  install_dir "$SRC_SCRIPTS" "$DST_SCRIPTS"
  chmod 755 "$DST_SCRIPTS"/*.py 2>/dev/null || true

  if $WITH_LSP; then
    if [ -f "$SRC_KAK_LSP" ]; then
      install_file "$SRC_KAK_LSP" "$DST_KAK_LSP"
    else
      warn "no hay kak-lsp.toml en el repo, salto."
    fi
  else
    log "--no-lsp: salto kak-lsp.toml."
  fi

  if $WITH_TMUX; then
    if [ -f "$SRC_TMUX" ]; then
      install_file "$SRC_TMUX" "$DST_TMUX"
      # fallback ~/.tmux.conf para tmux viejos que no leen XDG
      if [ ! -e "$DST_TMUX_FALLBACK" ] || $FORCE; then
        backup_if_exists "$DST_TMUX_FALLBACK"
        printf 'source-file "%s"\n' "$DST_TMUX" > "$DST_TMUX_FALLBACK"
        ok "instalado: $DST_TMUX_FALLBACK (source-file -> tmux.conf)"
      else
        log "$DST_TMUX_FALLBACK ya existe, no lo toco (usa -f para forzar)."
      fi
    else
      warn "no hay tmux.conf en el repo, salto."
    fi
  else
    log "--no-tmux: salto tmux.conf."
  fi

  if $WITH_PLUGINS && ! $ONLY_CONFIG; then
    install_plug
  elif $WITH_PLUGINS && $ONLY_CONFIG; then
    # aun en only-config conviene asegurar plug.kak si hay red
    if [ ! -d "$DST_KAK_DIR/plugged/plug.kak" ]; then
      install_plug || warn "sin plug.kak; los plugins se instalarán al abrir kak."
    fi
  else
    log "--no-plugins: salto plug.kak."
  fi

  # ── verificación ─────────────────────────────────────────────────────────
  echo
  log "verificando…"
  command -v kak >/dev/null 2>&1 && ok "kak: $(kak -version 2>/dev/null | head -1)" || warn "kak no encontrado en PATH."
  $WITH_TMUX && { command -v tmux >/dev/null 2>&1 && ok "tmux: $(tmux -V)" || warn "tmux no encontrado."; }
  $WITH_LSP && { command -v kak-lsp >/dev/null 2>&1 && ok "kak-lsp: $(kak-lsp --version 2>/dev/null | head -1)" || warn "kak-lsp no encontrado (ver nota Debian)."; }
  [ -f "$DST_KAKRC" ] && ok "kakrc en $DST_KAKRC" || warn "falta $DST_KAKRC"

  echo
  echo "${GREEN}${BOLD}Listo. Copia y reemplazo completados.${RESET}"
  echo "  kak + tmux:  tmux new -s dev  →  kak ."
  echo "  plugins:     abre kak y ejecuta  plug-install"
  echo "  LSP:         :lsp-diagnostics  |  <espacio>l (modo lsp)  |  gd/gr/K"
  echo "  tmux en kak: <espacio>t (h/v/w/p/r/s/g)  |  Ctrl-h/j/k/l navega paneles"
  echo "  tema:        gruvbox  |  powerline: <espacio>u (on/off)"
  echo "  live server: <espacio>s (toggle)  |  markdown preview: <espacio>v"
  echo "  backups:     *.bak-${STAMP}"
}

main "$@"
