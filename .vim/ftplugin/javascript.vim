"let tern#is_show_argument_hints_enabled=1

setlocal iskeyword-=.
setlocal dictionary=~/.vim/dicts/javascript.dict

" <S-F6> for rename(refactor)
inoremap <buffer> <expr> <F18> pumvisible() ? "\<C-e>\<C-o>:TernRename\<CR>" : "\<C-o>:TernRename\<CR>"

" <F2> for show doc
inoremap <buffer> <F2> <C-o>:TernDocBrowse<CR>
