if [[ -n "$VIM" ]]; then
  # export TERM="rxvt-unicode-256color"
  export TERM="mlterm-256color"
fi

export TERMINFO=~/.terminfo

ulimit -c unlimited
stty -ixon -ixoff
stty intr "^K"

autoload -Uz add-zsh-hook

autoload -Uz zmv
alias zmv='noglob zmv -W'

plugins=()

eval $(dircolors ~/.dircolors)
zle_highlight=(region:bg=238 isearch:bg=065)

autoload zkbd
source ~/.zkbd/$TERM-:0.0 # may be different - check where zkbd saved yours

[[ -n ${key[Backspace]} ]] && bindkey "${key[Backspace]}" backward-delete-char
[[ -n ${key[Insert]} ]] && bindkey "${key[Insert]}" overwrite-mode
[[ -n ${key[Home]} ]] && bindkey "${key[Home]}" beginning-of-line
[[ -n ${key[PageUp]} ]] && bindkey "${key[PageUp]}" up-line-or-history
[[ -n ${key[Delete]} ]] && bindkey "${key[Delete]}" delete-char
[[ -n ${key[End]} ]] && bindkey "${key[End]}" end-of-line
[[ -n ${key[PageDown]} ]] && bindkey "${key[PageDown]}" down-line-or-history
[[ -n ${key[Up]} ]] && bindkey "${key[Up]}" up-line-or-search
[[ -n ${key[Left]} ]] && bindkey "${key[Left]}" backward-char
[[ -n ${key[Down]} ]] && bindkey "${key[Down]}" down-line-or-search
[[ -n ${key[Right]} ]] && bindkey "${key[Right]}" forward-char

bindkey -e

# undo/redo
bindkey "^Z" undo
bindkey "^Y" redo

# inserting new line by ctrl+enter (multi-line prompt)
bindkey "^J" self-insert
bindkey -s "^[\015" "^J"

# delete by word
# <C-Del>
bindkey "^[[3;5~" delete-word
bindkey "^[[3^" delete-word
# <C-BS>
bindkey "^H" backward-delete-word

# Move cursor up/down by display lines when wrapping
# http://chneukirchen.org/blog/archive/2015/02/10-fancy-zsh-tricks-you-may-not-know.html
up-line-by-display-or-history() {
  #echo -n "\033[1A"
  local dest=$((CURSOR - $COLUMNS))
  #tmux display-message "CURSOR is (${CURSOR})"
  if [[ dest -ge 0 ]]; then
    zle backward-char -n $COLUMNS
  else
    zle up-line-or-history
  fi
}
down-line-by-display-or-history() {
  local dest=$((CURSOR + $COLUMNS))
  if [[ $#BUFFER -ge dest ]]; then
    zle forward-char -n $COLUMNS
  else
    zle down-line-or-history
  fi
}
zle -N up-line-by-display-or-history
zle -N down-line-by-display-or-history

# text selection w/ shift+arrow
# originally code posted by Mr.Stephane Chazelas
# http://stackoverflow.com/questions/5407916/zsh-zle-shift-selection
# rewrited for zkbd by ayapi

# bindkey -r "^[[200~" bracketed-paste

shift-arrow() {
  ((REGION_ACTIVE)) || zle set-mark-command
  zle $1
}

shift-left() shift-arrow backward-char
shift-right() shift-arrow forward-char
shift-up() shift-arrow up-line-by-display-or-history
shift-down() shift-arrow down-line-by-display-or-history
shift-home() shift-arrow beginning-of-line
shift-end() shift-arrow end-of-line
shift-ctrl-left() shift-arrow backward-word
shift-ctrl-right() shift-arrow forward-word

zle -N shift-left
zle -N shift-right
zle -N shift-up
zle -N shift-down
zle -N shift-home
zle -N shift-end
zle -N shift-ctrl-left
zle -N shift-ctrl-right

bindkey "^[[1;2D" shift-left
bindkey "^[[1;2C" shift-right
bindkey "^[[1;2A" shift-up
bindkey "^[[1;2B" shift-down
bindkey "^[[1;2H" shift-home
bindkey "^[[1;2F" shift-end
bindkey "^[[1;6D" shift-ctrl-left
bindkey "^[[1;6C" shift-ctrl-right


arrow() {
  REGION_ACTIVE=0
  zle $1
}

k_left() arrow backward-char
k_right() arrow forward-char
k_up() arrow up-line-by-display-or-history
k_down() arrow down-line-by-display-or-history
k_home() arrow beginning-of-line
k_end() arrow end-of-line
k_ctrl_left() arrow backward-word
k_ctrl_right() arrow forward-word

zle -N k_left
zle -N k_right
zle -N k_up
zle -N k_down
zle -N k_home
zle -N k_end
zle -N k_ctrl_left
zle -N k_ctrl_right

# bindkey "^[[C" k_left
# bindkey "^[[D" k_right
bindkey "${key[Left]}" k_left
bindkey "${key[Right]}" k_right
bindkey "${key[Up]}" k_up
bindkey "${key[Down]}" k_down
bindkey "${key[Home]}" k_home
bindkey "${key[End]}" k_end
bindkey "^[[1;5D" k_ctrl_left
bindkey "^[[1;5C" k_ctrl_right

#beep for test
# beeptest() {
#  echo -n \\a
#  zle $1
# }
# k_test() beeptest
# zle -N k_test
#bindkey "${key[Left]}" k_test
#bindkey "^[\015" k_test

# deleting selected chars
# original code posted by Mr.takc923
# edited for working w/ Del or BS by ayapi
# http://qiita.com/takc923/items/35d9fe81f61436c867a8 

delete-region() {
  zle kill-region
  CUTBUFFER=$killring[1]
  shift killring
}
zle -N delete-region

backward-delete-char-or-region() {
  if [ $REGION_ACTIVE -eq 0 ]; then
    zle backward-delete-char
  else
    zle delete-region
  fi
}
zle -N backward-delete-char-or-region

function delete-char-or-region() {
  if [ $REGION_ACTIVE -eq 0 ]; then
    zle delete-char
  else
    zle delete-region
  fi
}
zle -N delete-char-or-region

bindkey "${key[Backspace]}" backward-delete-char-or-region
bindkey "${key[Delete]}" delete-char-or-region

# deleting selected chars with normal char
zle -A self-insert zle-self-insert
delete-region-with-normal-char() {
  if [ $REGION_ACTIVE -ne 0 ]; then
    zle delete-region
  fi
  zle zle-self-insert
}
zle -N self-insert delete-region-with-normal-char

# copy/paste
cb_copy() {
  zle copy-region-as-kill
  print -rn $CUTBUFFER | xsel -ib
}
zle -N cb_copy

cb_cut() {
  zle kill-region
  print -rn $CUTBUFFER | xsel -ib
}
zle -N cb_cut

cb_paste() {
  killring=("$CUTBUFFER", "{(@)killring[1,-2]}")
  CUTBUFFER=$(xsel -ob < /dev/null 2> /dev/null)
  zle yank
}
zle -N cb_paste

bindkey "^c" cb_copy
bindkey "^x" cb_cut
bindkey "^v" cb_paste

# fuzzy completion
export FZF_DEFAULT_OPTS='
  --reverse 
  --ansi 
  --color fg:252,hl:222,fg+:170,bg+:235,hl+:222 
  --color info:144,prompt:161,spinner:135,pointer:135,marker:118
'
source /etc/profile.d/fzf.zsh

bindkey '^F' fzf-file-widget
bindkey '^D' fzf-cd-widget
bindkey '^R' fzf-history-widget

# uim-fep
if [[ -n "$TMUX" ]]; then
  if [ -n "$TMUX_SPLIT" ]; then
    unset UIM_FEP_PID
    unset TMUX_SPLIT
  fi
  if [ -z "$UIM_FEP_PID" ]; then
    uim-fep -s backtick
  fi
  
  old_set=$(tmux showenv UIM_FEP_SETMODE_FILES 2> /dev/null | cut -d "=" -f2)
  if [ -n "$old_set" ]; then
    tmux setenv UIM_FEP_SETMODE_FILES $UIM_FEP_SETMODE:$old_set
  else
    tmux setenv UIM_FEP_SETMODE_FILES $UIM_FEP_SETMODE
  fi
  
  old_get=$(tmux showenv UIM_FEP_GETMODE_FILES 2> /dev/null | cut -d "=" -f2)
  if [ -n "$old_get" ]; then
    tmux setenv UIM_FEP_GETMODE_FILES $UIM_FEP_GETMODE:$old_get
  else
    tmux setenv UIM_FEP_GETMODE_FILES $UIM_FEP_GETMODE
  fi
  
  tmux setenv UIM_FEP_PID $UIM_FEP_PID
fi

function uim_off() {
  if [ -n "$UIM_FEP_SETMODE" ]; then
    echo 0 > $UIM_FEP_SETMODE
  fi
}
add-zsh-hook preexec uim_off


alias keycode="xev | awk -F'[ )]+' '/^KeyPress/ { a[NR+2] } NR in a { printf \"%-3s %s\n\", \$5, \$8 }'"
alias ls='ls -a --group-directories-first --color=auto'
alias vim='/usr/bin/nvim'
alias ovim='/usr/bin/vim'
alias vimdiff='nvim -d'

export NVM_DIR="/home/ayapi/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

export NODE_PATH=${NVM_PATH}_modules

export PATH=$PATH:$HOME/node_tools

alias gpgimp='gpg --keyserver http://pgp.mit.edu --recv-key'
alias pacupg='sudo snp "pacman -Syu; pacmrr; pacnews"'
alias aurupg='snp "yaourt -Syua; sudo pacmrr; sudo pacnews"'
alias uimupg='sudo uim-module-manager --register mozc'

alias news='newsbeuter'

function archnews() {
  url="https://www.archlinux.org/feeds/news/"
  if [[ $1 = "view" ]]; then
    feed-view -n $2 $url | w3m -T text/html
  elif [[ $1 = "list" ]] || [[ $# -eq 2 ]]; then
    feed-list -h $2 $url
  else
    feed-list -h 3 $url
  fi
}
alias archnews=archnews

function font-install(){
  current_dir=$(pwd)
  _ mv $1 /usr/share/fonts/$2
  cd /usr/share/fonts/$2
  _ mkfontscale
  _ mkfontdir
  _ fc-cache -vf .
  xset fp rehash
  cd $current_dir
}
alias font-install=font-install

source ~/.zshrc.local

