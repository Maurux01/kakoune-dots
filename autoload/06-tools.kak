# 06-tools.kak — grep, make, git, filetree, modeline
# Destino: ~/.config/kak/autoload/06-tools.kak

# ── grep con ripgrep ─────────────────────────────────────────────────────────
set-option global grepcmd 'rg --column --with-filename'
hook global BufOpenFile .* %{ evaluate-commands %sh{
    if [ -d .git ] || git rev-parse --git-dir >/dev/null 2>&1; then
        printf 'set-option buffer grepcmd "rg --column --with-filename"\n'
    fi
}}

# ── make / build según proyecto fullstack ────────────────────────────────────
hook global BufOpenFile .* %{ evaluate-commands %sh{
    if [ -f package.json ]; then
        printf 'set-option buffer makecmd "npm run --silent"\n'
    elif [ -f Cargo.toml ]; then
        printf 'set-option buffer makecmd "cargo"\n'
    elif [ -f go.mod ]; then
        printf 'set-option buffer makecmd "go"\n'
    elif [ -f Makefile ] || [ -f makefile ]; then
        printf 'set-option buffer makecmd "make -j"\n'
    fi
}}
map global normal <space>m ': make ' -docstring 'make…'
map global normal <space>M ': make-next-error<ret>' -docstring 'siguiente error make'

# ── git gutter / diff auto ───────────────────────────────────────────────────
hook global WinCreate .* %{ evaluate-commands %sh{
    if git rev-parse --git-dir >/dev/null 2>&1; then
        printf 'git show-diff\n'
    fi
}}
hook global BufWritePost .* %{ evaluate-commands %sh{
    if git rev-parse --git-dir >/dev/null 2>&1; then
        printf 'git update-diff\n'
    fi
}}

# ── filetree en split tmux si aplica ─────────────────────────────────────────
hook global ModuleLoaded filetree %{
    map global normal <space>n ': filetree<ret>' -docstring 'filetree'
}

# ── modeline progess + git branch ────────────────────────────────────────────
evaluate-commands %sh{
    if git --version >/dev/null 2>&1; then
        printf 'hook global WinDisplay .* %%{ try %%{ git show-diff } }\n'
    fi
}

# ── auto-guardado de sesión opcional ──────────────────────────────────────────
# :mksession para persistir; no auto para no ensuciar /tmp
define-command mksession -docstring 'guarda sesión en .kak-session' %{
    evaluate-commands %sh{
        printf 'echo -debug "sesión: %s"\n' "$kak_session"
    }
}
