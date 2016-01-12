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
  autocmd BufWritePost * call ConvertIndent()
  autocmd FileChangedShellPost * call ConvertIndentOrSetTodo()
  autocmd BufEnter * call ConvertIndentIfTodoExists()
  autocmd BufWritePre * call RevertIndent()
augroup END

function! SaveIndentSize() abort
  if &shiftwidth == 16 && &expandtab == 0
    " hard-tab detected by tpope/vim-sleuth
    let b:noconvertindent = 1
    set shiftwidth=8
  elseif &diff || &filetype == "help" || &buftype != ''
    let b:noconvertindent = 1
  endif

  let b:org_shiftwidth = getbufvar("", "&shiftwidth", 8)
  call ConvertIndent()
  call ForgetUndo()
endfunction

function! ConvertIndentOrSetTodo() abort
  let l:changed_bufno = expand("<afile>")
  if l:changed_bufno == expand("%")
    call ConvertIndent()
    call ForgetUndo()
  else
    call setbufvar(l:changed_bufno, "need_convert_indent", 1)
  endif
endfunction

function! ConvertIndentIfTodoExists() abort
  if exists('b:need_convert_indent')
    unlet b:need_convert_indent
    call ConvertIndent()
    call ForgetUndo()
  endif
endfunction

function! ConvertIndent() abort
  if exists('b:noconvertindent') || !exists('b:org_shiftwidth')
    return
  endif
  
  if !&modifiable
    let l:org_modifiable=1
    set modifiable
  endif

  if &readonly
    let l:org_readonly=1
    set noreadonly
  endif

  call setbufvar("", "&shiftwidth", b:org_shiftwidth)
  call setbufvar("", "&tabstop", b:org_shiftwidth)
  set noexpandtab

  let l:save_cursor = getcurpos()
  
  " now, convert spaces to tab
  " ref. http://vim.1045645.n5.nabble.com/replace-spaces-by-tabs-begining-line-td3218935.html
  silent! %s/^ \+/\=substitute(submatch(0), repeat(' ', &tabstop), '\t', 'g')
  
  call setpos('.', l:save_cursor)

  set tabstop=2
  set shiftwidth=2

  " call ForgetUndo()
  
  if exists("l:org_modifiable")
    set nomodifiable
  endif

  if exists("l:org_readonly")
    set readonly
  endif
  
  set nomodified
endfunction

augroup revert_indent
  autocmd!
  autocmd BufWritePre * call RevertIndent()
augroup END

function! RevertIndent() abort
  if exists('b:noconvertindent') || !exists('b:org_shiftwidth')
    return
  endif
  call setbufvar("", "&tabstop", b:org_shiftwidth)
  call setbufvar("", "&shiftwidth", b:org_shiftwidth)
  set expandtab
  %retab
endfunction

" ref. http://superuser.com/questions/214696/how-can-i-discard-my-undo-history-in-vim
function! ForgetUndo()
  let old_undolevels = &undolevels
  set undolevels=-1
  execute "silent! normal! a \<BS>\<Esc>"
  let &undolevels = old_undolevels
  unlet old_undolevels
  set nomodified
endfunction
