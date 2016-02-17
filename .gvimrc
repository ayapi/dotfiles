set background=dark
colorscheme molokai
source ~/.vim/highlight.vim

highlight Cursor guifg=black guibg=white
highlight iCursor guifg=white guibg=white
set guicursor=a:ver10-iCursor-blinkwait300-blinkon700-blinkoff700
set guicursor+=n:block-Cursor/iCursor-blinkwait300-blinkon700-blinkoff700

set guioptions-=T
set guioptions-=m
set guioptions-=r
set guioptions-=R
set guioptions-=l
set guioptions-=L
set guioptions-=b

set linespace=4

if has('win32')
  set guifont=ＭＳ\ ゴシック:h11:cSHIFTJIS

  " gvim起動したら速攻最大化する
  augroup maximize
    autocmd!
    autocmd GUIEnter * simalt ~x
  augroup END
endif
