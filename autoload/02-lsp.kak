# 02-lsp.kak — kak-lsp fullstack
# Destino: ~/.config/kak/autoload/02-lsp.kak
# Servidores: ver kak-lsp/kak-lsp.toml -> ~/.config/kak-lsp/kak-lsp.toml
# Instalador.sh instala los language servers según distro.

evaluate-commands %sh{ kak-lsp --kakoune -s "$kak_session" 2>/dev/null || true }

hook global WinSetOption filetype=(javascript|typescript|tsx|jsx|json|html|css|scss|vue|svelte|python|rust|go|lua|bash|sh|yaml|toml|dockerfile|sql|markdown|c|cpp|java|php) %{
    lsp-enable-window
    lsp-auto-hover-enable
    lsp-auto-hover-insert-mode-disable
    set-option window lsp_hover_anchor true
    # firmas en modeline
    lsp-signature-help-enable window
    # resaltado de símbolos / referencias
    lsp-highlight-references-enable window
    # formato al guardar si el servidor lo soporta (fullstack)
    hook window BufWritePre .* lsp-formatting-sync 2>/dev/null
    # inlay hints donde haya soporte
    try %{ lsp-inlay-hints-enable window } catch %{ nop }
}

# inactivo por defecto fuera de esos filetypes
hook global WinSetOption filetype=(text|plain) %{
    nop
}

# ── atajos LSP bajo <espacio>l ───────────────────────────────────────────────
declare-user-mode lsp
map global user l ': enter-user-mode lsp<ret>' -docstring 'LSP mode'

map global lsp d ': lsp-definition<ret>'            -docstring 'go to definition'
map global lsp r ': lsp-references<ret>'             -docstring 'references'
map global lsp i ': lsp-implementation<ret>'        -docstring 'implementation'
map global lsp t ': lsp-type-definition<ret>'       -docstring 'type definition'
map global lsp h ': lsp-hover<ret>'                  -docstring 'hover'
map global lsp s ': lsp-signature-help<ret>'        -docstring 'signature help'
map global lsp n ': lsp-rename-prompt<ret>'         -docstring 'rename'
map global lsp a ': lsp-code-actions<ret>'          -docstring 'code actions'
map global lsp f ': lsp-formatting-sync<ret>'       -docstring 'format'
map global lsp e ': lsp-diagnostics<ret>'           -docstring 'diagnostics'
map global lsp j ': lsp-find-error --include-warnings<ret>' -docstring 'next error'
map global lsp k ': lsp-find-error --previous --include-warnings<ret>' -docstring 'prev error'
map global lsp o ': lsp-document-symbol<ret>'      -docstring 'document symbols'
map global lsp p ': lsp-workspace-symbol-incr<ret>' -docstring 'workspace symbols'

# goto con gd clásico
map global normal gd ': lsp-definition<ret>' -docstring 'lsp definition'
map global normal gr ': lsp-references<ret>'  -docstring 'lsp references'
map global normal K  ': lsp-hover<ret>'        -docstring 'lsp hover'

# diagnósticos en modeline
set-option global lsp_modeline_code_actions_enable true
set-option global lsp_modeline_message_method 'modeline'
