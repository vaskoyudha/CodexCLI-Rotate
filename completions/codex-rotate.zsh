#compdef codex-rotate
# codex-rotate zsh completion

_codex_rotate_aliases() {
    local cred_dir="${HOME}/.codex-accounts/credentials"
    local aliases=()
    if [[ -d "${cred_dir}" ]]; then
        for f in "${cred_dir}"/*.json(N); do
            aliases+=(${f:t:r})
        done
    fi
    _describe 'account alias' aliases
}

_codex_rotate() {
    local -a commands
    commands=(
        'init:Initialize ~/.codex-accounts structure'
        'add:Add account via browser login'
        'import:Import existing auth.json'
        'remove:Remove an account'
        'list:List accounts'
        'switch:Switch active account'
        'status:Show dashboard'
        'run:Run with rate-limit rotation'
        'auto:Run with time + rate-limit rotation'
        'cooldown:Mark account as cooling down'
        'uncooldown:Clear cooldown'
        'quota:Show usage/quota'
        'email:Show email and plan'
        'refresh:Refresh access tokens'
        'doctor:Run system diagnostics'
        'upgrade:Check for updates'
        'tui:Interactive menu'
        'daemon:Background rate-limit monitor'
        'help:Show help'
    )

    _arguments -C \
        '1: :->command' \
        '*: :->args'

    case "${state}" in
        command)
            _describe 'command' commands
            ;;
        args)
            case "${words[2]}" in
                remove|switch|cooldown|uncooldown|quota|email)
                    _codex_rotate_aliases
                    ;;
                refresh)
                    _alternative \
                        'aliases:account:_codex_rotate_aliases' \
                        'flags:flag:(--all)'
                    ;;
                add|switch)
                    _arguments '--force[Force overwrite]'
                    ;;
                list|status|quota|email)
                    _arguments '--json[JSON output]'
                    ;;
                import)
                    _arguments \
                        '2:alias:' \
                        '3:auth file:_files -g "*.json"'
                    ;;
                daemon)
                    _alternative \
                        'subcommands:subcommand:(start stop status logs)'
                    ;;
            esac
            ;;
    esac
}

_codex_rotate "$@"
