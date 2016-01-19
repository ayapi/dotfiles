" to use neco-vim without deoplete|neocomplete
" setlocal regexpengine=0

function! VimScriptOmniComplete(findstart, base)
  " let l:input = s:get_cur_text()
  let l:line = getline('.')
  let l:input = l:line[:col('.')-2]
  " echomsg "called input:" . l:input
    
  if a:findstart
    echomsg string(call("necovim#get_complete_position", [l:input]))
    return call("necovim#get_complete_position", [l:input])
  endif
  
  let l:candidates = call("necovim#gather_candidates",
                        \ [substitute(l:input, '^\s\+', "", "g"), a:base])
  echomsg string(a:base)
  echomsg string(l:candidates)

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

  echomsg string(l:matches)
  return l:matches
endfunction

setlocal omnifunc=VimScriptOmniComplete

if !exists("g:funcsnips.vim")
  source ~/.vim/funcsnippets/vim.vim
endif

function! VimScriptExpandFunc() abort
  if !exists('v:completed_item') || empty(v:completed_item)
    return 0
  endif

  let l:item = v:completed_item
  if l:item.word !~ "($"
    return 0
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
    return 1
  endif
  return 0
endfunction

let b:expandfunc = "VimScriptExpandFunc"

" vim: foldmethod=marker
