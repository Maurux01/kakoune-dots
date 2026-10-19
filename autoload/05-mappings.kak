# 05-mappings.kak — leader <espacio>, buffers, fzf, git
# Destino: ~/.config/kak/autoload/05-mappings.kak

# leader ya es <espacio> por defecto en user-mode; atajos directos:
map global normal <space>w ': write<ret>'                 -docstring 'guardar'
map global normal <space>q ': quit<ret>'                   -docstring 'salir'
map global normal <space>Q ': quit!<ret>'                  -docstring 'salir sin guardar'
map global normal <space>e ': edit '                       -docstring 'abrir archivo…'
map global normal <space>b ': buffer '                     -docstring 'ir a buffer…'
map global normal <space>f ': lsp-formatting-sync<ret>'   -docstring 'formatear'
map global normal <space>c ': comment-line<ret>'          -docstring 'comentar línea'

# buffers siguiente/anterior (también con tab / shift-tab)
map global normal <tab>   ': buffer-next<ret>' -docstring 'buffer siguiente'
map global normal <s-tab> ': buffer-previous<ret>' -docstring 'buffer anterior'
map global normal <space>1 ': buffer *debug*<ret>' -docstring 'buffer debug'
map global normal <space>k ': delete-buffer<ret>' -docstring 'cerrar buffer'
map global normal <space>K ': delete-buffer!<ret>' -docstring 'cerrar buffer!'

# fzf rápido
map global normal <space>p ': fzf-mode<ret>'      -docstring 'fzf'
map global normal <space>P ': fzf-file<ret>'      -docstring 'fzf archivo'
map global normal <space>g ': fzf-grep<ret>'      -docstring 'fzf grep'
map global normal <space>B ': fzf-buffer<ret>'    -docstring 'fzf buffer'

# búsqueda / grep con ripgrep (usa tmux popup si hay TMUX vía terminal)
map global normal <space>/ ': grep ' -docstring 'grep…'
map global normal <space>* ': grep <c-r>.<ret>' -docstring 'grep palabra bajo cursor'

# git
map global normal <space>G ': tmux-popup lazygit<ret>' -docstring 'lazygit'
map global normal <space>D ': git diff %val{buffile}<ret>' -docstring 'git diff archivo'

# live server / preview web
map global normal <space>s ': web-server-toggle<ret>' -docstring 'live server (on/off)'
map global normal <space>S ': web-server-stop<ret>'     -docstring 'live server: parar'
map global normal <space>v ': md-preview<ret>'          -docstring 'markdown preview'
map global normal <space>V ': md-preview-stop<ret>'     -docstring 'markdown preview: parar'
map global normal <space>u ': powerline-toggle-safe<ret>'  -docstring 'powerline on/off'
map global normal <space>h ': web-server-start<ret>'    -docstring 'live server: arrancar'

# terminal rápida (respeta tmux: ver 04-tmux.kak)
map global normal <space>z ': tmux-vsplit<ret>'   -docstring 'terminal split v'
map global normal <space>Z ': tmux-hsplit<ret>'   -docstring 'terminal split h'

# indentar con < / > en visual manteniendo selección
map global normal <a-,> '<a-;>: comment-line<ret>' -docstring 'comentar'

# escapar con jk (además de <esc>)
map global insert jk '<esc>' -docstring 'esc'
map global insert kj '<esc>' -docstring 'esc'

# moverse por líneas visuales cuando hay wrap
map global normal j 'gj'
map global normal k 'gk'
map global normal <a-j> 'j'
map global normal <a-k> 'k'

# seleccionar todo
map global normal <c-a> '%'
