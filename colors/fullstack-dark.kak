# colors/fullstack-dark.kak — tema oscuro fullstack, legible en tmux truecolor
# Destino: ~/.config/kak/colors/fullstack-dark.kak
# Paleta: fondo #1e1e2e (catppuccin-mocha like), acentos para LSP/diff/grep

evaluate-commands %sh{
cat <<'EOF'
face global value         rgb:cdd6f4
face global type          rgb:89b4fa
face global variable      rgb:cdd6f4
face global module        rgb:89dceb
face global function      rgb:89b4fa
face global string        rgb:a6e3a1
face global keyword       rgb:cba6f7
face global operator      rgb:89dceb
face global attribute     rgb:f9e2af
face global comment       rgb:6c7086+i
face global documentation rgb:6c7086+i
face global meta          rgb:f9e2af
face global builtin       rgb:fab387+b

face global title         rgb:cdd6f4+b
face global header        rgb:89dceb+b
face global mono          rgb:a6e3a1
face global block         rgb:89b4fa
face global link          rgb:89dceb+u
face global bullet        rgb:f9e2af
face global list          rgb:cdd6f4

face global Default            rgb:cdd6f4,rgb:1e1e2e
face global PrimarySelection   rgb:1e1e2e,rgb:89b4fa+g
face global SecondarySelection rgb:1e1e2e,rgb:585b70+g
face global PrimaryCursor      rgb:1e1e2e,rgb:f5e0dc+fg
face global SecondaryCursor    rgb:1e1e2e,rgb:bac2de+fg
face global PrimaryCursorEol   rgb:1e1e2e,rgb:f5e0dc+fg
face global SecondaryCursorEol rgb:1e1e2e,rgb:bac2de+fg

face global LineNumbers              rgb:585b70,rgb:1e1e2e
face global LineNumberCursor         rgb:f9e2af,rgb:313244+b
face global LineNumbersWrapped       rgb:313244,rgb:1e1e2e+i
face global MenuForeground           rgb:1e1e2e,rgb:89b4fa+b
face global MenuBackground           rgb:cdd6f4,rgb:313244
face global MenuInfo                 rgb:89dceb,rgb:313244
face global Information              rgb:cdd6f4,rgb:313244
face global Error                    rgb:f38ba8,rgb:1e1e2e+b
face global StatusLine               rgb:cdd6f4,rgb:313244
face global StatusLineMode           rgb:1e1e2e,rgb:cba6f7+b
face global StatusLineInfo           rgb:89dceb,rgb:313244
face global StatusLineValue          rgb:a6e3a1,rgb:313244
face global StatusCursor             rgb:1e1e2e,rgb:cdd6f4
face global Prompt                   rgb:f9e2af,rgb:1e1e2e+b
face global MatchingChar             rgb:f9e2af,rgb:45475a+b
face global Whitespace               rgb:45475a,rgb:1e1e2e+f
face global WrapMarker               rgb:45475a,rgb:1e1e2e+f
face global BufferPadding            rgb:313244,rgb:1e1e2e+f

# diff / git
face global DiffPlus  rgb:a6e3a1,rgb:1e1e2e
face global DiffMinus rgb:f38ba8,rgb:1e1e2e
face global DiffDelta rgb:f9e2af,rgb:1e1e2e

# diagnósticos LSP
face global DiagnosticError rgb:f38ba8+b
face global DiagnosticWarning rgb:f9e2af+b
face global DiagnosticInfo rgb:89dceb
face global DiagnosticHint rgb:6c7086+i
face global InlayHint rgb:6c7086,rgb:313244+i

# referencias LSP / búsqueda
face global Reference rgb:1e1e2e,rgb:f9e2af+g
face global Search rgb:1e1e2e,rgb:f9e2af+g
EOF
}
