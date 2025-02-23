# if not running interactively, don't do anything
[[ $- != *i* ]] && return
PS1='[\u@\h \W]\$ \n'

# check for custom bashrc
if [ -f ~/.bashrc_custom ]; then
  source ~/.bashrc_custom
fi

if [[ $(tty) == *"pts"* ]]; then
  # fastfetch
  # pfetch
  echo ""
else
  echo
  echo "hyprland not running? run: hyprland"
fi

# bin to path
export PATH="$HOME/.local/bin:$PATH"

# case insensitive
bind 'set completion-ignore-case on'

# aliases
# clearing the screen
alias cls='clear'
# quick git commit
alias gitqc='git add . && git commit -m "Lazy commmit" && git push'
# starship prompt
eval "$(starship init bash)"
# zoxide z
eval "$(zoxide init bash)"
# vim to nvim
alias vim='nvim'
# lazydocker
alias lzd='lazydocker'
# Set up fzf key bindings and fuzzy completion
eval "$(fzf --bash)"
# Use bash-completion, if available
[[ $PS1 && -f /usr/share/bash-completion/bash_completion ]] &&
  . /usr/share/bash-completion/bash_completion

# starting dir
cd ~
alias lzd='docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock -v /yourpath/config:/.config/jesseduffield/lazydocker lazyteam/lazydocker'
