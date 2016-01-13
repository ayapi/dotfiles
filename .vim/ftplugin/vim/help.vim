" [open document/help for the word under cursor]
" for example, when i want to see help `mode()` function
" and i hit Shift-k (vim's default keymap),
" vim opens help of `mode` COMMAND, not FUNCTION.
" it's unuseful so i define search function for it

function! SearchHelpTags(tag) abort
  let l:tag = a:tag
  let l:from_bufnr = winbufnr(0)
  
  for nr in range(1, winnr('$'))
    let l:buf_no = winbufnr(nr)
    let l:buf_type = getbufvar(l:buf_no, '&buftype', '')
    if l:buf_type == 'help'
      let l:help_winnr = nr
      break
    endif
  endfor

  if !exists("l:help_winnr")
    " open help window newly
    help
  else
    " move cursor to existing help window
    execute l:help_winnr."wincmd w"
  endif
  
  let l:win_count_before_lclose = winnr('$')
  try
    lclose
  catch /E776: No location list/
    " ignore error
  endtry
  
  if l:tag == ""
    return
  endif

  let l:loclist_was_showing = l:win_count_before_lclose > winnr('$')
  
  let l:no_result = 0
  try
    execute "ltag /".l:tag
  catch /E426: tag not found/
    let l:no_result = 1
  endtry
  
  if len(getloclist(0)) == 0
    let l:no_result = 1
  endif

  if l:no_result == 1
    set nohlsearch
    
    try
      lolder
    catch
      " ignore error
    endtry
    
    if l:loclist_was_showing
      lopen
    endif

    redraw
    echohl WarningMsg
    echo "No result"
    echohl None
    let v:warningmsg = "No result"
    return
  endif
  
  lopen
  lrewind
  wincmd p
  
  " add highlight match
  " ref. rking/ag.vim
  let @/ = l:tag
  call feedkeys(":set hlsearch\<CR>", 'n')
endfunction

function! SearchHelpTagsPrompt() abort
  call inputsave()
  let l:tag = input('HelpTag > ', expand('<cword>'))
  call inputrestore()
  call SearchHelpTags(l:tag)
endfunction

noremap  <buffer> <F2> :call SearchHelpTags(expand('<cword>'))<CR>
inoremap <buffer> <F2> <C-o>:call SearchHelpTags(expand('<cword>'))<CR>

map <F14> <S-F2>
imap <F14> <S-F2>
noremap  <buffer> <S-F2> :call SearchHelpTagsPrompt()<CR>
inoremap <buffer> <S-F2> <C-o>:call SearchHelpTagsPrompt()<CR>

