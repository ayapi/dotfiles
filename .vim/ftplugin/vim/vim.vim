" to use neco-vim without deoplete|neocomplete

function! VimScriptOmniComplete(findstart, base)
  let l:line = getline('.')
  let l:input = l:line[:col('.')-2]
    
  if a:findstart
    return call("necovim#get_complete_position", [l:input])
  endif
  
  let l:candidates = call("necovim#gather_candidates",
                        \ [substitute(l:input, '^\s\+', "", "g"), a:base])

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

  return l:matches
endfunction

setlocal omnifunc=VimScriptOmniComplete

augroup necovim
  autocmd!
  autocmd CursorHoldI * call necovim#helper#make_cache()
augroup END

function! Doc2Snip(argstxt) abort
  if a:argstxt == ''
    return ''
  endif

  let l:argstxt = a:argstxt
  let l:argstxt = substitute(l:argstxt, '^.\+(\(.*\))', '\1', '')
  let l:argstxt = substitute(l:argstxt, '[^\[],\s\?\.\.\.', '[, ...]', 'g')
  let l:argstxt = substitute(l:argstxt, ',\s\{-}\[', '[,', 'g')

  if l:argstxt =~ '^\[' && len(substitute(l:argstxt, '[^\[]', '', 'g')) == 1
    return '${1:#:' . substitute(l:argstxt, '\[\(.\+\)\]', '\1', '') . '}'
  endif
  
  let l:sniptxt = ''
  let l:in_argname = 0
  let l:tab_count = 1
  let l:depth = 0
  for j in range(0, len(l:argstxt)-1)
    let l:char = l:argstxt[j]
    if l:char =~ '^[\[\],]$'
      if l:in_argname == 1
        let l:sniptxt .= repeat('\', l:depth) . '}'
        let l:in_argname = 0
      endif
      
      if l:char == ','
        let l:sniptxt .= ', '
      elseif l:char == ']'
        let l:depth -= 1
        let l:sniptxt .= repeat('\', l:depth) . '}'
      elseif l:char == '['
        let l:sniptxt .= '${' . l:tab_count . ':'
        let l:tab_count += 1
        let l:depth += 1
      endif
    else
      if l:in_argname == 0
        let l:sniptxt .= '${' . l:tab_count . ':'
        let l:in_argname = 1
        let l:tab_count += 1
      endif
      let l:sniptxt .= l:char
    endif
  endfor
  if l:in_argname == 1
    let l:sniptxt .= '}'
  endif
  
  return l:sniptxt
endfunction

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
  try
    execute "help " . substitute(l:item.word, '(.*)', '()', 'g')
    wincmd p
  catch /E149: /
    " ignore error
  endtry
  
  if l:item.word !~ '($'
    " function has any arguments
    return 1
  endif

  let l:argstxt = l:item.info
  let l:argstxt = substitute(l:argstxt, '[{} ]', '', 'g')

  let l:sniptxt = Doc2Snip(l:argstxt) . ')'

  if l:sniptxt != ''
    execute "inoremap <silent><expr> <F22> " .
          \	"neosnippet#anonymous(\'". l:sniptxt . "\')"
    call feedkeys("\<F22>")
  endif
  return 1
endfunction

let b:expandfunc = "VimScriptExpandFunc"

" vim: foldmethod=marker
