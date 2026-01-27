#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias config='/usr/bin/git --git-dir=$HOME/.config/ --work-tree=$HOME'
PS1='[\u@\h \W]\$ '

fastfetch
eval "$(starship init bash)"
eval "$(direnv hook bash)"
