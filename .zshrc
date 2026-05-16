export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME=""

plugins=(
    git
    dnf
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# history
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# fzf (only if installed)
source <(fzf --zsh)

# clean ls aliases (optional, but fine)
alias ls='lsd'
alias l='ls -l'
alias la='ls -a'
alias ll='ls -la'
alias lt='ls --tree'


PROMPT='[%~] [$USER] %# '
