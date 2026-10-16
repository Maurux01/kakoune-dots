# 00-options.kak — opciones base, UI, edición
# Destino: ~/.config/kak/autoload/00-options.kak

# ── UI ───────────────────────────────────────────────────────────────────────
set-option global scrolloff 5,5
set-option global tabstop 4
set-option global indentwidth 4
set-option global eolformat lf
set-option global BOM none
set-option global ui_options terminal_set_title=true terminal_title="kak: %val{buffile}" terminal_assistant=none
set-option global modelinefmt '%val{bufname} %val{cursor_line}:%val{cursor_char} {{context_info}} {{mode_info}} - %val{client}@[%val{session}]'

add-highlighter global/ number-lines -relative -hlcursor -separator " │ "
add-highlighter global/ show-matching
add-highlighter global/ show-whitespaces -tab "→" -spc "·" -lf "¬" -only-trailing
add-highlighter global/ wrap -word -indent -marker "↪"

# ── edición ──────────────────────────────────────────────────────────────────
set-option global autoreload yes
set-option global incremental_search true
set-option global autocomplete prompt
set-option global complete_prefix true
set-option global ignored_files '\.(o|bin|obj|class|pyc|__pycache__|node_modules|\.git|\.hg|\.svn|target|dist|build|coverage)'
set-option global file_completion_ignore_case true

# clipboard del sistema: wayland (wl-copy) > x11 (xclip/xsel) > tmux buffer
hook global NormalKey y|d|c %{ nop %sh{
    if [ -n "$WAYLAND_DISPLAY" ] && command -v wl-copy >/dev/null 2>&1; then
        printf '%s' "$kak_reg_dquote" | wl-copy -n >/dev/null 2>&1 &
    elif [ -n "$DISPLAY" ] && command -v xclip >/dev/null 2>&1; then
        printf '%s' "$kak_reg_dquote" | xclip -selection clipboard >/dev/null 2>&1 &
    elif [ -n "$TMUX" ]; then
        printf '%s' "$kak_reg_dquote" | tmux load-buffer - >/dev/null 2>&1 &
    fi
}}

# pegar desde sistema con <c-p> en insert (si hay proveedor)
hook global InsertChar .* %{ try %{
    evaluate-commands %sh{
        if [ -n "$WAYLAND_DISPLAY" ] && command -v wl-paste >/dev/null 2>&1; then
            printf 'set-option window _syspaste %%{%s}\n' "$(wl-paste -n 2>/dev/null | head -c 4096)"
        fi
    }
}}

# ── ayuda / docs ─────────────────────────────────────────────────────────────
set-option global startup_info_version 20241201
