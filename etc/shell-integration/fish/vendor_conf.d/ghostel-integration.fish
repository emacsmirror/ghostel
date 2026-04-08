# Ghostel shell integration auto-injection for fish.
# Auto-loaded via XDG_DATA_DIRS.

# Restore XDG_DATA_DIRS by removing our injected path.
if set -q GHOSTEL_SHELL_INTEGRATION_XDG_DIR
    if set -q XDG_DATA_DIRS
        set --function --path xdg_data_dirs "$XDG_DATA_DIRS"
        if set --function index (contains --index "$GHOSTEL_SHELL_INTEGRATION_XDG_DIR" $xdg_data_dirs)
            set --erase --function xdg_data_dirs[$index]
        end
        if set -q xdg_data_dirs[1]
            set --global --export --unpath XDG_DATA_DIRS "$xdg_data_dirs"
        else
            set --erase --global XDG_DATA_DIRS
        end
    end
    set --erase GHOSTEL_SHELL_INTEGRATION_XDG_DIR
end

status --is-interactive; or exit 0

# Report working directory to the terminal via OSC 7
function __ghostel_osc7 --on-event fish_prompt
    printf '\e]7;file://%s%s\e\\' (hostname) "$PWD"
end

# --- Semantic prompt markers (OSC 133) ---

set -g __ghostel_prompt_shown 0

function __ghostel_postexec --on-event fish_postexec
    set -g __ghostel_last_status $status
end

# Emit "command finished" (D) + "prompt start" (A) before the prompt.
function __ghostel_prompt_start --on-event fish_prompt
    if test "$__ghostel_prompt_shown" = 1
        printf '\e]133;D;%s\e\\' "$__ghostel_last_status"
    end
    printf '\e]133;A\e\\'
end

# Emit "prompt end / command start" (B) after the prompt.
function __ghostel_prompt_end --on-event fish_prompt
    printf '\e]133;B\e\\'
    set -g __ghostel_prompt_shown 1
end

# Emit "command output start" (C) before command runs.
function __ghostel_preexec --on-event fish_preexec
    printf '\e]133;C\e\\'
end

# Call an Emacs Elisp function from the shell.
# Usage: ghostel_cmd FUNCTION [ARGS...]
# The function must be in `ghostel-eval-cmds'.
function ghostel_cmd
    set -l payload ""
    for arg in $argv
        set arg (string replace -a '\\' '\\\\' -- $arg)
        set arg (string replace -a '"' '\\"' -- $arg)
        set payload "$payload\"$arg\" "
    end
    printf '\e]51;E%s\e\\' "$payload"
end
