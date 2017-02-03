PATH=$HOME/bin:$PATH
export NVIM_TUI_ENABLE_TRUE_COLOR=1

if [[ -s "${ZDOTDIR:-${HOME}}/.zshenv.local" ]]; then
  source ~/.zshenv.local
fi
