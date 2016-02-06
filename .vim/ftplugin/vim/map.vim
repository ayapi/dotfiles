" [continuation new line]
" before C-Enter
" let ayapi = [
"              ^
" after C-Enter
" let ayapi = [
"         \ 
"           ^
" <C-Enter> = <F23> in my keysym
inoremap <silent><buffer><expr> <F23>
      \ pumvisible() ? "\<C-e>\<CR>\\ ": "\<CR>\\ "
