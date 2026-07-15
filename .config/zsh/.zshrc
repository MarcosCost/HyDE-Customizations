# Add user configurations here
# For HyDE to not touch your beloved configurations,
# we added a config file for you to customize HyDE before loading zshrc
# Edit $ZDOTDIR/.user.zsh to customize HyDE before loading zshrc

#  Plugins 
# oh-my-zsh plugins are loaded  in $ZDOTDIR/.user.zsh file, see the file for more information

#  Aliases 
# Override aliases here in '$ZDOTDIR/.zshrc' (already set in .zshenv)

# # Helpful aliases
alias l='eza -lh --icons=auto'                                         # long list
alias ls='eza -1 --icons=auto'                                         # short list
alias ll='eza -lha --icons=auto --sort=name --group-directories-first' # long list all
alias ld='eza -lhD --icons=auto'                                       # long list dirs
alias lt='eza --icons=auto --tree'                                     # list folder as tree

# # Always mkdir a path (this doesn't inhibit functionality to make a single dir)
alias mkdir='mkdir -p'

# # Lite-lx has weird startup behaviour this fixes it
alias lite='(nohup lite-xl </dev/null &>/dev/null &)'


#  This is your file 
# Add your configurations here
export EDITOR=nvim

# Prevent searching for commands not found in package manager, swapping this for an not found result
unset -f command_not_found_handler

# Insane mathed out fastfetch
unalias fastfetch 2>/dev/null
fastfetch() {
    if do_render "image" 2>/dev/null; then
        local term_cols=$(tput cols)
        local term_lines=$(tput lines)

        if [ "$term_cols" -lt 45 ] || [ "$term_lines" -lt 15 ]; then
            return
        fi

        local LOGO_PATH=$(find "$HOME/.config/fastfetch/logo" -maxdepth 1 -type f -name "*.png" 2>/dev/null | shuf -n 1)

        if [ -n "$LOGO_PATH" ]; then
            local img_width=$(( term_cols - 62 ))

            if [ "$img_width" -gt 35 ]; then
                img_width=35
            fi
            if [ "$img_width" -lt 8 ]; then
                command fastfetch "$@" --logo-type none
                return
            fi

            command fastfetch "$@" --logo-type kitty --logo "$LOGO_PATH" --logo-width "$img_width"
        else
            command fastfetch "$@" --logo-type none
        fi
    else
        command fastfetch "$@" --logo-type none
    fi
}

# Custom Scripts Path
export PATH="$HOME/.local/bin/custom_scripts:$PATH"

# Normalize PATH: dedupe and remove empty entries
typeset -U path
path=("${(@)path:#}")
export PATH
