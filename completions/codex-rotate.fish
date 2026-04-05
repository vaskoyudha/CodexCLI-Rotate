function __codex_rotate_aliases
    set -l cred_dir "$HOME/.codex-accounts/credentials"
    if test -d "$cred_dir"
        for f in $cred_dir/*.json
            if test -f "$f"
                string replace -r '.*/(.*)\.json$' '$1' -- "$f"
            end
        end
    end
end

complete -c codex-rotate -f

complete -c codex-rotate -n "not __fish_seen_subcommand_from init add import remove list switch status run auto cooldown uncooldown quota email refresh doctor upgrade tui help" -a "init" -d "Initialize structure"
complete -c codex-rotate -n "not __fish_seen_subcommand_from init add import remove list switch status run auto cooldown uncooldown quota email refresh doctor upgrade tui help" -a "add" -d "Add account"
complete -c codex-rotate -n "not __fish_seen_subcommand_from init add import remove list switch status run auto cooldown uncooldown quota email refresh doctor upgrade tui help" -a "import" -d "Import auth.json"
complete -c codex-rotate -n "not __fish_seen_subcommand_from init add import remove list switch status run auto cooldown uncooldown quota email refresh doctor upgrade tui help" -a "remove" -d "Remove account"
complete -c codex-rotate -n "not __fish_seen_subcommand_from init add import remove list switch status run auto cooldown uncooldown quota email refresh doctor upgrade tui help" -a "list" -d "List accounts"
complete -c codex-rotate -n "not __fish_seen_subcommand_from init add import remove list switch status run auto cooldown uncooldown quota email refresh doctor upgrade tui help" -a "switch" -d "Switch account"
complete -c codex-rotate -n "not __fish_seen_subcommand_from init add import remove list switch status run auto cooldown uncooldown quota email refresh doctor upgrade tui help" -a "status" -d "Show dashboard"
complete -c codex-rotate -n "not __fish_seen_subcommand_from init add import remove list switch status run auto cooldown uncooldown quota email refresh doctor upgrade tui help" -a "run" -d "Run with rotation"
complete -c codex-rotate -n "not __fish_seen_subcommand_from init add import remove list switch status run auto cooldown uncooldown quota email refresh doctor upgrade tui help" -a "auto" -d "Auto rotation"
complete -c codex-rotate -n "not __fish_seen_subcommand_from init add import remove list switch status run auto cooldown uncooldown quota email refresh doctor upgrade tui help" -a "cooldown" -d "Set cooldown"
complete -c codex-rotate -n "not __fish_seen_subcommand_from init add import remove list switch status run auto cooldown uncooldown quota email refresh doctor upgrade tui help" -a "uncooldown" -d "Clear cooldown"
complete -c codex-rotate -n "not __fish_seen_subcommand_from init add import remove list switch status run auto cooldown uncooldown quota email refresh doctor upgrade tui help" -a "quota" -d "Show quota"
complete -c codex-rotate -n "not __fish_seen_subcommand_from init add import remove list switch status run auto cooldown uncooldown quota email refresh doctor upgrade tui help" -a "email" -d "Show email"
complete -c codex-rotate -n "not __fish_seen_subcommand_from init add import remove list switch status run auto cooldown uncooldown quota email refresh doctor upgrade tui help" -a "refresh" -d "Refresh tokens"
complete -c codex-rotate -n "not __fish_seen_subcommand_from init add import remove list switch status run auto cooldown uncooldown quota email refresh doctor upgrade tui help" -a "doctor" -d "System diagnostics"
complete -c codex-rotate -n "not __fish_seen_subcommand_from init add import remove list switch status run auto cooldown uncooldown quota email refresh doctor upgrade tui help" -a "upgrade" -d "Check updates"
complete -c codex-rotate -n "not __fish_seen_subcommand_from init add import remove list switch status run auto cooldown uncooldown quota email refresh doctor upgrade tui help" -a "tui" -d "Interactive menu"
complete -c codex-rotate -n "not __fish_seen_subcommand_from init add import remove list switch status run auto cooldown uncooldown quota email refresh doctor upgrade tui help" -a "help" -d "Show help"

complete -c codex-rotate -n "__fish_seen_subcommand_from remove switch cooldown uncooldown quota email" -a "(__codex_rotate_aliases)" -d "Account alias"
complete -c codex-rotate -n "__fish_seen_subcommand_from refresh" -a "(__codex_rotate_aliases)" -d "Account alias"
complete -c codex-rotate -n "__fish_seen_subcommand_from refresh" -l "all" -d "Refresh all accounts"

complete -c codex-rotate -n "__fish_seen_subcommand_from add switch" -l "force" -d "Force overwrite"
complete -c codex-rotate -n "__fish_seen_subcommand_from list status quota email" -l "json" -d "JSON output"
