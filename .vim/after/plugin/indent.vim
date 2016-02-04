" ------------------------------------
" Indent Style Bridge display & file
" ------------------------------------
" ref. http://stackoverflow.com/questions/13849368/can-vim-display-two-spaces-for-indentation-while-keeping-four-spaces-in-the-fil
" > I want to work on someone else's project, and he uses 4 spaces for indentation. I use 2, and my screen is not big enough to edit using 4 spaces comfortably.

set tabstop=16
set shiftwidth=16

augroup save_indent_size
  autocmd!
  autocmd FileType * call SaveIndentSize()
  autocmd FileChangedShellPost * call Org2TabOrSetTodo()
  autocmd BufEnter * call Org2TabIfTodoExists()
  autocmd BufWriteCmd * call Tab2OrgAndWrite()
augroup END

let s:indent_fallback = {
      \ '_': 4,
      \ 'javascript': 2,
      \ 'jade': 2,
      \ 'stylus': 2,
      \ 'python': 4,
      \ 'java': 4,
      \ 'zsh': 2
      \}
function! GetIndentFallback() abort
  if &filetype == '' || !has_key(s:indent_fallback, &filetype)
    return s:indent_fallback._
  endif
  return s:indent_fallback[&filetype]
endfunction

function! SaveIndentSize() abort
  if &diff || &filetype == "help" || &buftype != ''
    let b:noconvertindent = 1
  elseif &shiftwidth == 16
    if &expandtab == 0
      " hard-tab detected by tpope/vim-sleuth
      let b:noconvertindent = 1
      setlocal shiftwidth=2
      setlocal tabstop=2
    else
      let l:fallback = GetIndentFallback()
      setlocal shiftwidth=l:fallback
      setlocal tabstop=l:fallback
    endif
  endif

  let b:org_shiftwidth = getbufvar("", "&shiftwidth", 8)
  call Org2Tab()
endfunction

function! Org2TabOrSetTodo() abort
  let l:changed_bufno = expand("<afile>")
  if l:changed_bufno == expand("%")
    call Org2Tab()
  else
    call setbufvar(l:changed_bufno, "need_convert_indent", 1)
  endif
endfunction

function! Org2TabIfTodoExists() abort
  if exists('b:need_convert_indent')
    unlet b:need_convert_indent
    call Org2Tab()
  endif
endfunction

function! Org2Tab() abort
  if exists('b:noconvertindent') || !exists('b:org_shiftwidth')
    return
  endif
  
  if &modified
    let l:org_modified=1
  endif
  
  if !&modifiable
    let l:org_nomodifiable=1
    setlocal modifiable
  endif

  if &readonly
    let l:org_readonly=1
    setlocal noreadonly
  endif

  call setbufvar("", "&shiftwidth", b:org_shiftwidth)
  call setbufvar("", "&tabstop", b:org_shiftwidth)
  setlocal noexpandtab
  
  let line = 1
  let last_line = line('$')
  
  while line <= last_line
    let matched = matchlist(getline(line), '^\( \+\)\(.*\)$')
    if len(matched) > 0
      let writetxt = substitute(matched[1], repeat(' ', b:org_shiftwidth), '\t', 'g').matched[2]
      try | silent undojoin | catch | endtry
      call setline(line, writetxt)
    endif
    let line += 1
  endwhile

  setlocal tabstop=2
  setlocal shiftwidth=2
  
  if exists("l:org_nomodifiable")
    setlocal nomodifiable
  endif

  if exists("l:org_readonly")
    setlocal readonly
  endif
  
  if !exists("l:org_modified")
    setlocal nomodified
  endif
endfunction

function! Tab2OrgAndWrite() abort
  if exists('b:noconvertindent') || !exists('b:org_shiftwidth')
    call writefile(getline(1, '$'), expand("<afile>"), "b")
  endif
  let line = 1
  let last_line = line('$')
  let writetxts = []
  while line <= last_line
    let txt = getline(line)
    let matched = matchlist(txt, '^\(\t\+\)\(.*\)$')
    let writetxt = ""
    if len(matched) == 0
      let writetxt = txt
    else
      let writetxt = substitute(matched[1], '\t', repeat(' ', b:org_shiftwidth), 'g').matched[2]
    endif
    call add(writetxts, writetxt)
    
    let line += 1
  endwhile
  call writefile(writetxts, expand("<afile>"), '')
  setlocal nomodified
endfunction

