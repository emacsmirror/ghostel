# Ghostel shell integration for zsh
# Source this from your .zshrc:
#   [[ "$INSIDE_EMACS" = 'ghostel' ]] && source /path/to/ghostel/etc/ghostel.zsh

# Report working directory to the terminal via OSC 7
__ghostel_osc7() {
    printf '\e]7;file://%s%s\e\\' "$HOST" "$PWD"
}
precmd_functions+=(__ghostel_osc7)
