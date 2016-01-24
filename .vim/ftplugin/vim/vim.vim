" to use neco-vim without deoplete|neocomplete
" setlocal regexpengine=0

function! VimScriptOmniComplete(findstart, base)
  " let l:input = s:get_cur_text()
  let l:line = getline('.')
  let l:input = l:line[:col('.')-2]
  " echomsg "called input:" . l:input
    
  if a:findstart
    " echomsg string(call("necovim#get_complete_position", [l:input]))
    return call("necovim#get_complete_position", [l:input])
  endif
  
  let l:candidates = call("necovim#gather_candidates",
                        \ [substitute(l:input, '^\s\+', "", "g"), a:base])
  " echomsg string(a:base)
  " echomsg string(l:candidates)

  if a:base == ""
    return l:candidates
  endif

  let l:matches = []
  for k in l:candidates
    if strpart(k.word, 0, strlen(a:base)) ==# a:base
      call add(l:matches, k)
    endif
  endfor
  
  if len(l:matches) == 0
    return l:candidates
  endif

  " echomsg string(l:matches)
  return l:matches
endfunction

setlocal omnifunc=VimScriptOmniComplete

if !exists("g:funcsnips.vim")
  source ~/.vim/funcsnippets/vim.vim
endif

function! VimScriptExpandFunc() abort
  if !exists('b:completed_item') || empty(b:completed_item)
    return 0
  endif

  let l:item = b:completed_item

  if l:item.word !~ '^\S\+(.*)\?$'
    " completed word is not a function
    return 0
  endif

  if getline('.')[:col('.')-2] !~ l:item.word . '$'
    " completed word is old
    let b:completed_item = {}
    return 0
  endif
  
  " show vim-function help
  execute "help " . substitute(l:item.word, '(.*)', '()', 'g')
  wincmd p
  
  if l:item.word !~ '($'
    " function has any arguments
    return 1
  endif
  
  let l:matches = []

  for snip in g:funcsnips["vim"]
    let l:matched_list = matchlist(snip, '^\([^(]\+(\)\(.\+\)$')
    if l:matched_list[1] == l:item.word
      call add(l:matches, l:matched_list[2])
    endif
  endfor

  if len(l:matches) == 1
    execute "inoremap <silent><expr> <F22> neosnippet#anonymous(\'".l:matches[0]."\')"
    call feedkeys("\<F22>")
  endif
  return 1
endfunction

let b:expandfunc = "VimScriptExpandFunc"

" vim: foldmethod=marker
