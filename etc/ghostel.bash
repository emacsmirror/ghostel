# Ghostel shell integration for bash
# Source this from your .bashrc:
#   [[ "$INSIDE_EMACS" = 'ghostel' ]] && source /path/to/ghostel/etc/ghostel.bash

# Report working directory to the terminal via OSC 7
__ghostel_osc7() {
    printf '\e]7;file://%s%s\e\\' "$HOSTNAME" "$PWD"
}
PROMPT_COMMAND="__ghostel_osc7${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
