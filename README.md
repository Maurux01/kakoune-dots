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
autoload/05-mappings.kak  leader <espacio>, buffers, fzf, git, live server
autoload/06-tools.kak     rg, make, git diff, filetree
autoload/07-web.kak       live server + markdown preview
colors/gruvbox.kak        -> ~/.config/kak/colors/ (tema gruvbox)
colors/fullstack-dark.kak -> ~/.config/kak/colors/
scripts/live_server.py    -> ~/.config/kak/scripts/ (servidor con livereload)
scripts/md_preview.py     -> ~/.config/kak/scripts/ (markdown -> HTML)
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
   `~/.config/kak/scripts/`, `~/.config/kak-lsp/kak-lsp.toml`,
   `~/.config/tmux/tmux.conf`.
4. Instala/actualiza `plug.kak`.

Después abre kak y ejecuta `plug-install` (instala powerline, render-markdown,
fzf, livedown, etc.) y reiniciá kak para que la powerline y el tema carguen.

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
| `<espacio>s` `<espacio>S` | live server on/off · parar |
| `<espacio>v` `<espacio>V` | markdown preview (browser) · parar |
| `<espacio>u` | powerline on/off |
| `<espacio>h` | live server: arrancar |

## Tema gruvbox + powerline

El tema es **gruvbox** (`colors/gruvbox.kak`, paleta base16 dark-medium) y la
modeline usa **powerline.kak** (`andreyorst/powerline.kak`) con el tema
`gruvbox` del propio plugin.

Módulos de la powerline: `git bufname filetype mode_info line_column position lsp`.
Separador: `triangle` (necesita una Nerd Font en la terminal; para ASCII puro
usá `powerline-separator global ascii-triangle`).

Comandos útiles: `powerline-toggle`, `powerline-theme gruvbox`,
`powerline-format global 'git bufname filetype position'`,
`powerline-separator global curve`.

## Live server y markdown preview

- `live server`: `scripts/live_server.py` sirve el proyecto en
  `http://127.0.0.1:8080/` e inyecta un script de livereload en el HTML: al
  guardar, el navegador se recarga solo. Se abre con `<espacio>s`.
  Para frontends con `package.json` usá `npm run dev` y el live server como
  proxy estático, o directamente el script de tu bundler.
- `markdown preview`: `scripts/md_preview.py` convierte el `.md` a HTML con
  pandoc (o conversor interno si no está) y lo sirve con autoreload en
  `http://127.0.0.1:8081/`. Se abre con `<espacio>v`.
  Además, `render-markdown.kak` renderiza el markdown dentro del editor
  (encabezados, código, listas, tablas) y `kakoune-livedown` da una preview
  alternativa (`<espacio>o`, requiere `npm install -g livedown`).

Ambos usan `python3` (ya instalado por el instalador) y `pandoc` es opcional.

## Workflow fullstack

| Necesitás | Comando |
|---|---|
| backend node/python/go/rust | `<espacio>T` abre REPL según filetype; `<espacio>r` manda la selección al REPL |
| frontend estático | `<espacio>s` live server con autoreload |
| markdown (docs, README) | `<espacio>v` preview en browser; en el editor, render nativo |
| JSON / env / lockfiles | `cat` de node_modules ignorado, `jq` highlight, `<espacio>` + `p` fzf |
| API / GraphQL | `kak-lsp` con los servers del `kak-lsp.toml`; `gd`/`gr` para saltar a definiciones |
| docker | `<espacio>t` `d` → `tmux-popup lazydocker` |
| git | `<espacio>G` lazygit, `<espacio>D` diff, gutter con `git show-diff` |

tmux (prefix `C-Space`): `|`/`-` splits, `g` lazygit popup, `f` sesiones (fzf), `C-h/j/k/l` navegar, `r` recargar.

## Requisitos

- Arch: `pacman -S kakoune tmux kak-lsp …` (lo hace el instalador).
- Debian/Ubuntu: `apt install kakoune tmux …` + `kak-lsp` vía cargo si no está en repos (lo intenta el instalador).
