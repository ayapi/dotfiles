" [open document/help for the word under cursor]
" for example, when i want to see help `mode()` function
" and i hit Shift-k (vim's default keymap),
" vim opens help of `mode` COMMAND, not FUNCTION.
" it's unuseful so i define search function for it

" ref.
" Fzf with arg or with word under cursor · Issue #50 · junegunn/fzf.vim
" https://github.com/junegunn/fzf.vim/issues/50

function! SearchHelpTags() abort
  call fzf#vim#helptags({'options': '-q '.shellescape(expand('<cword>')), 'down': '~40%'})
endfunction

noremap  <buffer> <F2> :call SearchHelpTags()<CR>
inoremap <buffer> <F2> <C-o>:call SearchHelpTags()<CR>
