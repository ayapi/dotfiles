set encoding=utf-8
scriptencoding utf-8

" Note: Skip initialization for vim-tiny or vim-small.
if 0 | endif

" filetype plugin on
" set omnifunc=syntaxcomplete#Complete

if has('vim_starting')
  if &compatible
    set nocompatible               " Be iMproved
  endif

  " Required:
  set runtimepath+=~/.vim/bundle/neobundle.vim/
endif

call neobundle#begin(expand('~/.vim/bundle/'))
NeoBundleFetch 'Shougo/neobundle.vim'

" My Bundles here:
" Refer to |:NeoBundle-examples|.
" Note: You don't set neobundle setting in .gvimrc!

if has('nvim')
  NeoBundle 'neovim/node-host'
endif

NeoBundle 'Shougo/neosnippet.vim'
" NeoBundle 'Shougo/neosnippet-snippets'
" NeoBundle 'honza/vim-snippets'

NeoBundle 'ternjs/tern_for_vim', {
  \ 'build': {
  \   'others': 'npm install'
  \ }
  \}
NeoBundle 'davidhalter/jedi-vim', {
  \ 'build' :{
  \   'others': 'git submodule update --init'
  \ }
  \}

NeoBundle 'kana/vim-submode'
NeoBundle 'Shougo/unite.vim'
NeoBundle 'Shougo/unite-outline'
NeoBundle 'Shougo/neomru.vim'
NeoBundle "tyru/caw.vim.git"
" NeoBundle 'vheon/vim-cursormode'

" color scheme
NeoBundle 'tomasr/molokai'

"NeoBundle 'vim-pandoc/vim-pandoc'
"NeoBundle 'vim-pandoc/vim-pandoc-syntax'

call neobundle#end()

" Required:
filetype plugin indent on

" If there are uninstalled bundles found on startup,
" this will conveniently prompt you to install them.
NeoBundleCheck

" ------------------------------------
" appearance
" ------------------------------------
" general
" let loaded_matchparen = 1
set novisualbell
set t_vb=
set nospell
set lazyredraw

" syntax highlight
set t_Co=256
let g:rehash256 = 1
syntax on
colorscheme molokai
highlight Normal ctermfg=none ctermbg=none
highlight VisualNOS cterm=none term=none
highlight NonText cterm=none ctermfg=none
highlight MatchParen cterm=none ctermbg=236 ctermfg=255

" gutter
set number
highlight LineNr ctermbg=none
set cursorline
highlight cursorline cterm=none ctermbg=none ctermfg=none
highlight cursorlinenr ctermfg=white ctermbg=none

" indent style
set noautoindent
set tabstop=2
set shiftwidth=2
set expandtab

" completion popup
set pumheight=10
set splitbelow  "show Scratch Preview pane on the bottom
" set completeopt=menuone,preview
set completeopt=menuone
set showfulltag
set shortmess+=c "supress 'Pattern not found' message
" augroup close_scratch_preview
"   autocmd!
"   autocmd CompleteDone * :pclose
" augroup END
highlight Pmenu ctermbg=234 ctermfg=255
highlight PmenuSel ctermbg=205 ctermfg=0
highlight PmenuSbar ctermbg=233
highlight PmenuThumb ctermbg=236

" markdown
let g:pandoc#modules#disabled=["spell","chdir","menu","formatting","command","bibliographies", "folding"]
let g:pandoc#syntax#conceal#use=0
"let g:pandoc#syntax#emphases=0
"let g:pandoc#syntax#underline_special=0
let g:pandoc#syntax#codeblocks#embeds#langs = ["javascript", "python", "bash=sh", "zsh=sh", "vim"]

" diff (merge tool)
if &diff 
  set diffopt=filler,context:1000000,horizontal
endif
highlight DiffAdd     ctermfg=154 ctermbg=237
highlight DiffDelete  ctermfg=197 ctermbg=237
highlight DiffChange  ctermfg=222 ctermbg=237
highlight DiffText    ctermfg=16  ctermbg=222

" ------------------------------------
" Auto Completion Popup
" ------------------------------------
" i wish i could use Shougo/deoplete but i noticed some conflict
" 
" mix up omnifunc & neosnippet & custom dictionaries
" ref. http://vi.stackexchange.com/questions/2618/one-pop-up-menu-with-keyword-and-user-defined-completion

function! MixComplete(findstart, base)
  if a:findstart
    return call(&omnifunc, [a:findstart, a:base])
  endif

  let l:matches = []
  let l:omni_matches = call(&omnifunc, [0, a:base])
  if type(l:omni_matches) == 3
    let l:matches += l:omni_matches
  endif

  if a:base == ""
    return l:matches
  endif

  if &dictionary != ""
    let l:keyword_matches = []
    let l:dict = readfile(expand(&dictionary))
    for k in l:dict
      if strpart(k, 0, strlen(a:base)) ==# a:base
        call add(l:matches, {'word': k,
                            \'menu': '(keyword)'})
      endif
    endfor
  endif
    
  let l:snippets = neosnippet#helpers#get_snippets()
  for k in keys(l:snippets)
    if strpart(k, 0, strlen(a:base)) ==# a:base
      call add(l:matches, {'word': k,
                          \'menu': '(snip)',
                          \'info': l:snippets[k]['description']})
    endif
  endfor
  
  return l:matches
endfunction

set omnifunc=syntaxcomplete#Complete
set completefunc=MixComplete
let g:neosnippet#snippets_directory = []
let g:neosnippet#snippets_directory += ["~/.vim/snippets"]


" ------------------------------------
" keybinds
" ------------------------------------
set ttimeout
set ttimeoutlen=10
set timeoutlen=100

set t_ku=[A
set t_kd=[B
set t_kr=[C
set t_kl=[D

set t_so=
set t_me=[m(B

set t_ks=
set t_ke=

if !&diff
  set insertmode
endif

source $VIMRUNTIME/mswin.vim
let g:unite_enable_start_insert=1
set whichwrap+=~

" [show auto completion popup menu & auto select first item without insertion]
" <C-x><C-o> try to show popup
" <C-p>      clear selection of popup item
" if pumvisible() popup appeared
"   <Down> select first item without insertion
" else
"   <C-e> end completion-mode

" <C-Space> is <Nul> in vim
inoremap <silent> <expr> <Nul> '<C-x><C-u><C-p><C-r>=pumvisible() ? "\<lt>Down>" : "\<lt>C-e>"<CR>'

" alphabet keys and dot, space
for k in add(
  \split('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ._','\zs'),
  \'<Space>'
  \)
  exec "inoremap <expr> ".k." '<C-g>u".k."<C-x><C-u><C-p><C-r>=pumvisible() ? \"\\<lt>Down>\" : \"\\<lt>C-e>\"<CR>'"
endfor

" [continue popup on backspace]
inoremap <silent> <expr> <BS> '<BS><C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>'

" [close completion popup menu]
" single quote
inoremap <silent> <expr> ' "<C-g>u\'<C-r>=pumvisible() ? \"\<lt>C-e>\" : \"\"<CR>"

" pipe
inoremap <silent> <expr> \| "<C-g>u\|<C-r>=pumvisible() ? \"\<lt>C-e>\" : \"\"<CR>"

" other symbols
for k in split('!"#$%&(=-~^\@{[+*:<,>?/);}]"`','\zs')
  exec "inoremap <expr> ".k." '<C-g>u".k."<C-r>=pumvisible() ? \"\\<lt>C-e>\" : \"\"<CR>'"
endfor

" for other insert-mode keybinds
" close completion popup menu before key
function! IMapWithClosePopup(before, after, ...)
  let silent = (a:0 == 1 ? "" : "<silent> ")
  exec "inoremap ".silent."<expr> ".a:before." pumvisible() ? \"\\<C-e>".a:after."\" : \"".a:after."\""
endfunction

" [accept item in completion popup menu & expand snippet immediately]
function! ExpandSnip()
  if neosnippet#expandable()
    call feedkeys("\<Plug>(neosnippet_expand)")
  endif
  return ""
endfunction

inoremap <silent><expr> <CR>  pumvisible() ? "\<C-y>\<C-r>=ExpandSnip()\<CR>" : "\<CR>"


" <Tab> ---------------------------
" snip mode       : tabstop jump
" completion mode : accept item
" other modes     : indent
" ---------------------------------

function! JumpSnipOrTab()
  if neosnippet#expandable_or_jumpable()
    call feedkeys("\<Plug>(neosnippet_expand_or_jump)")
    return ""
  else
    return "\<Tab>"
  endif
endfunction

" [accept item in completion popup menu & expand snippet immediately]
inoremap <silent><expr><Tab> pumvisible() ? "\<C-y>\<C-r>=ExpandSnip()\<CR>": "\<C-r>=JumpSnipOrTab()\<CR>"

" sometimes indent/deindent are buggy but roughly ok
" [indent]
noremap <silent> <tab> <C-v>>gvvi<C-g>u

" [deindent]
noremap  <silent> <S-tab> <C-v><gvv$i<C-g>u
inoremap <silent> <S-tab> <C-o><<<C-g>u


" <Esc> ---------------------------
" completion mode : close popup
" snip mode       : clear markers
" after search    : clear highlight
" exists sub-pane : close sub-pane
" 
" sub-pane means,
" 'Location List', 'Scratch Preview'
" ---------------------------------

function! VariousClear() abort
  if pumvisible()
    return "\<C-e>"
  elseif neosnippet#expandable_or_jumpable()
    return "\<C-o>:NeoSnippetClearMarkers\<CR>"
  else
    return "\<C-o>:silent nohlsearch\<CR>\<C-o>:silent lclose\<CR>\<C-o>:silent pclose\<CR>"
  endif
endfunction

noremap <silent> <Esc> :silent nohlsearch<CR>:silent lclose<CR>:silent pclose<CR>i
inoremap <silent><expr> <Esc> VariousClear()


" below code doesnt work
" maybe caused by vim's select-mode default behavior,
" <Esc> key captured for 'leaving select-mode'
" so i cant map <Esc> in select-mode

" snoremap <silent> <Esc> <C-g>vi<C-r>=VariousClear()


set virtualedit=onemore

" [move cursor word-by-word]
" general move
noremap <silent> <C-Right> el
noremap <silent> <C-Left> b
inoremap <silent> <C-Right> <C-o>e<C-o>l
inoremap <silent> <C-Left> <C-o>b

" when entering select-mode
inoremap <silent> <C-S-Right> <C-o>ve<C-g>
inoremap <silent> <C-S-Left> <C-o>vb<C-g>

" while select-mode
snoremap <silent> <C-S-Right> <C-o>e
snoremap <silent> <C-S-Left> <C-o>b

" when leaving select-mode
snoremap <silent> <C-Right> <C-g>ve
snoremap <silent> <C-Left> <C-g>vb

" [delete word]
noremap <silent> <C-Del> de
inoremap <silent> <C-Del> <C-o>:execute "normal! de"<CR>

" [delete backward word]
" <C-BS> is <C-h> in urxvt
noremap <silent> <C-h> db
inoremap <silent> <C-h> <C-o>:execute "normal! db"<CR>

" [Move cursor by display lines when wrapping]
" http://vim.wikia.com/wiki/Move_cursor_by_display_lines_when_wrapping
" http://stackoverflow.com/questions/18678332/gvim-make-s-up-s-down-move-in-screen-lines
" http://stackoverflow.com/questions/3676388/cursor-positioning-when-entering-insert-mode

" general move
nnoremap <silent> <Down> gj
nnoremap <silent> <Up> gk
if has('nvim')
  nnoremap <silent> <Home> g0
  nnoremap <silent> <End> g$
else
  nnoremap <silent> <kHome> g0
  nnoremap <silent> <kEnd> g$
endif
inoremap <silent> <expr> <Down>  pumvisible() ? "\<Down>" : "\<C-o>gj"
inoremap <silent> <expr> <Up>    pumvisible() ? "\<Up>" : "\<C-o>gk"
if has('nvim')
  call IMapWithClosePopup("<Home>",  "\\<C-o>g0")
  call IMapWithClosePopup("<End>",   "\\<C-o>g$")
else
  call IMapWithClosePopup("<kHome>", "\\<C-o>g0")
  call IMapWithClosePopup("<kEnd>",  "\\<C-o>g$")
endif

" when entering select-mode
call IMapWithClosePopup("<S-Down>", "\\<C-o>vgj\\<C-g>")
call IMapWithClosePopup("<S-Up>",   "\\<C-o>vgk\\<C-g>")
call IMapWithClosePopup("<S-Home>", "\\<C-o>vg0\\<C-g>")
call IMapWithClosePopup("<S-End>",  "\\<C-o>vg$\\<C-g>")

" while select-mode
snoremap <silent> <S-Down> <C-O>gj
snoremap <silent> <S-Up> <C-O>gk
snoremap <silent> <S-Home> <C-O>g0
snoremap <silent> <S-End> <C-O>g$

" when leaving select-mode
snoremap <silent> <Down> <C-G>vgj<Esc>i
snoremap <silent> <Up> <C-G>vgk<Esc>i
if has('nvim')
  snoremap <silent> <Home> <C-G>vg0<Esc>i
  snoremap <silent> <End> <C-G>vg$<Esc>i
else
  snoremap <silent> <kHome> <C-G>vg0<Esc>i
  snoremap <silent> <kEnd> <C-G>vg$<Esc>i
endif

" " [scroll by half page]
" noremap <silent> <PageDown> <C-d>
" noremap <silent> <PageUp>   <C-u>
" inoremap <silent> <expr> <PageDown> pumvisible() ? "\<PageDown>" : "\<C-o>\<C-d>"
" inoremap <silent> <expr> <PageUp>   pumvisible() ? "\<PageUp>"   : "\<C-o>\<C-u>"

" [cut/copy/paste]
" Prevent Vim from clearing the clipboard on exit
" http://stackoverflow.com/questions/6453595/prevent-vim-from-clearing-the-clipboard-on-exit
autocmd VimLeave * call system("xsel -ib", getreg('+'))

" [delete selection]
" i remap it for performance.
" already defined <Del> in behave:mswin, 
" but it freezes vim ui for about few seconds after <Del> key
vnoremap <Del> d

" [save]
call IMapWithClosePopup("<C-s>", "\\<C-o>:update\\<CR>")

" [save as]
" i cant use <C-S-s> caused by terminal's limitation
" <F12> is `save as` in MS Office family
" and i use urxvt's keysym <C-S-s> to <F12> in .Xresources
noremap <F12> <C-c>:w 
call IMapWithClosePopup("<F12>", "\\<C-o>:w ", 1)
nnoremap <F12> :w 

" [undo/redo]
vnoremap <C-z> <C-c>u
vnoremap <C-y> <C-c><C-r>
inoremap <expr> <C-z>   pumvisible() ? "\<C-e>\<C-o>u" : "\<C-o>u"

" [open]
noremap <C-o> <C-c>:Unite file_rec -direction=botright<CR>
inoremap <C-o> <C-o>:Unite file_rec -direction=botright<CR>
nnoremap <C-o> :Unite file_rec -direction=botright<CR>

" [quit]
noremap <C-q> <Esc>:confirm quitall<CR>
call IMapWithClosePopup("<C-q>", "\\<C-o>:confirm quitall<CR>", 1)
nnoremap <C-q> :confirm quitall<CR>

" [find]
noremap <C-f> <C-c>/
inoremap <C-f> <Esc>/
nnoremap <C-f> /
nnoremap j nzz
nnoremap k Nzz

" [replace]
noremap <C-r> <C-c>:%s///gc<Left><Left><Left><Left>
inoremap <C-r> <Esc>:%s///gc<Left><Left><Left><Left>
nnoremap <C-r> :%s///gc<Left><Left><Left><Left>

" [reformat]
noremap <C-l> <C-v>=i<C-g>u

" [comment toggle]
" <C-_> means `ctrl+/`
nmap <C-_> <Plug>(caw:i:toggle)
vmap <C-_> <Plug>(caw:i:toggle)
inoremap <C-_> <C-o>:execute "normal \<Plug>(caw:i:toggle)"<CR>

" [new tab]
noremap <C-n> <C-c>:tabnew<CR>
inoremap <C-n> <C-o>:tabnew<CR>
nnoremap <C-n> :tabnew<CR>

" [close current tab]
noremap <C-w> <C-c>:confirm tabclose<CR>
inoremap <C-w> <C-o>:confirm tabclose<CR>
nnoremap <C-w> :confirm tabclose<CR>

" [close other all tabs]
" noremap <C-M-F4> <Esc>:tabonly<CR>
" inoremap <C-M-F4> <Esc>:tabonly<CR>
" nnoremap <C-M-F4> :tabonly<CR>

" [show next tab]
" vim xterm <C-Tab> esc seq
if has('nvim')
  noremap <C-Tab> <C-c>:tabnext<CR>i
  inoremap <C-Tab> <C-o>:tabnext<CR>
  nnoremap <C-Tab> :tabnext<CR>i
else
  noremap [27;5;9~ <C-c>:tabnext<CR>i
  inoremap [27;5;9~ <C-o>:tabnext<CR>
  nnoremap [27;5;9~ :tabnext<CR>i
endif
  
" [show prev tab]
" xterm <C-S-Tab> esc seq
if has('nvim')
  noremap <C-S-Tab> <C-c>:tabNext<CR>i
  inoremap <C-S-Tab> <C-o>:tabNext<CR>
  nnoremap <C-S-Tab> :tabNext<CR>i
else
  noremap [27;6;9~ <C-c>:tabNext<CR>i
  inoremap [27;6;9~ <C-o>:tabNext<CR>
  nnoremap [27;6;9~ :tabNext<CR>i
endif

" TODO: "move tab" keymaps arent working in neovim
" [move tab to left]
" xterm <C-S-PageUp> esc seq
noremap [5;6~ <C-c>:tabmove -1<CR>
inoremap [5;6~ <C-o>:tabmove -1<CR>
nnoremap [5;6~ :tabmove -1<CR>

" [move tab to right]
" xterm <C-S-PageDown> esc seq
noremap [6;6~ <C-c>:tabmove +1<CR>
inoremap [6;6~ <C-o>:tabmove +1<CR>
nnoremap [6;6~ :tabmove +1<CR>

" [enter pane-mode]
let g:submode_always_show_submode = 1
let g:submode_timeoutlen = 1000
call submode#enter_with('pane', 'i', '', '<C-p>')
call submode#enter_with('pane', 'n', '', '<C-p>')

" [resize pane]
call submode#map('pane', 'i', '', '>', '<C-o><C-w>>')
call submode#map('pane', 'i', '', '<', '<C-o><C-w><')
call submode#map('pane', 'i', '', '+', '<C-o><C-w>+')
call submode#map('pane', 'i', '', '-', '<C-o><C-w>-')
call submode#map('pane', 'n', '', '>', '<C-w>>i')
call submode#map('pane', 'n', '', '<', '<C-w><i')
call submode#map('pane', 'n', '', '+', '<C-w>+i')
call submode#map('pane', 'n', '', '-', '<C-w>-i')

" [select(focus) pane]
call submode#map('pane', 'i', '', '<Tab>', '<C-o><C-w>p')
call submode#map('pane', 'n', '', '<Tab>', '<C-w>pi')

" [move pane]
call submode#map('pane', 'i', '', '<Left>', '<C-o><C-w>H')
call submode#map('pane', 'i', '', '<Right>', '<C-o><C-w>L')
call submode#map('pane', 'i', '', '<Up>', '<C-o><C-w>K')
call submode#map('pane', 'i', '', '<Down>', '<C-o><C-w>J')
call submode#map('pane', 'n', '', '<Left>', '<C-w>Hi')
call submode#map('pane', 'n', '', '<Right>', '<C-w>Li')
call submode#map('pane', 'n', '', '<Up>', '<C-w>Ki')
call submode#map('pane', 'n', '', '<Down>', '<C-w>Ji')

" [split pane w/ new file]
call submode#map('pane', 'i', '', '\|', '<Esc>:vnew<CR><C-w>Li')
call submode#map('pane', 'i', '', '=', '<Esc>:new<CR><C-w>Ji')
call submode#map('pane', 'n', '', '\|', ':vnew<CR><C-w>Li')
call submode#map('pane', 'n', '', '=', ':new<CR><C-w>Ji')

" [close pane]
call submode#map('pane', 'i', '', 'x', '<C-o>:confirm quit<CR>')
call submode#map('pane', 'n', '', 'x', ':confirm quit<CR>')

" [diff(merge-tool) mode]
function! MergeFromTop()
  let bufnr = winbufnr(1)
  execute 2 . 'wincmd w'
  execute 'diffget ' . bufnr
  diffupdate
  call feedkeys("zR", "n")
endfunction

function! MergeFromBottom()
  if winnr('$') == 3
    let bufnr = winbufnr(3)
    execute 2 . 'wincmd w'
    execute 'diffget ' . bufnr
  elseif winnr('$') == 2
    let bufnr = winbufnr(2)
    execute 1 . 'wincmd w'
    execute 'diffget ' . bufnr
  endif
  diffupdate
  call feedkeys("zR", "n")
endfunction

if &diff
  nnoremap j ]c
  nnoremap k [c
  nnoremap <silent> <C-S-Down> :call MergeFromTop()<CR>
  nnoremap <silent> <C-S-Up> :call MergeFromBottom()<CR>
  nnoremap <silent> <C-z> u:diffupdate<CR>
  nnoremap <silent> <C-y> <C-R>:diffupdate<CR>
endif

