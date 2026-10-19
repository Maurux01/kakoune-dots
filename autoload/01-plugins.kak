# 01-plugins.kak — plug.kak + plugins fullstack
# Destino: ~/.config/kak/autoload/01-plugins.kak

plug "andreyorst/plug.kak" noload

# fzf: archivos, buffers, grep (con soporte tmux popup, ver 04-tmux.kak)
plug "andreyorst/fzf.kak" config %{
    map global normal <c-p> ': fzf-mode<ret>'
    # si estamos en tmux, fzf-kak usa tmux popup automáticamente si fzf_tmux_popup=true
    set-option global fzf_preview true
    set-option global fzf_preview_width '60%'
    set-option global fzf_project_use_tops true
    set-option global fzf_highlight_command 'bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null || cat {}'
} defer fzf %{
    set-option global fzf_implementation "tmux"
} demand fzf "load"

# kak-lsp (se configura en 02-lsp.kak, aquí solo se declara)
plug "kakoune-lsp/kakoune-lsp" do %{
    cargo install --locked --force --path . --root ~/.local 2>/dev/null || true
} demand kak-lsp

# pares automáticos
plug "alexherbo2/auto-pairs.kak" config %{
    enable-auto-pairs
}

# surround (ys, ds, cs estilo vim-surround)
plug "alexherbo2/surround.kak" config %{
    declare-user-mode surround
    map global user s ': enter-user-mode surround<ret>' -docstring 'surround mode'
    map global surround s ': surround-selections<ret>' -docstring 'surround selections'
    map global surround d ': delete-surrounding<ret>' -docstring 'delete surrounding'
    map global surround c ': change-surrounding<ret>' -docstring 'change surrounding'
    map global surround t ': select-surrounding<ret>' -docstring 'select surrounding'
}

# buffers: navegación rápida tipo harpoon/bufferline
plug "Delapouite/kakoune-buffers" config %{
    map global normal ^ ': enter-buffers-mode<ret>' -docstring 'buffers mode'
    map global normal <a-^> ': enter-user-mode buffers<ret>' -docstring 'buffers (user)'
    hook global WinDisplay .* info-buffers
}

# texto / objetos extra: verbos, camelCase, etc.
plug "Delapouite/kakoune-text-objects" demand text-objects

# git: blame, diff, status en tmux popup
plug "olegdufour/kakoune-lazygit" config %{
    map global user g ': lazygit<ret>' -docstring 'lazygit (tmux popup)'
} demand lazygit

# sudo-write cuando el archivo no es escribible
plug "occivink/kakoune-sudo-write" demand sudo-write

# vertical selection / multicursor helpers
plug "occivink/kakoune-vertical-selection" demand vertical-selection

# snippets (fullstack: js/ts/py/go/rust/html…)
plug "occivink/kakoune-snippets" config %{
    set-option global snippets_auto_expand tab
    map global insert <tab> '<a-;>: try snippets-expand-or-jump "execute-keys -with-hooks <lt>tab>"<ret>' -docstring 'expand snippet / tab'
    map global normal <tab> ': snippets-expand-or-jump<ret>' -docstring 'expand snippet'
}

# filetree (ranger-style) que abre en tmux split si hay TMUX
plug "andreyorst/kakoune-filetree" defer filetree %{
    set-option global filetree_show_hidden true
} demand filetree %{ map global normal <c-n> ': filetree<ret>' }

# smarttab: tab = indent / align según contexto
plug "andreyorst/smarttab.kak" defer smarttab %{
    set-option global softtabstop 4
} demand smarttab

# ── powerline: modeline linda con tema gruvbox ──────────────────────────────
# Nota: el módulo `lsp` de powerline declara `int lsp_diagnostic_error_count`
# y `int lsp_diagnostic_warning_count`, igual que kak-lsp → mismo tipo, sin
# conflicto. No hace falta redeclararlas.
define-command powerline-setup -docstring 'powerline-setup: activa la modeline powerline con tema gruvbox' %{
    try %{
        # módulo principal: al cargarse dispara los hooks ModuleLoaded que
        # cargan los submódulos (bufname, git, lsp, …) y el tema
        require-module powerline

        # el tema debe ir DESPUÉS del módulo principal: al declararse los
        # colores, el valor por defecto del módulo principal los pisaría
        try %{ require-module powerline_gruvbox } catch %{ nop }

        # activar
        powerline-start

        # tema gruvbox (rc/themes/gruvbox.kak del propio plugin)
        powerline-theme gruvbox

        # orden de los módulos de la modeline
        powerline-format global 'git bufname filetype mode_info line_column position lsp'

        # separador: triangle (Nerd Font). Para ASCII: ascii-triangle
        powerline-separator global triangle

        # nombre de archivo corto
        set-option global powerline_shorten_bufname short

        # aplicar a los buffers ya abiertos
        powerline-enable
    } catch %{
        echo -debug "powerline: plugin no instalado todavía (corré :plug-install)"
    }
}

plug "andreyorst/powerline.kak" config %{
    powerline-setup
}

define-command powerline-toggle-safe -docstring 'powerline-toggle-safe: activa/desactiva la powerline' %{
    try %{ powerline-toggle } catch %{ nop }
}

# ── render markdown dentro del editor (encabezados, código, listas…) ───────
plug "kmafeni04/render-markdown.kak" demand render-markdown

hook global WinSetOption filetype=markdown %{
    try %{
        require-module render-markdown
        render-markdown-enable
    } catch %{ nop }
}

# ── markdown preview en el navegador (alternativa a md-preview, requiere
#    `npm install -g livedown`) ──────────────────────────────────────────────
plug "Delapouite/kakoune-livedown" config %{
    map global normal <space>o ': livedown-start-with-write-on-idle<ret>' -docstring 'markdown preview (livedown)'
}
