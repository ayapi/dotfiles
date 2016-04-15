function! PhpDocOneLineVarComment() abort
  try
    call pdv#DocumentCurrentLine()
  catch
    let l:line = getline('.')
    let l:match = matchlist(l:line, '\(\s*\)\($[^ \t=]\+\)')
    if empty(l:match)
      return
    endif
    let l:lnum = line('.')
    let l:comment = l:match[1] . '/** @var ' . l:match[2] . '  */'
    call append(l:lnum - 1, l:comment)
    call cursor(l:lnum, len(l:comment) - 2)
  endtry
endfunction

let g:pdv_template_dir = $HOME . "/.vim/plugged/pdv/templates"
inoremap <buffer> <C-d> <C-o>:call PhpDocOneLineVarComment()<CR>