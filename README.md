# kakoune-dots — config fullstack + tmux (Arch / Debian)

Kakoune listo para desarrollo fullstack, integrado con tmux.

## Estructura

```text
kakrc                  -> ~/.config/kak/kakrc
autoload/00-options.kak   base, UI, clipboard
autoload/01-plugins.kak   plug.kak + fzf, auto-pairs, surround, buffers, snippets…
autoload/02-lsp.kak       kak-lsp + atajos <espacio>l, gd/gr/K
autoload/03-languages.kak hooks JS/TS/HTML/CSS/Python/Rust/Go/Lua/Shell/YAML/SQL/MD…
autoload/04-tmux.kak      splits, popups, REPL, navegación C-h/j/k/l
autoload/05-mappings.kak  leader <espacio>, buffers, fzf, git
autoload/06-tools.kak     rg, make, git diff, filetree
colors/fullstack-dark.kak -> ~/.config/kak/colors/
kak-lsp/kak-lsp.toml      -> ~/.config/kak-lsp/kak-lsp.toml
tmux/tmux.conf            -> ~/.config/tmux/tmux.conf (+ ~/.tmux.conf)
instalador.sh             instalador Arch/Debian (copia y reemplaza)
```

## Instalación

```bash
git clone <tu-repo> kakoune-dots
cd kakoune-dots
chmod +x instalador.sh

./instalador.sh              # todo: paquetes + configs + tmux + lsp
./instalador.sh --only-config  # solo copiar/reemplazar configs, sin sudo
./instalador.sh -f -y          # reemplazar sin preguntar
./instalador.sh --no-tmux --no-lsp  # sin tmux ni servers
```

El instalador:

1. Detecta Arch (`pacman`) o Debian/Ubuntu (`apt`) vía `/etc/os-release`.
2. Instala `kakoune tmux git fzf ripgrep fd kak-lsp node npm python go…` + LSPs (`typescript-language-server`, `vscode-langservers`, `tailwindcss`, `pyright/pylsp`, `rust-analyzer`, `gopls`…).
3. **Copia y reemplaza** en destino (con backup `*.bak-FECHA`):
   `~/.config/kak/kakrc`, `~/.config/kak/autoload/`, `~/.config/kak/colors/`,
   `~/.config/kak-lsp/kak-lsp.toml`, `~/.config/tmux/tmux.conf`.
4. Instala/actualiza `plug.kak`.

Después abre kak y ejecuta `plug-install`.

## Uso kak + tmux

```text
tmux new -s dev   # o: tmux attach
kak .
```

| Tecla | Acción |
|---|---|
| `<espacio>t` | modo tmux: `h` split-h, `v` split-v, `w` ventana, `p` popup, `r` REPL, `s` enviar selección, `g` lazygit |
| `Ctrl-h/j/k/l` | moverse entre paneles tmux (igual en tmux.conf, sin prefix) |
| `<espacio>r` / `<espacio>T` | enviar selección a REPL / abrir REPL según filetype |
| `<espacio>l` | modo LSP (`d`ef, `r`ef, `h`over, re`n`ame, `a`ctions, `f`ormat, `e`rrors) |
| `gd` `gr` `K` | definition / references / hover |
| `<espacio>p` `<espacio>g` `<espacio>B` | fzf archivos / grep / buffers |
| `<c-p>` `<c-n>` | fzf-mode / filetree |

tmux (prefix `C-Space`): `|`/`-` splits, `g` lazygit popup, `f` sesiones (fzf), `C-h/j/k/l` navegar, `r` recargar.

## Requisitos

- Arch: `pacman -S kakoune tmux kak-lsp …` (lo hace el instalador).
- Debian/Ubuntu: `apt install kakoune tmux …` + `kak-lsp` vía cargo si no está en repos (lo intenta el instalador).
