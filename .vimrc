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

NeoBundle 'vim-jp/vimdoc-ja'
NeoBundle 'xolox/vim-session', {
  \   'depends' : 'xolox/vim-misc',
  \ }

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

NeoBundle 'junegunn/fzf', {
  \ 'build': {
  \   'others': '$HOME/.vim/bundle/fzf/install'
  \   }
  \ }
NeoBundle 'junegunn/fzf.vim'

" NeoBundle 'kana/vim-submode'
" NeoBundle 'Shougo/unite.vim'
" NeoBundle 'Shougo/unite-outline'
" NeoBundle 'Shougo/neomru.vim'
NeoBundle 'tyru/caw.vim.git'
NeoBundle 'airblade/vim-gitgutter'
" NeoBundle 'vheon/vim-cursormode'

" color scheme
NeoBundle 'tomasr/molokai'

NeoBundle 'alunny/pegjs-vim'
"NeoBundle 'vim-pandoc/vim-pandoc'
"NeoBundle 'vim-pandoc/vim-pandoc-syntax'

call neobundle#end()

" Required:
filetype plugin indent on

" If there are uninstalled bundles found on startup,
" this will conveniently prompt you to install them.
NeoBundleCheck

autocmd BufNewFile,BufReadPost *.pegjs set filetype=pegjs

" ------------------------------------
" appearance
" ------------------------------------
" general
" let loaded_matchparen = 1
set novisualbell
set t_vb=
set nospell
set lazyredraw
set updatetime=500

" syntax highlight
if has('nvim')
  " let $NVIM_TUI_ENABLE_TRUE_COLOR=1
else
  set t_Co=256
endif
let g:rehash256 = 1
syntax on
colorscheme molokai
highlight Normal ctermfg=none ctermbg=none guifg=none guibg=none
highlight VisualNOS cterm=none term=none gui=none
highlight NonText cterm=none ctermfg=none gui=none
highlight MatchParen cterm=none ctermbg=236 ctermfg=255 guibg=gray guifg=white

" gutter
set number
set numberwidth=1
highlight LineNr ctermbg=none guibg=none
let g:gitgutter_realtime = 1
let g:gitgutter_eager = 1
let g:gitgutter_sign_column_always = 1
let g:gitgutter_max_signs = 9999
set cursorline
highlight cursorline cterm=none ctermbg=none ctermfg=none gui=none guibg=none guifg=none
highlight cursorlinenr ctermfg=white ctermbg=none guifg=white guibg=none

" statusline
highlight StatusLine ctermfg=170 ctermbg=0 guifg=#d75fd7 guibg=#000000
highlight StatusLineNC ctermfg=255 ctermbg=0 guifg=#eeeeee guibg=#000000

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
highlight Pmenu ctermbg=234 ctermfg=255 guibg=#1c1c1c guifg=#eeeeee
highlight PmenuSel ctermbg=205 ctermfg=0 guibg=#ff5faf guifg=#000000
highlight PmenuSbar ctermbg=233 guibg=#121212
highlight PmenuThumb ctermbg=236 guibg=#303030

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
highlight DiffAdd     ctermfg=154 ctermbg=237 guifg=#afff00 guibg=#3a3a3a
highlight DiffDelete  ctermfg=197 ctermbg=237 guifg=#ff005f guibg=#3a3a3a
highlight DiffChange  ctermfg=222 ctermbg=237 guifg=#ffd787 guibg=#3a3a3a
highlight DiffText    ctermfg=16  ctermbg=222 guifg=#000000 guibg=#ffd787

" terminal-mode
if has('nvim')
  highlight TermCursor ctermfg=251 ctermbg=0 guifg=#c6c6c6 guibg=#000000
  highlight TermCursorNC ctermfg=251 ctermbg=0 guifg=#c6c6c6 guibg=#000000

  let g:terminal_color_0="#1B1D1E"
  let g:terminal_color_1="#FF0044"
  let g:terminal_color_2="#A6E22E"
  let g:terminal_color_3="#f4bf75"
  let g:terminal_color_4="#266C98"
  let g:terminal_color_5="#AC0CB1"
  let g:terminal_color_6="#AE81FF"
  let g:terminal_color_7="#CCCCCC"
  let g:terminal_color_8="#808080"
  let g:terminal_color_9="#F92672"
  let g:terminal_color_10="#A6E22E"
  let g:terminal_color_11="#E6DB74"
  let g:terminal_color_12="#7070F0"
  let g:terminal_color_13="#D63AE1"
  let g:terminal_color_14="#66D9EF"
  let g:terminal_color_15="#F8F8F2"
endif

if &term =~ "mlterm"
  let &t_ti .= "\e[?6h\e[?69h"
  let &t_te .= "\e7\e[?69l\e[?6l\e8"
  let &t_CV = "\e[%i%p1%d;%p2%ds"
  let &t_CS = "y"
endif

" ------------------------------------
" Session
" ------------------------------------
" ref. http://qiita.com/take/items/3be8908bbf4ad5b49e46
let s:local_session_directory = xolox#misc#path#merge(getcwd(), '.vimsessions')
if isdirectory(s:local_session_directory)
  let g:session_directory = s:local_session_directory
  let g:session_autosave = 'yes'
  let g:session_autoload = 'yes'
  let g:session_autosave_periodic = 1
else
  let g:session_autosave = 'no'
  let g:session_autoload = 'no'
endif
unlet s:local_session_directory
let g:session_autosave_silent=1

" ------------------------------------
" Git cooperation
" ------------------------------------
" ref. http://vim-jp.org/vim-users-jp/2011/03/12/Hack-206.html
set autoread
function! UpdateWindow() abort
  checktime
  if &buftype==''
    let buffer_id = winbufnr(0)
    let file = expand('#' . buffer_id . ':p')
    if !empty(file)
      call gitgutter#process_buffer(buffer_id, 1)
    endif
  endif
endfunction
augroup vimrc-checktime
  autocmd!
  autocmd WinEnter * :call UpdateWindow()
augroup END


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
let g:neosnippet#scope_aliases = {}
let g:neosnippet#scope_aliases['vim'] = 'vim,vim-functions'
let g:neosnippet#disable_runtime_snippets = {'_' : 1}


" ------------------------------------
" Auto Mode Change
" ------------------------------------
" ref. http://stackoverflow.com/questions/6593299/change-from-insert-to-normal-mode-when-switching-to-another-tab

set insertmode

augroup mode_select
  autocmd!
  autocmd BufReadPost,BufNewFile,BufEnter * call ModeSelectBufEnter()
augroup END

function! ModeSelectBufEnter()
  if !&diff && !&readonly && &modifiable
    set insertmode
    startinsert
  else
    set noinsertmode
    stopinsert
  endif
endfunction


" ------------------------------------
" Neovim remote
" ------------------------------------
" grep in zsh -> append loclist in nvim

function! RestoreQuickfixCursor() abort
  if &buftype == 'quickfix' && exists('w:last_cursor')
    call setpos(".", w:last_cursor)
  endif
endfunction

function! SaveQuickfixCursor() abort
  if &buftype == 'quickfix'
    let w:last_cursor = getpos(".")
  endif
endfunction

augroup loclist_cursor
  autocmd!
  autocmd BufEnter * call RestoreQuickfixCursor()
  autocmd BufLeave * call SaveQuickfixCursor()
augroup END

function! AppendLocList(loclist_bufnr, entries) abort
  let l:loclist_winnr = bufwinnr(a:loclist_bufnr)
  let l:current_winnr = winnr()
  if l:loclist_winnr == l:current_winnr
    let w:last_cursor = getpos(".")
  endif
  call setloclist(l:loclist_winnr, eval(a:entries), 'a')
  if l:loclist_winnr == l:current_winnr
    call setpos(".", w:last_cursor)
  endif
endfunction

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

" [accept item in completion popup menu, without expand snippet]
inoremap <silent><expr> <CR> pumvisible() ? "\<C-y>" : "\<CR>"


" <Tab> ---------------------------
" snip mode       : tabstop jump
" completion mode : accept item
" other modes     : indent
" ---------------------------------

function! ExpandSnip()
  if neosnippet#expandable()
    call feedkeys("\<Plug>(neosnippet_expand)")
  endif
  return ""
endfunction

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


function! IndentOrJump() range abort
  " <C-v> normal-mode -> visual-mode
  " gv    restore selection
  " <C-g> visual-mode -> select-mode
  execute "normal! \<C-v>gv\<C-g>"
  
  if a:firstline != a:lastline
    " multi-line selection, indent
    " <C-v> normal-mode -> visual-mode
    " V     visual-mode -> visual-line-mode
    " >     right-shift
    " gv    restore selection
    " <C-g> visual-line-mode -> select-line-mode
    execute "normal! \<C-v>V>gv\<C-g>"
  else
    call JumpSnipOrTab()
  endif
endfunction

" [indent selection lines || jump tabstop from placeholder selection]
snoremap <silent><Tab> <C-g>:call IndentOrJump()<CR>

" [deindent selection lines]
snoremap <silent> <S-tab> <C-v>V<gv<C-g>
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
    return "\<C-o>:silent nohlsearch|:silent lclose|:silent pclose\<CR>"
  endif
endfunction

noremap <silent> <Esc> :silent nohlsearch \| lclose \| pclose<CR>
nnoremap <silent> <Esc> :silent nohlsearch \| lclose \| pclose<CR>i
inoremap <silent><expr> <Esc> VariousClear()


" below code doesnt work
" maybe caused by vim's select-mode default behavior,
" <Esc> key captured for 'leaving select-mode'
" so i cant map <Esc> in select-mode

" snoremap <silent> <Esc> <C-g>vi<C-r>=VariousClear()


set virtualedit=onemore

function! BeforeWord() abort
  let b:default_keyword=&iskeyword
  setlocal iskeyword=@,48-57
  return ""
endfunction

function! AfterWord() abort
  execute "setlocal iskeyword=".b:default_keyword
  return ""
endfunction

" [move cursor word-by-word]
" general move
noremap <silent><expr> <C-Right> BeforeWord()."el".AfterWord()
noremap <silent><expr> <C-Left> BeforeWord()."b".AfterWord()
inoremap <silent><expr> <C-Right> "\<C-o>".BeforeWord()."e\<C-o>l".AfterWord()
inoremap <silent><expr> <C-Left> "\<C-o>".BeforeWord()."b".AfterWord()

" when entering select-mode
inoremap <silent><expr> <C-S-Right> "\<C-o>".BeforeWord()."ve".AfterWord()."\<C-g>"
inoremap <silent><expr> <C-S-Left> "\<C-o>".BeforeWord()."vb".AfterWord()."\<C-g>"

" while select-mode
snoremap <silent><expr> <C-S-Right> "\<C-o>".BeforeWord()."e".AfterWord()
snoremap <silent><expr> <C-S-Left> "\<C-o>".BeforeWord()."b".AfterWord()

" when leaving select-mode
snoremap <silent><expr> <C-Right> "\<C-g>".BeforeWord()."ve".AfterWord()
snoremap <silent><expr> <C-Left> "\<C-g>".BeforeWord()."vb".AfterWord()

" [delete word]
noremap <silent><expr> <C-Del> BeforeWord()."de".AfterWord()
inoremap <silent><expr> <C-Del> "\<C-o>".BeforeWord()."de".AfterWord()

" [delete backward word]
" <C-BS> is <C-h> in urxvt
noremap <silent><expr> <C-h> BeforeWord()."db".AfterWord()
inoremap <silent><expr> <C-h> "\<C-o>".BeforeWord()."db".AfterWord()


" <Home> --------------------------
"     console.log('ayp')
" ^   ^        ^
" 3   2        1
" 
" when hit <Home> & cursor on and after 2 (like 1), cursor will go to 2.
" when hit <Home> & cursor in range 2-3, cursor will go to 3.
" ---------------------------------
function! GetGoHomeCmd() abort
  return indent('.') >= col('.') - 1 ? "g0" : "g^"
endfunction

" [Move cursor by display lines when wrapping]
" http://vim.wikia.com/wiki/Move_cursor_by_display_lines_when_wrapping
" http://stackoverflow.com/questions/18678332/gvim-make-s-up-s-down-move-in-screen-lines
" http://stackoverflow.com/questions/3676388/cursor-positioning-when-entering-insert-mode

" general move
nnoremap <silent> <Down> gj
nnoremap <silent> <Up> gk
if has('nvim')
  nnoremap <silent><expr> <Home> GetGoHomeCmd()
  nnoremap <silent> <End> g$
else
  nnoremap <silent><expr> <kHome> GetGoHomeCmd()
  nnoremap <silent> <kEnd> g$
endif
inoremap <silent> <expr> <Down>  pumvisible() ? "\<Down>" : "\<C-o>gj"
inoremap <silent> <expr> <Up>    pumvisible() ? "\<Up>" : "\<C-o>gk"
if has('nvim')
  call IMapWithClosePopup("<Home>", "\\<C-o>:execute printf(\\\"normal! %s\\\", GetGoHomeCmd())\\<CR>")
  call IMapWithClosePopup("<End>",  "\\<C-o>g$")
else
  call IMapWithClosePopup("<kHome>","\\<C-o>:execute printf(\\\"normal! %s\\\", GetGoHomeCmd())\\<CR>")
  call IMapWithClosePopup("<kEnd>", "\\<C-o>g$")
endif

" when entering select-mode
call IMapWithClosePopup("<S-Down>", "\\<C-o>vgj\\<C-g>")
call IMapWithClosePopup("<S-Up>",   "\\<C-o>vgk\\<C-g>")

call IMapWithClosePopup("<S-Home>", "\\<C-o>:execute printf(\\\"normal! v%s<C-g>\\\", GetGoHomeCmd())\\<CR>")
call IMapWithClosePopup("<S-End>",  "\\<C-o>vg$\\<C-g>")

" while select-mode
snoremap <silent> <S-Down> <C-O>gj
snoremap <silent> <S-Up> <C-O>gk
snoremap <silent><expr> <S-Home> "\<C-o>".GetGoHomeCmd()
snoremap <silent> <S-End> <C-O>g$

" when leaving select-mode
snoremap <silent> <Down> <C-G>vgj<Esc>i
snoremap <silent> <Up> <C-G>vgk<Esc>i
if has('nvim')
  snoremap <silent><expr> <Home> "\<C-G>v".GetGoHomeCmd()."\<Esc>i"
  snoremap <silent> <End> <C-G>vg$<Esc>i
else
  snoremap <silent><expr> <kHome> "\<C-G>v".GetGoHomeCmd()."\<Esc>i"
  snoremap <silent> <kEnd> <C-G>vg$<Esc>i
endif

" [scroll page up/down]
" on 1st page, <PageUp> should move cursor to 1st line.
" on last page, <PageDown> should move cursor to last line,
" and it shouldnt show after eof (`~` lines).
" ref. http://vimrc-dissection.blogspot.se/2009/02/fixing-pageup-and-pagedown.html
set scrolloff=3
noremap <silent> <PageUp> 1000<C-u>
noremap <silent> <PageDown> 1000<C-d>
snoremap <silent> <PageUp> <C-g>v1000<C-u>
snoremap <silent> <PageDown> <C-g>v1000<C-d>
snoremap <silent> <S-PageUp> <C-o>1000<C-u>
snoremap <silent> <S-PageDown> <C-o>1000<C-d>
inoremap <silent><expr> <PageUp> pumvisible() ? "\<PageUp>" : "\<C-o>1000\<C-u>"
inoremap <silent><expr> <PageDown> pumvisible() ? "\<PageDown>" : "\<C-o>1000\<C-d>"
call IMapWithClosePopup("<S-PageUp>",   "\\<C-o>v1000\\<C-u>\\<C-g>")
call IMapWithClosePopup("<S-PageDown>", "\\<C-o>v1000\\<C-d>\\<C-g>")

" [scroll viewport up/down]
" like a mouse wheel, scroll 3 lines.
" if possible, without change cursor position
noremap  <silent> <C-Down> 3<C-e>
inoremap <silent> <C-Down> <C-o>3<C-e>
noremap  <silent> <C-Up> 3<C-y>
inoremap <silent> <C-Up> <C-o>3<C-y>

" [cut/copy/paste]
" Prevent Vim from clearing the clipboard on exit
" http://stackoverflow.com/questions/6453595/prevent-vim-from-clearing-the-clipboard-on-exit
autocmd VimLeave * call system("xsel -ib", getreg('+'))

" paste in select-mode, force back to insert-mode
" ref. $VIMRUNTIME/autoload/paste.vim
execute 'snoremap <script> <C-v> '. paste#paste_cmd['i']

" [save]
call IMapWithClosePopup("<C-s>", "\\<C-o>:update\\<CR>")

" [save as]
" ref. http://vim.wikia.com/wiki/User_input_from_a_script
function! SaveAs()
  call inputsave()
  let filename = input('Save As > File Name: ', expand("%"))
  call inputrestore()
  if filename == ""
    echoerr "empty filename, aborted."
  else
    execute ":saveas ".filename
  endif
endfunction

" i cant use <C-S-s> caused by terminal's limitation
" <F12> is `save as` in MS Office family
" and i use urxvt's keysym <C-S-s> to <F12> in .Xresources
noremap  <F12> <C-c>:call SaveAs()<CR>
inoremap <F12> <C-o>:call SaveAs()<CR>
snoremap <F12> <C-g>v:call SaveAs()<CR>
nnoremap <F12> :call SaveAs()<CR>

" [undo/redo]
vnoremap <C-z> <C-c>u
vnoremap <C-y> <C-c><C-r>
inoremap <expr> <C-z>   pumvisible() ? "\<C-e>\<C-o>u" : "\<C-o>u"

" [open]
function! FilesFromRoot() abort
  call fzf#vim#files("/", {'options': '-q '.getcwd()[1:], 'down': '~40%'})
endfunction
noremap <C-o> <C-c>:call FilesFromRoot()<CR>
inoremap <C-o> <C-o>:call FilesFromRoot()<CR>
nnoremap <C-o> :call FilesFromRoot()<CR>

" [quit]
noremap <C-q> <Esc>:confirm quitall<CR>
call IMapWithClosePopup("<C-q>", "\\<C-o>:confirm quitall<CR>", 1)
nnoremap <C-q> :confirm quitall<CR>

" [find]
set ignorecase
set noincsearch
noremap <C-f> <C-c>/
inoremap <C-f> <Esc>/
nnoremap <C-f> /
snoremap <C-f> <C-g><C-\><C-n>/\%V
nnoremap n nzz
nnoremap N Nzz

" [replace]
noremap <C-r> <C-c>:%s///gc<Left><Left><Left><Left>
inoremap <C-r> <Esc>:%s///gc<Left><Left><Left><Left>
nnoremap <C-r> :%s///gc<Left><Left><Left><Left>
snoremap <C-r> <C-g>:s/\%V\%V//gc<Left><Left><Left><Left><Left><Left><Left>

" [reformat]
noremap <C-l> <C-v>=i<C-g>u

" [comment toggle]
" <C-_> means `ctrl+/`
nmap <C-_> <Plug>(caw:i:toggle)
vmap <C-_> <Plug>(caw:i:toggle)
inoremap <C-_> <C-o>:execute "normal \<Plug>(caw:i:toggle)"<CR>

" [jump to line]
" ref. http://vim.wikia.com/wiki/Jump_to_a_line_number
" ref. http://vim.wikia.com/wiki/User_input_from_a_script
function! JumpToLine()
  call inputsave()
  let lineno = input('Jump to Line > Number: ')
  call inputrestore()
  execute "normal! ".lineno."G"
endfunction

noremap  <C-g> <C-c>:call JumpToLine()<CR>
inoremap <C-g> <C-o>:call JumpToLine()<CR>
snoremap <C-g> <C-g>v:call JumpToLine()<CR>
nnoremap <C-g> :call JumpToLine()<CR>

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

function! MapAllMode(lhs, rhs) abort
  execute "noremap \<silent> ".a:lhs." \<C-c>".a:rhs
  execute "inoremap \<silent> ".a:lhs." \<C-o>".a:rhs
  execute "snoremap \<silent> ".a:lhs." \<C-g>".a:rhs
  execute "nnoremap \<silent> ".a:lhs." ".a:rhs
  if has('nvim')
    execute "tnoremap \<silent> ".a:lhs." \<C-\\>\<C-n>".a:rhs
  endif
endfunction

" [resize pane]
call MapAllMode("\<lt>M-+>", "\<lt>C-w>+")
call MapAllMode("\<lt>M-->", "\<lt>C-w>-")

" [select(focus) pane]
" http://vim.wikia.com/wiki/Mapping_fast_keycodes_in_terminal_Vim#2a._Mappings
map <Esc>[27;3;9~ <M-Tab>
call MapAllMode("\<lt>M-Tab>", "\<lt>C-w>w")
call MapAllMode("\<lt>M-S-Tab>", "\<lt>C-w>W")
call MapAllMode("\<lt>M-Up>", "\<lt>C-w>k")
call MapAllMode("\<lt>M-Down>", "\<lt>C-w>j")
call MapAllMode("\<lt>M-Right>", "\<lt>C-w>l")
call MapAllMode("\<lt>M-Left>", "\<lt>C-w>h")

" [move pane]
" ref. http://stackoverflow.com/questions/2586984/how-can-i-swap-positions-of-two-open-files-in-splits-in-vim

function! GutterToggle() abort
  if &buftype == ''
    set number
  else
    set nonumber
  endif
endfunction

augroup gutter_toggle
  autocmd!
  autocmd BufWinEnter * :call GutterToggle()
augroup END

function! SwapBuffer(targetWinnr) abort
  let l:targetWinnr = a:targetWinnr
  if l:targetWinnr == ""
    call inputsave()
    let l:targetWinnr = input('Swap with > Pane No.: ')
    call inputrestore()
    if l:targetWinnr == ""
      echoerr "empty number, aborted."
      return
    endif
  endif
  let l:currentBufnr = bufnr("%")
  execute 'hide buf' winbufnr(l:targetWinnr)
  execute l:targetWinnr . " wincmd w"
  execute 'hide buf' l:currentBufnr
endfunction

function! SwapBufferArrow(direction) abort
  let l:currentWinnr = winnr()
  execute 'wincmd '.a:direction
  let l:targetWinnr = winnr()
  if l:currentWinnr == l:targetWinnr
    return
  endif
  execute l:currentWinnr.' wincmd w'
  call SwapBuffer(l:targetWinnr)
endfunction

map <Esc>[1;7A <M-C-Up>
call MapAllMode("\<lt>M-C-Up>", ":call SwapBufferArrow('k')\<lt>CR>")
map <Esc>[1;7B <M-C-Down>
call MapAllMode("\<lt>M-C-Down>", ":call SwapBufferArrow('j')\<lt>CR>")
map <Esc>[1;7C <M-C-Right>
call MapAllMode("\<lt>M-C-Right>", ":call SwapBufferArrow('l')\<lt>CR>")
map <Esc>[1;7D <M-C-Left>
call MapAllMode("\<lt>M-C-Left>", ":call SwapBufferArrow('h')\<lt>CR>")

" [split pane w/ new file]
set splitbelow
set splitright

" alt-pipe(|)
call MapAllMode("\<lt>M-\\|>", ":vnew\<lt>CR>")
" alt-equal(=)
call MapAllMode("\<lt>M-=>", ":new\<lt>CR>")

" [close pane]
call MapAllMode("\<lt>M-x>", ":confirm quit\<lt>CR>")

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

" [neovim terminal-mode]
if has('nvim')
  source ~/.vim/nvim-term-keysym.vim
  tnoremap <Esc> <C-\><C-n>
  tnoremap <C-l> <C-\><C-n>
  noremap <C-t> :term<CR>
  inoremap <C-t> <Esc>:term<CR>
  tmap <C-v> <C-\><C-n><C-v>i
endif

