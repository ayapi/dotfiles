" ayapi's custom omnifunc
" =======================
" better omni-completion for vim-script.
" 
" feature
" -------
" - show only long-form name items
" - show syntax group name
" 

source ~/.vim/scripts/vim_longform_keywords.vim

function! VimScriptOmniComplete(findstart, base)
  if a:findstart
    return call("syntaxcomplete#Complete", [a:findstart, a:base])
  endif

  let l:matches = []
  let l:omni_matches = call("syntaxcomplete#Complete", [0, a:base])
  if type(l:omni_matches) == 3
    " filter out 'short-form name' item & add group name
    for l:o in l:omni_matches
      if has_key(g:vim_longform_keywords, l:o)
        call add(l:matches,{'word': l:o,
                           \'menu': '('.g:vim_longform_keywords[l:o].')'})
      endif
    endfor
  endif
  return l:matches
endfunction

set omnifunc=VimScriptOmniComplete

setlocal keywordprg=:help

