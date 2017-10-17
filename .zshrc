

#
# User configuration sourced by interactive shells
#

# Change default zim location 
export ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim

# Source zim
if [[ -s ${ZIM_HOME}/init.zsh ]]; then
  source ${ZIM_HOME}/init.zsh
fi

fpath=( "$HOME/.zfunctions" $fpath )

autoload -U promptinit && promptinit
prompt ayapi

if [[ -n "$VIM" ]]; then
  # export TERM="rxvt-unicode-256color"
  export TERM="mlterm-256color"
fi

export TERMINFO=${ZDOTDIR:-${HOME}}/.terminfo

ulimit -c unlimited
stty -ixon -ixoff
stty intr "^K"

autoload -Uz add-zsh-hook

autoload -Uz zmv
alias zmv='noglob zmv -W'

plugins=()

if which dircolors > /dev/null 2>&1; then
  eval $(dircolors ${ZDOTDIR:-${HOME}}/.dircolors)
fi

if which gdircolors > /dev/null 2>&1; then
  eval $(gdircolors ${ZDOTDIR:-${HOME}}/.dircolors)
fi

zle_highlight=(region:bg=238 isearch:bg=065)

autoload zkbd
source ${ZDOTDIR:-${HOME}}/.zkbd/$TERM-:0.0 # may be different - check where zkbd saved yours

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

# reset prompt before exec
re-prompt() {
  prompt_ayapi_postaccept
  zle .reset-prompt
  zle .accept-line
}
zle -N accept-line re-prompt

# undo/redo
bindkey "^Z" undo
bindkey "^Y" redo

# inserting new line by ctrl+enter (multi-line prompt)
bindkey "^J" self-insert
bindkey -s "^[\015" "^J"

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


# Move cursor word-by-word (custom word splitting)
typeset -g -A char_groups
char_groups=(
  symbol "[!-/:-@[-\`{-~]"
  upper "[A-Z]"
  lower "[a-z]"
  number "[0-9]"
  blank "[[:space:]]"
  hiragana "[あ-ん]"
  katakana "[ア-ヶ]"
  other "[^a-zA-Z0-9[:space:]!-/:-@[-\`{-~あ-んア-ヶ]"
)
get_char_group() {
  local char="$1"
  for k in ${(k)char_groups}; do
    if [[ "$char" =~ ${char_groups[$k]} ]]; then
      local group=($k ${char_groups[$k]})
      echo $group
      break
    fi
  done
}

backward-smart-word() {
  local char=${LBUFFER[$#LBUFFER, $#LBUFFER]}
  local group=($(get_char_group "${char}"))
  local dest
  for ((i = $#LBUFFER; i > 0; i--)) {
    if ! [[ "${LBUFFER[$i]}" =~ "${group[2]}" ]]; then
      dest=$i
      break
    fi
  }
  if [ -z "$dest" ]; then
    zle beginning-of-line
  else
    if [ "${group[1]}" '==' "lower" ]; then
      local to_group=($(get_char_group "${LBUFFER[$(($dest))]}"))
      if [ "${to_group[1]}" '==' "upper" ]; then
        dest=$(($dest-1))
      fi
    fi
    CURSOR=$dest
  fi
  zle redisplay
}
zle -N backward-smart-word

forward-smart-word() {
  local char=${BUFFER[$CURSOR+1, $CURSOR+1]}
  local group=($(get_char_group "${char}"))
  local start=1
  if [ "${group[1]}" '==' "upper" ]; then
    local tmp_next_group=($(get_char_group "${BUFFER[$CURSOR+2, $CURSOR+2]}"))
    if [ "${tmp_next_group[1]}" '==' "lower" ]; then
      start=2
      unset group
      local group=(${tmp_next_group})
    fi
  fi
  
  local dest
  for ((i = $start; i <= $#RBUFFER; i++)) {
    if ! [[ "${RBUFFER[$i]}" =~ "${group[2]}" ]]; then
      dest=$(($i+$CURSOR))
      break
    fi
  }
  if [ -z "$dest" ]; then
    zle end-of-line
  else
    CURSOR=$(($dest-1))
  fi
  zle redisplay
}
zle -N forward-smart-word


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
shift-ctrl-left() shift-arrow backward-smart-word
shift-ctrl-right() shift-arrow forward-smart-word

zle -N shift-left
zle -N shift-right
zle -N shift-up
zle -N shift-down
zle -N shift-home
zle -N shift-end
zle -N shift-ctrl-left
zle -N shift-ctrl-right

bindkey "${key[ShiftLeft]}" shift-left
bindkey "${key[ShiftRight]}" shift-right
bindkey "${key[ShiftUp]}" shift-up
bindkey "${key[ShiftDown]}" shift-down
bindkey "${key[ShiftHome]}" shift-home
bindkey "${key[ShiftEnd]}" shift-end
bindkey "${key[ControlShiftLeft]}" shift-ctrl-left
bindkey "${key[ControlShiftRight]}" shift-ctrl-right


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
k_ctrl_left() arrow backward-smart-word
k_ctrl_right() arrow forward-smart-word

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
bindkey "${key[ControlLeft]}" k_ctrl_left
bindkey "${key[ControlRight]}" k_ctrl_right

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
delete-region-with-normal-char() {
  if [ $REGION_ACTIVE -ne 0 ]; then
    zle delete-region
  fi
  zle .self-insert
}
zle -N delete-region-with-normal-char
zle -N self-insert delete-region-with-normal-char

# delete by word
# <C-BS>
ctrl-bs() {
  shift-arrow
  backward-smart-word
  zle delete-region
}
zle -N ctrl-bs
bindkey "${key[ControlBackspace]}" ctrl-bs

# <C-Del>
ctrl-del() {
  shift-arrow
  forward-smart-word
  zle delete-region
}
zle -N ctrl-del
bindkey "${key[ControlDelete]}" ctrl-del
bindkey "^[[3^" ctrl-del

# copy/paste
cb_copy() {
  zle copy-region-as-kill
  if which xsel > /dev/null 2>&1; then
    print -rn $CUTBUFFER | xsel -ib
  elif which pbcopy > /dev/null 2>&1; then
    print -rn $CUTBUFFER | pbcopy
  fi
}
zle -N cb_copy

cb_cut() {
  zle kill-region
  if which xsel > /dev/null 2>&1; then
    print -rn $CUTBUFFER | xsel -ib
  elif which pbcopy > /dev/null 2>&1; then
    print -rn $CUTBUFFER | pbcopy
  fi
}
zle -N cb_cut

cb_paste() {
  killring=("$CUTBUFFER", "{(@)killring[1,-2]}")
  if which xsel > /dev/null 2>&1; then
    CUTBUFFER=$(xsel -ob < /dev/null 2> /dev/null)
    zle yank
  elif which pbcopy > /dev/null 2>&1; then
    CUTBUFFER=$(pbpaste < /dev/null 2> /dev/null)
    zle yank
  fi
}
zle -N cb_paste

bindkey "^c" cb_copy
bindkey "^x" cb_cut
bindkey "^v" cb_paste

# auto completion
# zstyle -d ':completion:*:default' list-prompt
# unset LISTPROMPT
setopt auto_menu
unsetopt auto_list
unset LISTMAX
setopt menu_complete
setopt always_last_prompt
setopt no_list_beep
setopt no_beep
# zstyle -e ':completion:*' '(( compstate[nmatches] > 10)) && reply=( true )'
zstyle ':completion:*' menu select=0 interactive
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s

menu_visible=0
menu-expand-or-complete-wrap() {
  menu_visible=1
  zle menu-expand-or-complete
}
zle -N menu-expand-or-complete-wrap
bindkey "^i" menu-expand-or-complete-wrap

zmodload zsh/complist

bindkey -M menuselect "${key[Left]}" backward-char
bindkey -M menuselect "${key[Right]}" forward-char
bindkey -M menuselect "${key[Up]}" up-line-or-history
bindkey -M menuselect "${key[Down]}" down-line-or-history
bindkey -M menuselect "\e[z"  reverse-menu-complete
bindkey -M menuselect '^c' send-break
bindkey -M menuselect '^m' accept-line
bindkey -M menuselect '^u' accept-and-hold

function limit-completion
{
  if [[ compstate[list_lines]+BUFFERLINES+1 -gt LINES ]]; then
    compstate[list]='list explanations'
    [[ compstate[list_lines]+BUFFERLINES+1 -gt LINES ]] && compstate[list]=''
  fi
}

list-choices-after-self-insert() {
  zle delete-region-with-normal-char
  if ((PENDING == 0)); then
    comppostfuncs=(limit-completion)
    zle list-choices
    zle redisplay
  fi
}
zle -N self-insert list-choices-after-self-insert

list-choices-after-space() {
  zle .magic-space
  comppostfuncs=(limit-completion)
  zle list-choices
  zle redisplay
}
zle -N magic-space list-choices-after-space

list-choices-after-backspace() {
  zle .backward-delete-char
  comppostfuncs=(limit-completion)
  zle list-choices
  zle redisplay
}
zle -N backward-delete-char list-choices-after-backspace

list-choices-after-delete() {
  zle .delete-char
  comppostfuncs=(limit-completion)
  zle list-choices
  zle redisplay
}
zle -N delete-char list-choices-after-delete

list-choices-after-delete-word() {
  zle .delete-word
  comppostfuncs=(limit-completion)
  zle list-choices
  zle redisplay
}
zle -N delete-word list-choices-after-delete-word

list-choices-after-backward-delete-word() {
  zle .backward-delete-word
  comppostfuncs=(limit-completion)
  zle list-choices
  zle redisplay
}
zle -N backward-delete-word list-choices-after-backward-delete-word

# list-choices-after-accept-line() {
#   if ((menu_visible == 1)); then
#     menu_visible=0
#     comppostfuncs=(limit-completion)
#     zle list-choices
#   else
#     zle .accept-line
#   fi
#   zle redisplay
# }
# zle -N accept-line list-choices-after-accept-line

cancel-menu() {
  if ((menu_visible == 1)); then
    menu_visible=0
  fi
}
zle -N send-break cancel-menu

zstyle -d :completion:\*:\*:kill:\*

# fuzzy completion
export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -l'
export FZF_DEFAULT_OPTS="
  --ansi 
  --color fg:252,hl:222,fg+:170,bg+:235,hl+:222 
  --color info:144,prompt:161,spinner:135,pointer:135,marker:118 
  --bind=ctrl-h:backward-kill-word 
"
# followings are invalid. fzf cant handle these keys
# ctrl-right:forward-word,ctrl-left:backward-word,ctrl-del:kill-word,ctrl-v:yank

if [[ -s "/usr/share/fzf/key-bindings.zsh" ]]; then
  source /usr/share/fzf/key-bindings.zsh
fi

if [[ -s "/etc/profile.d/fzf-extras.zsh" ]]; then
  source /etc/profile.d/fzf-extras.zsh
fi

# file search including hidden files(dotfiles)
# ref. https://github.com/junegunn/fzf/issues/337
fzf-file-include-hidden-widget() {
  local selected
  local char=${LBUFFER[$#LBUFFER]}
  local query=""
  local lbuffer="${LBUFFER}"
  if [ "$char" != " " ]; then
    query=${${(z)lbuffer}[-1]}
    lbuffer=${LBUFFER[1,($#LBUFFER - $#query)]}
  fi
  selected=( $(ag --hidden --skip-vcs-ignores --path-to-ignore=~/.agignore --ignore=.git --silent -l 2> /dev/null | fzf -q "$query") )
  LBUFFER="$lbuffer$selected"
  zle redisplay
}
zle -N fzf-file-include-hidden-widget

fzf-file-from-root-include-hidden-widget() {
  local selected
  local char=${LBUFFER[$#LBUFFER]}
  local query=""
  local lbuffer="${LBUFFER}"
  if [ "$char" != " " ]; then
    query=${${(z)lbuffer}[-1]}
    lbuffer=${LBUFFER[1,($#LBUFFER - $#query)]}
  fi
  selected=( $(ag --hidden --skip-vcs-ignores --path-to-ignore=~/.agignore --ignore=.git -l '^(?=.)' / 2> /dev/null | fzf -q "$query") )
  LBUFFER="$lbuffer$selected"
  zle redisplay
}
zle -N fzf-file-from-root-include-hidden-widget

fzf-file-git-untracked-and-unstaged() {
  local selected
  local char=${LBUFFER[$#LBUFFER]}
  local query=""
  local lbuffer="${LBUFFER}"
  if [ "$char" != " " ]; then
    query=${${(z)lbuffer}[-1]}
    lbuffer=${LBUFFER[1,($#LBUFFER - $#query)]}
  fi
  selected=( $({git ls-files --modified --exclude-standard; git ls-files --others --exclude-standard} | fzf -q "$query") )
  LBUFFER="$lbuffer$selected"
  zle redisplay
}
zle -N fzf-file-git-untracked-and-unstaged

bindkey '^F' fzf-file-include-hidden-widget
bindkey '^_' fzf-file-from-root-include-hidden-widget
bindkey '^U' fzf-file-git-untracked-and-unstaged
bindkey '^D' fzf-cd-widget
bindkey '^R' fzf-history-widget

# grep & preview
function agp() {
  if [[ -n "$NVIM_LISTEN_ADDRESS" ]]; then
    ag --hidden --ignore .git --nocolor --nogroup --column $@ 2> /dev/null | ag2nvim
  else
    sockpath=$(mktemp -d /tmp/nvimXXXXXX)/nvim
    NVIM_LISTEN_ADDRESS="$sockpath" nvim &
    ag --hidden --ignore .git --nocolor --nogroup --column $@ 2> /dev/null | NVIM_LISTEN_ADDRESS="$sockpath" ag2nvim 2> /dev/null &!
    fg
  fi
}
alias agp=agp

function nv() {
  if [ $# -eq 0 ]; then
    echo "<filename>    open file"
    echo "-o <filename> open file split"
    return 1
  fi
  
  local filename="$@[-1]"
  local -a args
  args=($@[1,-2] ${filename:a})
  
  if [[ -n "$NVIM_LISTEN_ADDRESS" ]]; then
    nvr $args
  else
    nvim $args
  fi
}
alias nv=nv

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

unalias gls
if which gls > /dev/null 2>&1; then
  alias ls='gls -a --group-directories-first --color=auto'
else
  alias ls='ls -a --group-directories-first --color=auto'
fi

if which nvim > /dev/null 2>&1; then
  alias vim='/usr/bin/nvim'
  alias ovim='/usr/bin/vim'
  alias vimdiff='nvim -d'
fi


# aliases from prezto utility (some arranged by ayapi)

# Disable correction.
setopt CORRECT
alias ag='nocorrect ag'
alias ack='nocorrect ack'
alias cd='nocorrect cd'
alias cp='nocorrect cp'
alias ebuild='nocorrect ebuild'
alias gcc='nocorrect gcc'
alias gist='nocorrect gist'
alias grep='nocorrect grep'
alias heroku='nocorrect heroku'
alias ln='nocorrect ln'
alias man='nocorrect man'
alias mkdir='nocorrect mkdir'
alias mv='nocorrect mv'
alias mysql='nocorrect mysql'
alias rm='nocorrect rm'

# Disable globbing.
alias bower='noglob bower'
alias fc='noglob fc'
alias find='noglob find'
alias ftp='noglob ftp'
alias history='noglob history'
alias locate='noglob locate'
alias rake='noglob rake'
alias rsync='noglob rsync'
alias scp='noglob scp'
alias sftp='noglob sftp'

# Define general aliases.
alias cp="${aliases[cp]:-cp} -i"
alias ln="${aliases[ln]:-ln} -i"
alias mkdir="${aliases[mkdir]:-mkdir} -p"
alias mv="${aliases[mv]:-mv} -i"
alias rm="${aliases[rm]:-rm} -i"
alias type='type -a'

# Resource Usage
alias df='df -kh'
alias du='du -kh'

alias ag='ag --path-to-ignore=~/.agignore --hidden --silent'

if [ -z "$NVM_DIR" ]; then
  export NVM_DIR="$HOME/.nvm"
fi
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

export NODE_PATH=${NVM_PATH}_modules

export PATH=$PATH:$HOME/node_tools

export GOPATH=$HOME/.go
export PATH=$HOME/.go/bin:$PATH

if which ghq > /dev/null 2>&1; then
  export GHQ_ROOT="$HOME/.ghq"
  fpath=($GOPATH/src/github.com/motemen/ghq/zsh ${fpath})
fi

export PATH=$HOME/.phpenv/shims:$PATH
if which phpenv > /dev/null 2>&1; then
  eval "$(phpenv init - zsh)"
fi

export PATH="$HOME/.rbenv/bin:$PATH"
if which rbenv > /dev/null 2>&1; then
  eval "$(rbenv init - zsh)"
fi

export PATH=$HOME/.composer/vendor/bin:$PATH
export ECLIPSE_HOME=/usr/lib/eclipse
alias eclimd=$ECLIPSE_HOME/eclimd
alias eclim=$ECLIPSE_HOME/eclim

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

if [[ -s "${ZDOTDIR:-${HOME}}/.zshrc.local" ]]; then
  source ~/.zshrc.local
fi


# The next line updates PATH for the Google Cloud SDK.
if [ -s "$HOME/google-cloud-sdk/path.zsh.inc" ]; then
  source "$HOME/google-cloud-sdk/path.zsh.inc"
fi

# The next line enables shell command completion for gcloud.
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then
  source "$HOME/google-cloud-sdk/completion.zsh.inc"
fi

[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

autoload -U compinit
compinit

if [[ -s "${ZDOTDIR:-${HOME}}/.zcompcustom" ]]; then
  source $HOME/.zcompcustom
fi
