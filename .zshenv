PATH=$HOME/bin:$PATH
export NVIM_TUI_ENABLE_TRUE_COLOR=1
export LESSCHARSET=utf-8
export LC_CTYPE=UTF-8

if [[ -s "${ZDOTDIR:-${HOME}}/.zshenv.local" ]]; then
  source ~/.zshenv.local
fi
