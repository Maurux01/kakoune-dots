# 03-languages.kak — hooks fullstack: indent, fmt, lint, repl
# Destino: ~/.config/kak/autoload/03-languages.kak

# ── helper: formateador externo por filetype ─────────────────────────────────
define-command -params 1..2 format-with -docstring 'format-with <cmd...> : formatea buffer con comando externo' %{
    evaluate-commands %sh{
        cmd="$*"
        tmp="$(mktemp)"
        cp "$kak_buffile" "$tmp" 2>/dev/null || cat "$kak_main_reg_dquote" > "$tmp"
        if printf '%s' "$kak_main_reg_dquote" | sh -c "$cmd" > "$tmp.out" 2>/dev/null; then
            printf 'execute-keys "%%|sh -c %%{%s}<ret>"\n' "$cmd"
        else
            printf 'echo -debug "format-with falló: %s"\n' "$cmd"
        fi
        rm -f "$tmp" "$tmp.out"
    }
}

# ── JavaScript / TypeScript / JSX / TSX / JSON / Vue / Svelte ────────────────
hook global WinSetOption filetype=(javascript|typescript|jsx|tsx|json|vue|svelte) %{
    set-option window tabstop 2
    set-option window indentwidth 2
    set-option window formatcmd 'prettier --stdin-filepath=%val{buffile}'
    # eslint fix al guardar si existe
    hook window BufWritePre .* %{ nop %sh{
        if command -v eslint >/dev/null 2>&1 && [ -f "$kak_buffile" ]; then
            eslint --fix "$kak_buffile" >/dev/null 2>&1 &
        fi
    }}
    map window normal <space>f ': lsp-formatting-sync<ret>' -docstring 'format (prettier/lsp)'
}

# ── HTML / CSS / SCSS / Tailwind ─────────────────────────────────────────────
hook global WinSetOption filetype=(html|css|scss|less) %{
    set-option window tabstop 2
    set-option window indentwidth 2
    set-option window formatcmd 'prettier --stdin-filepath=%val{buffile}'
}

# ── Python ───────────────────────────────────────────────────────────────────
hook global WinSetOption filetype=python %{
    set-option window tabstop 4
    set-option window indentwidth 4
    set-option window formatcmd 'ruff format --stdin-filename=%val{buffile} - 2>/dev/null || black -q - 2>/dev/null || cat'
    set-option window lintcmd 'ruff check --output-format=concise --stdin-filename=%val{buffile} - 2>/dev/null || flake8 --stdin-display-name=%val{buffile} -'
    map window normal <space>f ': lsp-formatting-sync<ret>' -docstring 'format python'
}

# ── Rust ─────────────────────────────────────────────────────────────────────
hook global WinSetOption filetype=rust %{
    set-option window formatcmd 'rustfmt --edition 2021'
    hook window BufWritePre .* %{ try %{ lsp-formatting-sync } }
}

# ── Go ───────────────────────────────────────────────────────────────────────
hook global WinSetOption filetype=go %{
    set-option window tabstop 4
    set-option window indentwidth 4
    hook window BufWritePre .* %{ try %{ lsp-formatting-sync } }
    # goimports si lsp no formateó
    set-option window formatcmd 'goimports 2>/dev/null || gofmt'
}

# ── Lua / Shell / YAML / TOML / Docker / SQL / Markdown ──────────────────────
hook global WinSetOption filetype=lua %{
    set-option window tabstop 2
    set-option window indentwidth 2
    set-option window formatcmd 'stylua - 2>/dev/null || cat'
}
hook global WinSetOption filetype=(sh|bash) %{
    set-option window tabstop 2
    set-option window indentwidth 2
    set-option window formatcmd 'shfmt -i 2 -ci -bn 2>/dev/null || cat'
    set-option window lintcmd 'shellcheck -f gcc -x -'
}
hook global WinSetOption filetype=(yaml|toml) %{
    set-option window tabstop 2
    set-option window indentwidth 2
}
hook global WinSetOption filetype=sql %{
    set-option window formatcmd 'sqlfluff fix --force - 2>/dev/null || pg_format - 2>/dev/null || cat'
}
hook global WinSetOption filetype=markdown %{
    set-option window tabstop 2
    set-option window indentwidth 2
    set-option window formatcmd 'prettier --parser markdown --stdin-filepath=%val{buffile}'
    add-highlighter window/ wrap -word -indent
}

# ── C / C++ / Java / PHP (extra fullstack) ───────────────────────────────────
hook global WinSetOption filetype=(c|cpp) %{
    set-option window formatcmd 'clang-format 2>/dev/null || cat'
}
hook global WinSetOption filetype=java %{
    set-option window formatcmd 'google-java-format - 2>/dev/null || cat'
}
hook global WinSetOption filetype=php %{
    set-option window formatcmd 'php-cs-fixer fix --using-cache=no --quiet 2>/dev/null; cat'
}

# ── lint global (si kak-lsp no cubre, usar lint.kak) ──────────────────────────
hook global WinSetOption filetype=(python|sh|bash) %{
    try %{ lint-enable-window } catch %{ nop }
}
