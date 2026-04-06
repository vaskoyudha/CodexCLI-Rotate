_codex_rotate() {
    local cur words cword
    _init_completion || return

    local commands="init add import remove list switch status run auto cooldown uncooldown quota email refresh doctor upgrade tui daemon help"

    local alias_commands="remove switch cooldown uncooldown quota email refresh"

    if [[ ${cword} -eq 1 ]]; then
        mapfile -t COMPREPLY < <(compgen -W "${commands}" -- "${cur}")
        return
    fi

    local cmd="${words[1]}"

    local alias_pattern=""
    for ac in ${alias_commands}; do
        if [[ "${cmd}" == "${ac}" ]]; then
            alias_pattern=1
            break
        fi
    done

    if [[ -n "${alias_pattern}" ]]; then
        local aliases=""
        local cred_dir="${HOME}/.codex-accounts/credentials"
        if [[ -d "${cred_dir}" ]]; then
            for f in "${cred_dir}"/*.json; do
                [[ -f "${f}" ]] || continue
                local name
                name=$(basename "${f}" .json)
                aliases="${aliases} ${name}"
            done
        fi
        case "${cmd}" in
            refresh) aliases="${aliases} --all" ;;
        esac
        mapfile -t COMPREPLY < <(compgen -W "${aliases}" -- "${cur}")
        return
    fi

    case "${cmd}" in
        add|switch)
            mapfile -t COMPREPLY < <(compgen -W "--force" -- "${cur}")
            ;;
        list|status|quota|email)
            mapfile -t COMPREPLY < <(compgen -W "--json" -- "${cur}")
            ;;
        import)
            if [[ ${cword} -eq 3 ]]; then
                _filedir json
            fi
            ;;
        daemon)
            mapfile -t COMPREPLY < <(compgen -W "start stop status logs" -- "${cur}")
            ;;
    esac
}

complete -F _codex_rotate codex-rotate
