# 07-web.kak — live server + markdown preview
# Destino: ~/.config/kak/autoload/07-web.kak
#
# live server: sirve el proyecto con livereload (scripts/live_server.py)
# markdown preview: renderiza el .md a HTML y lo sirve con autoreload
#
# Depende de los scripts del repo en ~/.config/kak/scripts/

# -- opciones ---------------------------------------------------------------
declare-option -hidden int web_server_port 8080
declare-option -hidden int web_preview_port 8081
declare-option -hidden str web_server_root %sh{ pwd }
declare-option -hidden str web_preview_dir %sh{ printf '%s' "${TMPDIR:-/tmp}/kak-md-preview" }
declare-option -hidden str web_preview_file ''

# -- helper: ruta de los scripts del repo -----------------------------------
# ~/.config/kak/scripts/ (instalado) o ../scripts/ (repo, KAKOUNE_CONFIG_DIR)
declare-option -hidden str web_scripts_dir %sh{
    candidates="$kak_config/scripts"
    src_dir=$(dirname "${kak_source:-}")
    [ -d "$src_dir/../scripts" ] && candidates="$src_dir/../scripts"
    printf '%s' "$candidates"
}

# -- live server ------------------------------------------------------------
define-command -hidden web-server-start -params 0..1 -docstring 'web-server-start [root]: sirve <root> con livereload en el navegador' %{
    evaluate-commands %sh{
        root="${1:-}"
        if [ -z "$root" ]; then
            if [ -n "$kak_buffile" ] && [ -f "$kak_buffile" ]; then
                root=$(dirname "$kak_buffile")
            else
                root="$PWD"
            fi
        fi
        root=$(cd "$root" 2>/dev/null && pwd) || {
            printf 'echo -markup {Error}live server: no existe el directorio\n'
            exit 0
        }

        script="$kak_opt_web_scripts_dir/live_server.py"
        if [ ! -f "$script" ]; then
            printf 'echo -markup {Error}falta %s (reinstalá el repo)\n' "$script"
            exit 0
        fi
        command -v python3 >/dev/null 2>&1 || {
            printf 'echo -markup {Error}live server: falta python3\n'
            exit 0
        }

        pidfile="${TMPDIR:-/tmp}/kak-web-server.pid"
        if [ -f "$pidfile" ]; then
            oldpid=$(cat "$pidfile" 2>/dev/null)
            [ -n "$oldpid" ] && kill "$oldpid" 2>/dev/null
            rm -f "$pidfile"
        fi

        python3 "$script" --root "$root" --port "$kak_opt_web_server_port" --open index.html \
            >"${TMPDIR:-/tmp}/kak-web-server.log" 2>&1 &
        echo $! > "$pidfile"
        printf 'echo -markup {Information}live server: http://127.0.0.1:%s/ (root %s)\n' "$kak_opt_web_server_port" "$root"
    }
}

define-command -hidden web-server-stop -docstring 'web-server-stop: detiene el live server' %{
    evaluate-commands %sh{
        pidfile="${TMPDIR:-/tmp}/kak-web-server.pid"
        if [ -f "$pidfile" ]; then
            pid=$(cat "$pidfile" 2>/dev/null)
            [ -n "$pid" ] && kill "$pid" 2>/dev/null
            rm -f "$pidfile"
            printf 'echo -markup {Information}live server detenido\n'
        else
            printf 'echo -markup {Information}live server: no estaba corriendo\n'
        fi
    }
}

define-command web-server-toggle -docstring 'web-server-toggle: arranca/detiene el live server' %{
    evaluate-commands %sh{
        pidfile="${TMPDIR:-/tmp}/kak-web-server.pid"
        if [ -f "$pidfile" ]; then
            printf 'web-server-stop\n'
        else
            printf 'web-server-start\n'
        fi
    }
}

# -- markdown preview -------------------------------------------------------
define-command -hidden md-render -docstring 'md-render: renderiza el markdown actual a HTML' %{
    evaluate-commands %sh{
        src="$kak_buffile"
        case "$src" in
            *.md | *.markdown | *.mdown) ;;
            *) exit 0 ;;
        esac
        script="$kak_opt_web_scripts_dir/md_preview.py"
        if [ ! -f "$script" ]; then
            printf 'echo -markup {Error}falta %s (reinstalá el repo)\n' "$script"
            exit 0
        fi
        command -v python3 >/dev/null 2>&1 || {
            printf 'echo -markup {Error}markdown preview: falta python3\n'
            exit 0
        }
        dir="$kak_opt_web_preview_dir"
        mkdir -p "$dir"
        out="$dir/$(basename "${src%.*}").html"
        python3 "$script" --src "$src" --out "$out" --title "$(basename "$src")" >/dev/null 2>&1 || {
            printf 'echo -markup {Error}markdown preview: falló el render\n'
            exit 0
        }
        printf 'set-option global web_preview_file "%s"\n' "$out"
    }
}

define-command -hidden md-preview-start -params 0..1 -docstring 'md-preview-start: abre el preview de markdown con autoreload' %{
    evaluate-commands %sh{
        src="$kak_buffile"
        case "$src" in
            *.md | *.markdown | *.mdown) ;;
            *)
                printf 'echo -markup {Error}markdown preview: este buffer no es markdown\n'
                exit 0
                ;;
        esac
        dir="$kak_opt_web_preview_dir"
        mkdir -p "$dir"
        name="$(basename "${src%.*}").html"

        script="$kak_opt_web_scripts_dir/live_server.py"
        if [ ! -f "$script" ]; then
            printf 'echo -markup {Error}falta %s (reinstalá el repo)\n' "$script"
            exit 0
        fi
        command -v python3 >/dev/null 2>&1 || {
            printf 'echo -markup {Error}markdown preview: falta python3\n'
            exit 0
        }

        pidfile="${TMPDIR:-/tmp}/kak-md-preview.pid"
        if [ -f "$pidfile" ]; then
            oldpid=$(cat "$pidfile" 2>/dev/null)
            [ -n "$oldpid" ] && kill "$oldpid" 2>/dev/null
            rm -f "$pidfile"
        fi

        python3 "$script" --root "$dir" --port "$kak_opt_web_preview_port" --open "$name" \
            >"${TMPDIR:-/tmp}/kak-md-preview.log" 2>&1 &
        echo $! > "$pidfile"
        printf 'echo -markup {Information}markdown preview: http://127.0.0.1:%s/%s\n' "$kak_opt_web_preview_port" "$name"
    }
}

define-command md-preview -docstring 'md-preview: markdown preview en el navegador (con autoreload)' %{
    md-render
    md-preview-start
}

define-command md-preview-stop -docstring 'md-preview-stop: detiene el preview de markdown' %{
    evaluate-commands %sh{
        pidfile="${TMPDIR:-/tmp}/kak-md-preview.pid"
        if [ -f "$pidfile" ]; then
            pid=$(cat "$pidfile" 2>/dev/null)
            [ -n "$pid" ] && kill "$pid" 2>/dev/null
            rm -f "$pidfile"
            printf 'echo -markup {Information}markdown preview detenido\n'
        fi
    }
}

# re-render al guardar: el live server detecta el cambio y recarga el browser
hook global BufWritePost .* %{ try %{ md-render } catch %{ nop } }

# render al abrir un markdown
hook global WinSetOption filetype=markdown %{
    try %{ md-render } catch %{ nop }
}
