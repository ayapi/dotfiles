function! s:menu2Snip(argstxt) abort
  if a:argstxt == ''
    return ''
  endif

  let l:argstxt = a:argstxt
  let l:argstxt = substitute(l:argstxt, '^.\{-}(\(.\{-}\)).*$', '\1', '')
  
  let l:args = split(l:argstxt, ',\s*')
  return join(map(l:args, '"${" . (v:key + 1) . ":" . v:val ."}"'), ', ')
endfunction

function! ExpandPhp() abort
  if !exists('b:completed_item') || empty(b:completed_item)
    return 0
  endif
  
  let l:item = b:completed_item
  
  if !has_key(l:item, 'word')
        \ || (!has_key(l:item, 'info') && !has_key(l:item, 'menu'))
    return 0
  endif
  
  if l:item.word !~ '^\S\+(.*)\?$'
    " completed word is not a function
    return 0
  endif
  
  if getline('.')[:col('.')-2] !~ l:item.word . '$'
    " completed word is old
    let b:completed_item = {}
    return 0
  endif
  
  if l:item.word !~ '($'
    " function has any arguments
    return 1
  endif
  
  let l:argstxt = has_key(l:item, 'info') ? l:item.info : l:item.menu
  let l:sniptxt = s:menu2Snip(l:argstxt) . ')'
  
  if l:sniptxt != ''
    execute "inoremap <silent><expr> <F22> " .
          \	"neosnippet#anonymous(\'". l:sniptxt . "\')"
    call feedkeys("\<F22>")
  endif
  return 1
endfunction

let b:expandfunc = "ExpandPhp"
