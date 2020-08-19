alias tm="tmux new -A -s main"
alias kc="kubectl"
alias copy="xclip -selection clipboard -i"
alias clip="xclip -selection clipboard -o"
setopt nosharehistory
#powerline-daemon -q
#. /usr/lib/python3.8/site-packages/powerline/bindings/zsh/powerline.zsh

export PATH=$PATH:/home/demoniac/.bin
export PATH=$PATH:/home/demoniac/.composer/vendor/bin
eval "$(symfony-autocomplete)"
[[ -e ~/.phpbrew/bashrc ]] && source ~/.phpbrew/bashrc
