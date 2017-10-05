

#
# startup file read in interactive login shells
#
# The following code helps us by optimizing the existing framework.
# This includes zcompile, zcompdump, etc.
#

(
  # Function to determine the need of a zcompile. If the .zwc file
  # does not exist, or the base file is newer, we need to compile.
  # These jobs are asynchronous, and will not impact the interactive shell
  zcompare() {
    if [[ -s ${1} && ( ! -s ${1}.zwc || ${1} -nt ${1}.zwc ) ]]; then
      zcompile ${1}
    fi
  }

  local zim_mods=${ZIM_HOME}/modules
  setopt EXTENDED_GLOB

  # zcompile the completion cache; siginificant speedup.
  for file in ${ZDOTDIR:-${HOME}}/.zcomp^(*.zwc)(.); do
    zcompare ${file}
  done

  # zcompile .zshrc
  zcompare ${ZDOTDIR:-${HOME}}/.zshrc

  # zcompile some light module init scripts
  zcompare ${zim_mods}/git/init.zsh
  zcompare ${zim_mods}/git-info/init.zsh
  zcompare ${zim_mods}/utility/init.zsh
  zcompare ${zim_mods}/pacman/init.zsh
  zcompare ${zim_mods}/spectrum/init.zsh
  zcompare ${zim_mods}/completion/init.zsh
  zcompare ${zim_mods}/fasd/init.zsh

  # zcompile all .zsh files in the custom module
  for file in ${zim_mods}/custom/**/^(README.md|*.zwc)(.); do
    zcompare ${file}
  done

  # zcompile all autoloaded functions
  for file in ${zim_mods}/**/functions/^(*.zwc)(.); do
    zcompare ${file}
  done

  # syntax-highlighting
  for file in ${zim_mods}/syntax-highlighting/external/highlighters/**^test-data/*.zsh; do
    zcompare ${file}
  done
  zcompare ${zim_mods}/syntax-highlighting/external/zsh-syntax-highlighting.zsh

  # zsh-histery-substring-search
  zcompare ${zim_mods}/history-substring-search/external/zsh-history-substring-search.zsh

) &!#
# startup file read in interactive login shells
#
# The following code helps us by optimizing the existing framework.
# This includes zcompile, zcompdump, etc.
#

(
  # Function to determine the need of a zcompile. If the .zwc file
  # does not exist, or the base file is newer, we need to compile.
  # These jobs are asynchronous, and will not impact the interactive shell
  zcompare() {
    if [[ -s ${1} && ( ! -s ${1}.zwc || ${1} -nt ${1}.zwc) ]]; then
      zcompile ${1}
    fi
  }

  # First, we will zcompile the completion cache, if it exists. Siginificant speedup.
  zcompare ${ZDOTDIR:-${HOME}}/.zcompdump

  # Next, zcompile .zshrc if needed
  zcompare ${ZDOTDIR:-${HOME}}/.zshrc

  # Now, zcompile some light module init scripts
  zcompare ${ZDOTDIR:-${HOME}}/.zim/modules/git/init.zsh
  zcompare ${ZDOTDIR:-${HOME}}/.zim/modules/utility/init.zsh
  zcompare ${ZDOTDIR:-${HOME}}/.zim/modules/pacman/init.zsh
  zcompare ${ZDOTDIR:-${HOME}}/.zim/modules/spectrum/init.zsh
  zcompare ${ZDOTDIR:-${HOME}}/.zim/modules/completion/init.zsh
  zcompare ${ZDOTDIR:-${HOME}}/.zim/modules/custom/init.zsh

  # Then, we should zcompile the 'heavy' modules where possible.
  # This includes syntax-highlighting and completion. 
  # Other modules may be added to this list at a later date.
  zim=${ZDOTDIR:-${HOME}}/.zim
  setopt EXTENDED_GLOB

  #
  # syntax-highlighting zcompile
  #
  if [[ -d ${zim}/modules/syntax-highlighting/external/highlighters ]]; then
    # compile the highlighters
    for file in ${zim}/modules/syntax-highlighting/external/highlighters/**/*.zsh; do
      zcompare ${file}
    done
    # compile the main file
    zcompare ${zim}/modules/syntax-highlighting/external/zsh-syntax-highlighting.zsh
  fi

  #
  # zsh-histery-substring-search zcompile
  #
  if [[ -s ${zim}/modules/history-substring-search/external/zsh-history-substring-search.zsh ]]; then
    zcompare ${zim}/modules/history-substring-search/external/zsh-history-substring-search.zsh
  fi
  

) &!
