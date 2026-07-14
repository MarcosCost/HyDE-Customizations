#  Startup 
# Commands to execute on startup (before the prompt is shown)
# Check if the interactive shell option is set
if [[ $- == *i* ]]; then
    if command -v pokego >/dev/null; then
        pokego --no-title -r 1,3,6
    elif command -v pokemon-colorscripts >/dev/null; then
        pokemon-colorscripts --no-title -r 1,3,6
    elif command -v fastfetch >/dev/null; then
        if do_render "image" 2>/dev/null; then
            term_cols=$(tput cols)
            term_lines=$(tput lines)

            if [ "$term_cols" -lt 45 ] || [ "$term_lines" -lt 15 ]; then
                return
            fi

            LOGO_PATH=$(find "$HOME/.config/fastfetch/logo" -maxdepth 1 -type f -name "*.png" 2>/dev/null | shuf -n 1)

            if [ -n "$LOGO_PATH" ]; then
                # Reserve 58 columns for text (just enough to fix the wrap)
                img_width=$(( term_cols - 62 ))

                if [ "$img_width" -gt 35 ]; then
                    img_width=35
                fi

                # Lower floor to 8 so it still renders in smaller splits
                if [ "$img_width" -lt 8 ]; then
                    fastfetch --logo-type none
                    return
                fi

                fastfetch --logo-type kitty --logo "$LOGO_PATH" --logo-width "$img_width"
            else
                fastfetch --logo-type none
            fi
        else
            fastfetch --logo-type none
        fi
    fi
fi

#   Overrides 
# HYDE_ZSH_NO_PLUGINS=1 # Set to 1 to disable loading of oh-my-zsh plugins, useful if you want to use your zsh plugins system
# HYDE_ZSH_COMPINIT_CHECK=1 # Set 24 (hours) per compinit security check // lessens startup time
# HYDE_ZSH_OMZ_DEFER=1 # Set to 1 to defer loading of oh-my-zsh plugins ONLY if prompt is already loaded

if [[ ${HYDE_ZSH_NO_PLUGINS} != "1" ]]; then
    #  OMZ Plugins 
    # manually add your oh-my-zsh plugins here
    plugins=(
        "sudo"
        "docker"
    )
fi

unset HYDE_ZSH_PROMPT # Uncomment to unset/disable loading of prompts from HyDE and let you load your own prompts
ZSH_THEME="bira"
