# 04-tmux.kak — integración Kakoune <-> tmux
# Destino: ~/.config/kak/autoload/04-tmux.kak
# Diseñado para funcionar DENTRO y FUERA de tmux sin romper nada.
#
# Requiere tmux.conf de este repo (tmux/tmux.conf):
#   - focus-events on, escape-time 0, truecolor, modo vi
#   - C-h/j/k/l para moverse entre paneles tmux (compatible kak)
#   - prefix C-space, popups con <prefix>g (lazygit), <prefix>f (sesiones)

# ── detección tmux ───────────────────────────────────────────────────────────
declare-option -hidden bool in_tmux false
evaluate-commands %sh{
    if [ -n "$TMUX" ]; then
        printf 'set-option global in_tmux true\n'
    else
        printf 'set-option global in_tmux false\n'
    fi
}

# renombrar ventana tmux al buffer actual (solo dentro de tmux)
hook global WinDisplay .* %{ nop %sh{
    if [ -n "$TMUX" ]; then
        tmux rename-window "kak: $(basename "$kak_buffile" 2>/dev/null || echo "$kak_bufname")" >/dev/null 2>&1 &
    fi
}}

# ── terminal: usar splits / popups de tmux cuando exista ─────────────────────
# Kakoune ya usa tmux automáticamente para `: terminal`, pero forzamos
# splits cómodos y popup (tmux >= 3.2) para herramientas efímeras.
define-command tmux-hsplit -params .. -docstring 'terminal en split horizontal tmux (o terminal normal fuera de tmux)' %{
    evaluate-commands %sh{
        if [ -n "$TMUX" ]; then
            printf 'terminal tmux split-window -h -c "#{pane_current_path}" %s\n' "$*"
        else
            printf 'terminal %s\n' "$*"
        fi
    }
}
define-command tmux-vsplit -params .. -docstring 'terminal en split vertical tmux' %{
    evaluate-commands %sh{
        if [ -n "$TMUX" ]; then
            printf 'terminal tmux split-window -v -c "#{pane_current_path}" %s\n' "$*"
        else
            printf 'terminal %s\n' "$*"
        fi
    }
}
define-command tmux-popup -params .. -docstring 'comando en tmux popup (fallback: terminal)' %{
    evaluate-commands %sh{
        if [ -n "$TMUX" ] && tmux display-message -p '#{version}' 2>/dev/null | grep -qE '^(3\.[2-9]|[4-9])'; then
            # popup centrado 80%x80%
            printf 'terminal tmux display-popup -E -w 80%% -h 80%% -d "#{pane_current_path}" %s\n' "$*"
        elif [ -n "$TMUX" ]; then
            printf 'terminal tmux split-window -h -c "#{pane_current_path}" %s\n' "$*"
        else
            printf 'terminal %s\n' "$*"
        fi
    }
}
define-command tmux-window -params .. -docstring 'nueva ventana tmux' %{
    evaluate-commands %sh{
        if [ -n "$TMUX" ]; then
            printf 'terminal tmux new-window -c "#{pane_current_path}" %s\n' "$*"
        else
            printf 'terminal %s\n' "$*"
        fi
    }
}

# ── REPL: enviar selección al panel tmux de al lado (fullstack) ──────────────
# Uso: selecciona código (node/python/…) y <space>r para enviarlo al REPL.
define-command tmux-send-selection -docstring 'envía selección al panel tmux vecino (REPL)' %{
    evaluate-commands %sh{
        if [ -z "$TMUX" ]; then
            printf 'echo -markup "{Error}fuera de tmux: nada a quien enviar"\n'
            exit 0
        fi
        printf '%s' "$kak_selection" | tmux load-buffer -
        tmux paste-buffer -p -t '{last}' 2>/dev/null
    }
}
define-command tmux-repl-node -docstring 'abre node REPL en split tmux' %{ tmux-vsplit node }
define-command tmux-repl-python -docstring 'abre python REPL en split tmux' %{ tmux-vsplit python3 }
define-command tmux-repl -docstring 'abre REPL según filetype en split tmux' %{
    evaluate-commands %sh{
        case "$kak_opt_filetype" in
            python) printf 'tmux-vsplit python3\n' ;;
            javascript|typescript|json|node) printf 'tmux-vsplit node\n' ;;
            go) printf 'tmux-vsplit "go run ." \n' ;;
            rust) printf 'tmux-vsplit evcxr 2>/dev/null || tmux-vsplit irust 2>/dev/null || tmux-vsplit bash\n' ;;
            sh|bash) printf 'tmux-vsplit bash\n' ;;
            lua) printf 'tmux-vsplit lua\n' ;;
            sql) printf 'tmux-vsplit pgcli 2>/dev/null || tmux-vsplit sqlite3 2>/dev/null || tmux-vsplit bash\n' ;;
            *) printf 'tmux-vsplit\n' ;;
        esac
    }
}

# ── navegación kak <-> tmux con C-h/j/k/l ────────────────────────────────────
# En tmux.conf de este repo, C-h/j/k/l (sin prefix) cambia de panel.
# Aquí mapeamos lo mismo para que desde kak puedas saltar al panel tmux
# vecino sin salir del modo normal. Fuera de tmux no hacen nada.
define-command tmux-navigate -params 1 -docstring 'navega al panel tmux (h/j/k/l)' %{
    evaluate-commands %sh{
        if [ -n "$TMUX" ]; then
            case "$1" in
                h) printf 'nop %%sh{ tmux select-pane -L >/dev/null 2>&1 }\n' ;;
                j) printf 'nop %%sh{ tmux select-pane -D >/dev/null 2>&1 }\n' ;;
                k) printf 'nop %%sh{ tmux select-pane -U >/dev/null 2>&1 }\n' ;;
                l) printf 'nop %%sh{ tmux select-pane -R >/dev/null 2>&1 }\n' ;;
            esac
        else
            printf 'echo -debug "tmux-navigate: fuera de tmux"\n'
        fi
    }
}
map global normal <c-h> ': tmux-navigate h<ret>' -docstring 'tmux pane izquierda'
map global normal <c-j> ': tmux-navigate j<ret>' -docstring 'tmux pane abajo'
map global normal <c-k> ': tmux-navigate k<ret>' -docstring 'tmux pane arriba'
map global normal <c-l> ': tmux-navigate l<ret>' -docstring 'tmux pane derecha'

# ── modo tmux bajo <espacio>t ─────────────────────────────────────────────────
declare-user-mode tmux
map global user t ': enter-user-mode tmux<ret>' -docstring 'tmux mode'

map global tmux h ': tmux-hsplit<ret>'              -docstring 'split horizontal'
map global tmux v ': tmux-vsplit<ret>'              -docstring 'split vertical'
map global tmux w ': tmux-window<ret>'              -docstring 'nueva ventana'
map global tmux p ': tmux-popup<ret>'               -docstring 'popup'
map global tmux r ': tmux-repl<ret>'                -docstring 'REPL según filetype'
map global tmux s ': tmux-send-selection<ret>'      -docstring 'enviar selección a REPL'
map global tmux g ': tmux-popup lazygit<ret>'       -docstring 'lazygit popup'
map global tmux d ': tmux-popup lazydocker<ret>'    -docstring 'lazydocker popup'
map global tmux f ': tmux-popup tmux-sessionizer<ret>' -docstring 'sessionizer'

# atajo directo: <space>r = enviar a REPL, <space>T = REPL según filetype
map global normal <space>r ': tmux-send-selection<ret>' -docstring 'enviar a tmux REPL'
map global normal <space>T ': tmux-repl<ret>'           -docstring 'abrir REPL'

# ── fzf en popup tmux ────────────────────────────────────────────────────────
hook global ModuleLoaded fzf %{ evaluate-commands %sh{
    if [ -n "$TMUX" ]; then
        printf 'set-option global fzf_implementation "tmux"\n'
        printf 'set-option global fzf_tmux_popup true 2>/dev/null || true\n'
    fi
}}

# ── lazygit en popup (si el plugin no lo hace) ───────────────────────────────
define-command lazygit-tmux -docstring 'lazygit en popup tmux' %{ tmux-popup lazygit }
