# kakrc — fullstack + tmux (punto de entrada)
# Repo: kakoune-dots | Destino: ~/.config/kak/kakrc
# Arch / Debian: instalado por instalador.sh (copia y reemplaza)

# ── runtimepath: que ~/.config/kak sea la base ──────────────────────────────
evaluate-commands %sh{
    kak_config="${XDG_CONFIG_HOME:-$HOME/.config}/kak"
    printf 'set-option global runtimepath "%s"\n' "$kak_config"
}

# ── plug.kak bootstrap (gestor de plugins) ───────────────────────────────────
evaluate-commands %sh{
    plug_dir="${XDG_CONFIG_HOME:-$HOME/.config}/kak/plugged/plug.kak"
    if [ ! -d "$plug_dir" ]; then
        mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/kak/plugged"
        git clone -q https://github.com/andreyorst/plug.kak.git "$plug_dir" >/dev/null 2>&1 &
    fi
    printf 'source "%s/rc/plug.kak"\n' "$plug_dir"
}
plug "andreyorst/plug.kak" noload

# Los archivos de autoload/ se cargan solos cuando están en ~/.config/kak/autoload/
# pero los sourceamos explícito para cuando se prueba desde el repo con KAKOUNE_CONFIG_DIR.
evaluate-commands %sh{
    kak_config="${XDG_CONFIG_HOME:-$HOME/.config}/kak"
    # si estamos dentro del repo (existe ./autoload), usar ruta relativa al kakrc real
    if [ -d "$kak_config/autoload" ]; then
        : # kak ya hace autoload, no hace falta nada
    fi
}

# ── colores ──────────────────────────────────────────────────────────────────
# gruvbox primero (tema pedido), fullstack-dark como fallback
try %{ colorscheme gruvbox } catch %{ try %{ colorscheme fullstack-dark } catch %{ colorscheme default } }

# ── mensaje de bienvenida ────────────────────────────────────────────────────
hook global KakBegin .* %{
    echo -debug "kakrc fullstack+tmux cargado"
}
