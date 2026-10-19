# colors/gruvbox.kak — tema Gruvbox dark (medium) para Kakoune
# Destino: ~/.config/kak/colors/gruvbox.kak
# Paleta base16-gruvbox-dark-medium, compatible con el tema gruvbox de
# powerline.kak (fondo rgb:282828).

evaluate-commands %sh{
cat <<'EOF'
# ── sintaxis ────────────────────────────────────────────────────────────────
face global value         rgb:83a598
face global type          rgb:fabd2f
face global variable      rgb:ebdbb2
face global module        rgb:8ec07c
face global function      rgb:8ec07c
face global string        rgb:b8bb26
face global keyword       rgb:fb4934
face global operator      rgb:fe8019
face global attribute     rgb:d3869b
face global comment       rgb:928374+i
face global documentation rgb:928374+i
face global meta          rgb:928374
face global builtin       rgb:fe8019+b

# ── markdown / texto ────────────────────────────────────────────────────────
face global title         rgb:fabd2f+b
face global header        rgb:83a598+b
face global mono          rgb:8ec07c
face global block         rgb:83a598
face global link          rgb:83a598+u
face global bullet        rgb:fe8019
face global list          rgb:ebdbb2

# ── UI ──────────────────────────────────────────────────────────────────────
face global Default            rgb:ebdbb2,rgb:282828
face global PrimarySelection   rgb:282828,rgb:83a598+g
face global SecondarySelection rgb:282828,rgb:504945+g
face global PrimaryCursor      rgb:282828,rgb:fbf1c7+fg
face global SecondaryCursor    rgb:282828,rgb:d5c4a1+fg
face global PrimaryCursorEol   rgb:282828,rgb:fbf1c7+fg
face global SecondaryCursorEol rgb:282828,rgb:d5c4a1+fg

face global LineNumbers              rgb:7c6f64,rgb:282828
face global LineNumberCursor         rgb:fabd2f,rgb:3c3836+b
face global LineNumbersWrapped       rgb:504945,rgb:282828+i
face global MenuForeground           rgb:282828,rgb:83a598+b
face global MenuBackground           rgb:ebdbb2,rgb:3c3836
face global MenuInfo                 rgb:8ec07c,rgb:3c3836
face global Information              rgb:ebdbb2,rgb:3c3836
face global Error                    rgb:fb4934,rgb:282828+b
face global StatusLine               rgb:ebdbb2,rgb:3c3836
face global StatusLineMode           rgb:282828,rgb:fabd2f+b
face global StatusLineInfo           rgb:8ec07c,rgb:3c3836
face global StatusLineValue          rgb:b8bb26,rgb:3c3836
face global StatusCursor             rgb:282828,rgb:ebdbb2
face global Prompt                   rgb:fabd2f,rgb:282828+b
face global MatchingChar             rgb:fabd2f,rgb:504945+b
face global Whitespace               rgb:504945,rgb:282828+f
face global WrapMarker               rgb:504945,rgb:282828+f
face global BufferPadding            rgb:3c3836,rgb:282828+f

# ── diff / git ──────────────────────────────────────────────────────────────
face global DiffPlus  rgb:b8bb26,rgb:282828
face global DiffMinus rgb:fb4934,rgb:282828
face global DiffDelta rgb:fabd2f,rgb:282828

# ── diagnósticos LSP ────────────────────────────────────────────────────────
face global DiagnosticError   rgb:fb4934+b
face global DiagnosticWarning rgb:fabd2f+b
face global DiagnosticInfo    rgb:83a598
face global DiagnosticHint    rgb:928374+i
face global InlayHint         rgb:7c6f64,rgb:3c3836+i

# ── referencias / búsqueda ──────────────────────────────────────────────────
face global Reference rgb:282828,rgb:fabd2f+g
face global Search    rgb:282828,rgb:fe8019+g
EOF
}
