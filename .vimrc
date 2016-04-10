set encoding=utf-8
scriptencoding utf-8

" Note: Skip initialization for vim-tiny or vim-small.
if 0 | endif

" ref. http://qiita.com/jiminko/items/f4b337ab41db751388f7
if has('vim_starting')
  set runtimepath+=~/.vim/plugged/vim-plug
  if !isdirectory(expand('~/.vim/plugged/vim-plug'))
    echo 'install vim-plug...'
    if has('win32')
      call system('mkdir ' . $HOME . '\.vim\plugged\vim-plug')
    else
      call system('mkdir -p ~/.vim/plugged/vim-plug')
    endif
    call system('git clone https://github.com/junegunn/vim-plug.git '
          \	. $HOME . '/.vim/plugged/vim-plug/autoload')
  end
endif

let g:eclim_filetypes = ['scala', 'java', 'php', 'ruby']

call plug#begin('~/.vim/plugged')
Plug 'junegunn/vim-plug', {'dir': '~/.vim/plugged/vim-plug/autoload'}
Plug 'vim-jp/vimdoc-ja'
Plug 'xolox/vim-misc' | Plug 'xolox/vim-session'
if has('nvim')
  Plug 'neovim/node-host', {'do': 'npm install'}
endif
Plug 'tomtom/tcomment_vim'
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-sleuth'
if !has('win32')
  Plug 'junegunn/fzf', {'do': '$HOME/.vim/plugged/fzf/install'}
  Plug 'junegunn/fzf.vim'
endif
Plug 'junegunn/vader.vim'
Plug 'vim-jp/vital.vim'
Plug 'haya14busa/vital-safe-string'
Plug 'haya14busa/vital-vimlcompiler'
Plug 'haya14busa/vital-power-assert'
Plug 'Shougo/neosnippet.vim'
Plug 'Shougo/neco-vim',
      \ {'dir': '~/.vim/bundle-custom/neco-vim',
      \ 'frozen': 1, 'for': 'vim'}
Plug 'Valodim/vim-zsh-completion',
      \ {'dir': '~/.vim/bundle-custom/vim-zsh-completion',
      \ 'frozen': 1, 'for': 'zsh'}
Plug 'dansomething/vim-eclim' , {'for': g:eclim_filetypes}
Plug 'ternjs/tern_for_vim',
      \ {'do': 'npm install', 'for': 'javascript'}
Plug 'davidhalter/jedi-vim',
      \ {'do': 'git submodule update --init', 'for': 'python'}
Plug 'shawncplus/phpcomplete.vim'
Plug 'othree/yajs.vim', {'for': 'javascript'}
Plug 'othree/es.next.syntax.vim', {'for': 'javascript'}
Plug 'digitaltoad/vim-pug', {'for': 'pug'}
Plug 'wavded/vim-stylus', {'for': ['stylus', 'pug']}
Plug 'tobyS/vmustache' | Plug 'tobyS/pdv', {'for': 'php'}
Plug 'jwalton512/vim-blade'
Plug 'alunny/pegjs-vim', {'for': 'pegjs'}
Plug 'elzr/vim-json', {'for': 'json'}
Plug 'mrk21/yaml-vim'
Plug 'vim-pandoc/vim-pandoc'
Plug 'vim-pandoc/vim-pandoc-syntax'
Plug 'othree/html5.vim'
Plug 'hail2u/vim-css3-syntax'
Plug 'othree/csscomplete.vim'
Plug 'ap/vim-css-color'

Plug 'luochen1990/rainbow'
Plug 'dpy-/molokai'
call plug#end()

filetype plugin indent on

" ref. http://qiita.com/b4b4r07/items/fa9c8cceb321edea5da0
let s:plug = {"plugs": get(g:, 'plugs', {})}
function! s:plug.is_installed(name)
  return has_key(self.plugs, a:name) ? isdirectory(self.plugs[a:name].dir) : 0
endfunction

function! s:plug.check_installation()
  if empty(self.plugs)
    return
  endif

  let list = []
  for [name, spec] in items(self.plugs)
    if !isdirectory(spec.dir)
      call add(list, spec.uri)
    endif
  endfor

  if len(list) > 0
    let unplugged = map(list, 'substitute(v:val, "^.*github\.com/\\(.*/.*\\)\.git$", "\\1", "g")')

    " Ask whether installing plugs like NeoBundle
    echomsg 'Not installed plugs: ' . string(unplugged)
    if confirm('Install plugs now?', "yes\nNo", 2) == 1
      PlugInstall
    endif
  endif
endfunction

augroup check-plug
  autocmd!
  autocmd VimEnter * if !argc() | call s:plug.check_installation() | endif
augroup END


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
elseif !has('gui_running')
  set t_Co=256
endif
if !has('gui_running')
  let g:rehash256 = 1
endif
syntax on
let g:molokai_italic = 0
colorscheme molokai
source ~/.vim/highlight.vim

" add random colors to braces
let g:rainbow_active = 1
let g:rainbow_conf = {
    \   'guifgs': ['#FFFFFF', '#ffafff', '#ffaf87', '#afffaf', '#87d7ff', '#d7afff'],
    \   'ctermfgs': [255, 219, 216, 226, 157, 117, 183],
    \   'operators': '_,_',
    \   'parentheses': ['start=/(/ end=/)/ fold', 'start=/\[/ end=/\]/ fold', 'start=/{/ end=/}/ fold'],
    \   'separately': {
    \       '*': {},
    \       'vim': {
    \           'parentheses': ['start=/(/ end=/)/', 'start=/\[/ end=/\]/', 'start=/{/ end=/}/ fold', 'start=/(/ end=/)/ containedin=vimFuncBody', 'start=/\[/ end=/\]/ containedin=vimFuncBody', 'start=/{/ end=/}/ fold containedin=vimFuncBody'],
    \       },
    \       'html': 0,
    \       'css': 0,
    \       'json': 0,
    \       'blade': 0
    \   }
    \}

" gutter
set number
set numberwidth=1
let g:gitgutter_realtime = 1
let g:gitgutter_eager = 1
let g:gitgutter_sign_column_always = 1
let g:gitgutter_max_signs = 9999
let g:gitgutter_diff_args = '--ignore-all-space'
set cursorline

" vertical split line
set fillchars+=vert:\ 

highlight link TrailSpace Error
highlight link WideSpace Error

" ref. http://vim.wikia.com/wiki/Highlight_unwanted_spaces#Highlighting_with_the_syntax_command
function! SetWhiteSpaceSyntax() abort
  " highlight as error trailing whitespaces,
  " but exclude comment blocks & empty lines
  syntax match LeadSpace excludenl /^\s\+$/ containedin=ALL
  syntax match TrailSpace excludenl /\s\+$/ containedin=ALLBUT,.*Comment.*,LeadSpace

  " highlight japanese wide-width space, everywhere
  syntax match WideSpace excludenl /　/ containedin=ALL
endfunction
augroup whitespace_syntax
  autocmd!
  autocmd Syntax * call SetWhiteSpaceSyntax()
augroup END

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

" markdown
let g:pandoc#modules#disabled=["spell","chdir","menu","formatting","command","bibliographies", "folding", "completion"]
let g:pandoc#modules#enabled=["metadata","keyboard","toc","hypertext"]
let g:pandoc#syntax#conceal#use=0
"let g:pandoc#syntax#emphases=0
"let g:pandoc#syntax#underline_special=0
let g:pandoc#syntax#codeblocks#embeds#langs = ["javascript", "python", "bash=sh", "zsh=sh", "vim"]

" json
let g:vim_json_syntax_conceal = 0

" diff (merge tool)
if &diff 
  set diffopt=filler,context:1000000,horizontal
endif

" terminal-mode
if has('nvim')
  highlight TermCursor ctermfg=251 ctermbg=0 guifg=#c6c6c6 guibg=#000000
  highlight TermCursorNC ctermfg=251 ctermbg=0 guifg=#c6c6c6 guibg=#000000
  source ~/.vim/nvim-term-colors.vim
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

if has('win32')
  set undodir=~/.vimundo/
  set nobackup
endif

" ------------------------------------
" Git cooperation
" ------------------------------------
" ref. http://vim-jp.org/vim-users-jp/2011/03/12/Hack-206.html
set autoread
function! UpdateWindow() abort
  checktime
endfunction
augroup vimrc-checktime
  autocmd!
  autocmd BufEnter * :call UpdateWindow()
augroup END


" ------------------------------------
" Auto Completion Popup
" ------------------------------------
" i wish i could use Shougo/deoplete but i noticed some conflict
" 
" mix up omnifunc & neosnippet & custom dictionaries
" ref. http://vi.stackexchange.com/questions/2618/one-pop-up-menu-with-keyword-and-user-defined-completion

function! SortCandidates(l, r) abort
  let l = a:l.pos
  let r = a:r.pos
  return l == r ? 0 : l > r ? 1 : -1
endfunction
function! MatchCandidates(candidates, cur_text) abort
  let l:candidates = a:candidates
  let l:matches = []
  for l:k in l:candidates
    if type(l:k) == type("")
      let l:candidate = {"word": l:k}
    elseif type(k) == type({})
      let l:candidate = l:k
    endif
    unlet l:k
    if !exists('l:candidate')
      continue
    endif
    
    " ignore special symbols & ignore case
    let l:candidate.pos = stridx(
          \ tolower(substitute(l:candidate.word, '[^a-zA-Z0-9]', '', 'g')),
          \ tolower(substitute(a:cur_text, '[^a-zA-Z0-9]', '', 'g'))
          \)
    if l:candidate.pos == -1
      continue
    endif
    call add(l:matches, l:candidate)
    unlet l:candidate
  endfor
  return sort(l:matches, "SortCandidates")
endfunction
function! MixComplete(findstart, base)
  if a:findstart
    return call(&omnifunc, [a:findstart, a:base])
  endif

  let l:matches = []
  let l:omni_matches = call(&omnifunc, [0, a:base])
  if type(l:omni_matches) == type({}) && has_key(l:omni_matches, 'words')
    let l:matches += l:omni_matches.words
  elseif type(l:omni_matches) == type([])
    let l:matches += l:omni_matches
  endif

  if a:base == ""
    return l:matches
  endif

  if &dictionary != ""
    let l:dict = readfile(expand(&dictionary))
    let l:keyword_matches = MatchCandidates(l:dict, a:base)
    call map(l:keyword_matches,
          \ '{"word": v:val.word, "menu": "(keyword)"}'
          \)
    let l:matches += l:keyword_matches
  endif
    
  let l:snippets = neosnippet#helpers#get_snippets()
  let l:snippet_matches = MatchCandidates(keys(l:snippets), a:base)
  call map(l:snippet_matches,
        \ '{"word": v:val.word, '
        \ . '"menu": "(snip)", '
        \ . '"info": l:snippets[v:val.word]["description"]}'
        \)
  let l:matches += l:snippet_matches
  
  return l:matches
endfunction

augroup completedone
  autocmd!
  " `v:completed_item` is readonly var.
  " i want to consume it, so copy to buffer local var
  autocmd CompleteDone * let b:completed_item = v:completed_item
augroup END

set omnifunc=syntaxcomplete#Complete
set completefunc=MixComplete
let g:neosnippet#snippets_directory = []
let g:neosnippet#snippets_directory += ["~/.vim/snippets"]
let g:neosnippet#scope_aliases = {}
let g:neosnippet#scope_aliases['vim'] = 'vim,vim-functions'
let g:neosnippet#disable_runtime_snippets = {'_' : 1}
let g:funcsnips = {}

augroup setomniafterfiletype
  autocmd!
  autocmd FileType stylus setlocal omnifunc=CompleteStylus
  autocmd FileType pug setlocal omnifunc=CompleteJade
augroup END

let g:EclimCompletionMethod = 'omnifunc'
let g:EclimProjectProblemsUpdateOnSave = 1
function! EclimComplete(findstart, base)
  if &filetype == 'php'
    let l:compfunc='phpcomplete#CompletePHP'
  else
    let l:compfunc = 'syntaxcomplete#Complete'
  endif
  
  if eclim#PingEclim(0) && index(g:eclim_filetypes, &filetype) >= 0
    let l:compfunc='eclim#' . &filetype . '#complete#CodeComplete'
    
    " cancel completion before eclim gathers global candidates
    " cuz its very slow
    if &filetype == 'php'
      let l:pattern = '\%(new\s\+\|\s\+\\\)$'
      if a:findstart
        if getline('.')[0: col('.') - 2] =~ l:pattern
          return -1
        endif
      else
        if getline('.') . a:base =~ l:pattern
          return []
        endif
      endif
    endif
  endif
  return call(l:compfunc, [a:findstart, a:base])
endfunction

function! s:start_eclimd() abort
  if !has('nvim') || eclim#PingEclim(0) || exists('g:eclimd_will_start')
    return
  endif
  let l:eclipse_project_dir = ''
  let l:dirstack = split(expand("<afile>:p:h"), '/')
  let l:dirstack_len = len(l:dirstack)
  for l:i in range(l:dirstack_len - 1, 0, -1)
    let l:dir = '/' . join(l:dirstack[0: l:i], '/')
    let l:project_file_path = l:dir . '/.project'
    if filereadable(l:project_file_path)
      let l:eclipse_project_dir = l:dir
      break
    endif
  endfor
  if l:eclipse_project_dir == ""
    return
  endif
  let g:eclimd_will_start = 1
  call system('$ECLIPSE_HOME/eclimd 2>&1 1>/dev/null &')
endfunction

augroup eclim
  autocmd!
  autocmd FileType java,php call s:start_eclimd() | setlocal omnifunc=EclimComplete
augroup END

" ------------------------------------
" Indent Styles
" ------------------------------------

set noautoindent
augroup indentexpr
  autocmd!
  autocmd FileType stylus,pug setlocal indentexpr=
  autocmd FileType stylus setlocal autoindent
augroup END

" ref. http://rcmdnk.github.io/blog/2014/07/14/computer-vim/
set breakindent
augroup breakindent
  autocmd!
  autocmd BufEnter * set breakindentopt=min:20,shift:0
augroup END

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
" Cursor Vertical Guide
" ------------------------------------
"     console.log('ayp')
" ^   ^        ^
" 3   2        1
" 
" when cursor on and after 2 (like 1), hide vertical guide line
" when cursor in range 2-3, show vertical guide line
" ---------------------------------
set nocursorcolumn
function! VerticalGuide() abort
  if &buftype != "" || &filetype == 'markdown'
    setlocal nocursorcolumn
    return
  endif
  if indent('.') >= virtcol('.') - 1
    setlocal cursorcolumn
  else
    setlocal nocursorcolumn
  endif
endfunction

augroup vertguide
  autocmd!
  autocmd CursorMoved,CursorMovedI,WinEnter * call VerticalGuide()
  autocmd WinLeave,BufWinLeave * setlocal nocursorcolumn
  if has('nvim')
    autocmd TermOpen * setlocal nocursorcolumn
  endif
augroup END

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
" Testing
" ------------------------------------
let g:__vital_power_assert_config = {'__debug__': 1}

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
let g:neosnippet#disable_select_mode_mappings = 0
let g:unite_enable_start_insert=1
set whichwrap+=~

" [disable unwanted keymaps]
inoremap <C-\> <Nop>

" [show auto completion popup menu & auto select first item without insertion]
" <C-x><C-o> try to show popup
" <C-p>      clear selection of popup item
" if pumvisible() popup appeared
"   <Down> select first item without insertion
" else
"   <C-e> end completion-mode

inoremap <silent> <C-Space> <C-x><C-u><C-p><C-r>=pumvisible() ? "\<lt>Down>" : "\<lt>C-e>"<CR>
" <C-Space> is <Nul> in vim
inoremap <silent> <Nul> <C-x><C-u><C-p><C-r>=pumvisible() ? "\<lt>Down>" : "\<lt>C-e>"<CR>

" alphabet keys and dot, space
for k in add(
  \split('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ._!"#$%&(=-~^\@[+*:<,?/`','\zs'),
  \'<Space>'
  \)
  execute 'inoremap <silent> ' . k . ' <C-g>u' . k
        \ . '<C-x><C-u><C-p><C-r>=pumvisible()'
        \ . ' ? "\<lt>Down>" : "\<lt>C-e>"<CR>'
endfor

" single quote
inoremap <silent> ' <C-g>u'<C-x><C-u><C-p><C-r>=pumvisible() ? "\<lt>Down>" : "\<lt>C-e>"<CR>

" [continue popup on backspace]
inoremap <silent> <BS> <C-g>u<BS><C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>

" [close completion popup menu]
" pipe
inoremap <silent> \| <C-r>=pumvisible() ? "\<lt>C-e>" : ""<CR><C-g>u\|

" other symbols
for k in split('{>);}]','\zs')
  execute 'inoremap <silent><expr>' . k
        \ . ' (pumvisible() ? "\<lt>C-e>" : "") . '
        \ . '"\<C-g>u' . k . '"'
endfor

" <C-CR>
inoremap <silent> <F23> <C-r>=pumvisible() ? "\<lt>C-e>" : ""<CR><C-g>u<CR>

" for other insert-mode keybinds
" close completion popup menu before key
function! IMapWithClosePopup(before, after, ...)
  let silent = (a:0 == 1 ? "" : "<silent> ")
  execute 'inoremap ' . silent . '<expr> ' . a:before
        \ . ' (pumvisible() ? "\<lt>C-e>" : "") . "' . a:after . '"'
endfunction

" <CR> ----------------------------
" completion mode : accept item w/o expanding snippet
" other modes     : add new line w/o removing indent
" ---------------------------------
inoremap <silent><expr> <CR>
      \ pumvisible()
      \ ? "\<C-y>\<C-o>:let b:completed_item={}\<CR>"
      \ : "\<C-g>u\<CR>x\<BS>"


" <Tab> ---------------------------
" snip mode       : tabstop jump
" completion mode : accept item
" other modes     : indent
" ---------------------------------

function! ExpandSnipGetResult()
  if exists("b:expandfunc")
    let l:result = call(function(b:expandfunc), [])
    let b:completed_item = {}
    if l:result
      return 1
    endif
  endif
  if neosnippet#expandable()
    call feedkeys("\<Plug>(neosnippet_expand)")
    return 1
  endif
  return 0
endfunction

function! ExpandSnip() abort
  call ExpandSnipGetResult()
  return ""
endfunction

function! JumpSnipOrTab()
  if ExpandSnipGetResult()
    return ""
  elseif neosnippet#jumpable()
    call feedkeys("\<Plug>(neosnippet_jump)")
    return ""
  else
    return "\<Tab>"
  endif
endfunction

" [accept item in completion popup menu & expand snippet immediately]
nmap <silent><expr><Tab> neosnippet#jumpable()
      \ ? "i\<Plug>(neosnippet_jump)" : ""
inoremap <silent><expr><Tab> pumvisible()
      \ ? "\<C-y>\<C-r>=ExpandSnip()\<CR>"
      \ : "\<C-r>=JumpSnipOrTab()\<CR>"

" [indent selection lines]
" <C-g>      select-mode -> visual-mode
" <Esc>      visual-mode -> normal-mode
" `<         move cursor to first char in last selection
" g^         move cursor to first visible char on current line
" v          start visual selection
" `>         move cursor to last char in last selection
" >          right shift selection
" `<g^v`>    to follow selection, repeat once again
" "=&sw<CR>l move cursor one 'shiftwidth' rightwards
" o          move cursor to first char in current selection
" <C-g>      visual-mode -> select-mode
snoremap <silent> <Tab> <C-g><Esc>`<g^v`>>`<g^v`>"=&sw<CR>lo<C-g>

" [deindent selection lines]
snoremap <silent> <S-tab> <C-g><Esc>`<g^v`><`<g^v`>"=&sw<CR>ho<C-g>
inoremap <silent> <S-tab> <C-o>g^<C-o><<<C-g>u


" <Esc> ---------------------------
" completion mode : close popup
" snip mode       : clear markers
" after search    : clear highlight
" exists sub-pane : close sub-pane
" select mode     : exit select mode
" 
" sub-pane means,
" 'Location List', 'Scratch Preview'
" ---------------------------------

function! ClearSearch() abort
  call matchdelete(b:ring)
  set nohlsearch
  " let @/ =
endfunction

function! VariousClear() abort
  if pumvisible()
    return "\<C-e>"
  elseif neosnippet#expandable_or_jumpable()
    return "\<C-o>:NeoSnippetClearMarkers\<CR>"
  else
    return "\<C-o>:silent! call ClearSearch()|:silent lclose|:silent pclose\<CR>"
  endif
endfunction

noremap <silent> <Esc> :silent! call ClearSearch()<CR>:silent lclose \| pclose<CR>
nnoremap <silent> <Esc> :silent! call ClearSearch()<CR>:silent lclose \| pclose<CR>i
inoremap <silent><expr> <Esc> VariousClear()
snoremap <silent> <Esc> <C-g>vi

set virtualedit=onemore

" get next/prev cursor char (multibyte support! cool)
" ref. http://d.hatena.ne.jp/eagletmt/20100623/1277289728
function! s:next_cursor_char(n) abort
  return matchstr(getline('.'), '.', col('.')-1, a:n)
endfunction

function! s:prev_cursor_char(n)
  let chars = split(getline('.')[0 : col('.')-1], '\zs')
  let len = len(chars)
  if a:n >= len
    return ''
  else
   return chars[len(chars) - a:n - 1]
  endif
endfunction


" <C-Left/Right> ------------------
" ayapi's original smart word move
" stop on camelCase upper char
" stop on hiragana/katakana/others
" ---------------------------------

let s:char_groups = {
      \"symbol": "[\\u0021-\\u002F\\u003A-\\u0040\\u005B-\\u0060\\u007B-\\u007E]",
      \"upper": "[A-Z]",
      \"lower": "[a-z]",
      \"number": "[0-9]",
      \"blank": "[\\x20\\x09]",
      \"hiragana": "[\\u3040-\\u309F]",
      \"katakana": "[\\u30A0-\\u30FF]",
      \"other": "[^a-zA-Z0-9\\x20\\x09\\u0021-\\u002F\\u003A-\\u0040\\u005B-\\u0060\\u007B-\\u007E\\u3040-\\u309F\\u30A0-\\u30FF]"
      \}

function! s:get_char_group(char) abort
  for l:item in items(s:char_groups)
    if a:char =~# l:item[1]
      let l:group = l:item
      break
    endif
  endfor
  return l:group
endfunction

function! s:get_char_by_direction(direction) abort
  return a:direction == 'h'
        \ ? s:prev_cursor_char(1)
        \ : s:next_cursor_char(1)
endfunction

set whichwrap+=h,l

function! GoWord(direction, ...) abort
  if a:0 == 1 && a:1 == 1
    " when entering select-mode
    silent! normal! v
  endif
  
  if a:0 == 2 && a:2 == 1
    " while select-mode, need `gv`(restore selection)
    silent! normal! gv
  endif
  
  let l:from_char = s:get_char_by_direction(a:direction)
  if l:from_char == ""
    if a:direction == "h"
      " now cursor on the start of line
      if line(".") > 1
        " go to end of the prev line (virtualedit onemore position)
        silent! normal! gkg$
      endif
    else
      " now cursor on the end of line
      " go to start of the next line
      silent! normal! l
    endif
    return
  endif
  
  let l:from_group = s:get_char_group(l:from_char)

  " forwarding camelCase
  if a:direction == "l" && l:from_group[0] == "upper"
    let l:tmp_next_group = s:get_char_group(s:next_cursor_char(2))
    if l:tmp_next_group[0] == "lower"
      " camelCase camelCase
      "      ^^  ^
      "      12  3
      " cursor on 1, so forward to 2 now. (to forward to 3 later)
      silent! normal! l
      let l:from_group = l:tmp_next_group
    endif
  endif
  
  while 1
    execute "silent! normal! ".a:direction
    let l:to_char = s:get_char_by_direction(a:direction)
    if l:to_char == "" || l:to_char !~# l:from_group[1]
      break
    endif
  endwhile
  
  if l:to_char == ""
    return
  endif
  
  " backwarding camelCase, go to upper char
  if a:direction == "h" && l:from_group[0] == "lower"
    let l:to_group = s:get_char_group(l:to_char)
    if l:to_group[0] == "upper"
      " camelCase camelCase
      "      ^^
      "      21
      " cursor on 1, so backward to 2 now
      silent! normal! h
    endif
  endif
endfunction

" [move cursor word-by-word]
" general move
noremap <silent> <C-Right> :call GoWord("l")<CR>
noremap <silent> <C-Left> :call GoWord("h")<CR>
call IMapWithClosePopup("<C-Right>","\\<C-o>:call GoWord(\\\"l\\\")\\<CR>")
call IMapWithClosePopup("<C-Left>", "\\<C-o>:call GoWord(\\\"h\\\")\\<CR>")

" when entering select-mode
call IMapWithClosePopup("<C-S-Right>","\\<C-o>:call GoWord(\\\"l\\\", 1)\\<CR>\\<C-g>")
call IMapWithClosePopup("<C-S-Left>", "\\<C-o>:call GoWord(\\\"h\\\", 1)\\<CR>\\<C-g>")

" while select-mode
snoremap <silent> <C-S-Right> <C-g>:call GoWord("l",0,1)<CR><C-g>
snoremap <silent> <C-S-Left>  <C-g>:call GoWord("h",0,1)<CR><C-g>

" when leaving select-mode
snoremap <silent> <C-Right> <C-g>v:call GoWord("l")<CR>
snoremap <silent> <C-Left>  <C-g>v:call GoWord("h")<CR>

" [delete word]
noremap <silent> <C-Del> :call GoWord("l",1)<CR><C-g><Del>
call IMapWithClosePopup("<C-Del>","\\<C-o>:call GoWord(\\\"l\\\", 1)\\<CR>\\<C-g>\\<Del>")

" [delete backward word]
" <C-BS> is <C-h> in urxvt
noremap <silent> <C-h> :call GoWord("h",1)<CR><C-g><Del>
call IMapWithClosePopup("<C-h>","\\<C-o>:call GoWord(\\\"h\\\", 1)\\<CR>\\<C-g>\\<Del>")
" for gvim
noremap <silent> <C-BS> :call GoWord("h",1)<CR><C-g><Del>
call IMapWithClosePopup("<C-BS>","\\<C-o>:call GoWord(\\\"h\\\", 1)\\<CR>\\<C-g>\\<Del>")

" <Home> --------------------------
"     console.log('ayp')
" ^   ^        ^
" 3   2        1
" 
" when hit <Home> & cursor on and after 2 (like 1), cursor will go to 2.
" when hit <Home> & cursor in range 2-3, cursor will go to 3.
" ---------------------------------
function! GetGoHomeCmd() abort
  return indent('.') >= virtcol('.') - 1 ? "g0" : "g^"
endfunction

" <End> ---------------------------
" when current line is short than right edge of window
"                            |
" console.log('ayp')         |
"                   ^        |
" cursor should go to here
" 
" when current line is LONG than right edge of window (soft wrapped)
"                            |
" console.log(util.inspect(ay|
" p, false,2,true));         |
" ^                          |
" cursor should go to here
" ---------------------------------

function! GoEnd(cmd) range
  execute ":silent! normal! ".a:cmd
  if virtcol(".") < virtcol("$")
    silent! normal! l
  endif
  endfunction

" [Move cursor by display lines when wrapping]
" http://vim.wikia.com/wiki/Move_cursor_by_display_lines_when_wrapping
" http://stackoverflow.com/questions/18678332/gvim-make-s-up-s-down-move-in-screen-lines
" http://stackoverflow.com/questions/3676388/cursor-positioning-when-entering-insert-mode

" general move
nnoremap <silent> <Down> gj
nnoremap <silent> <Up> gk
nnoremap <silent><expr> <Home> GetGoHomeCmd()
nnoremap <silent> <End> :call GoEnd("g$")<CR>
nnoremap <silent><expr> <kHome> GetGoHomeCmd()
nnoremap <silent> <kEnd> :call GoEnd("g$")<CR>

inoremap <silent> <expr> <Down>  pumvisible() ? "\<Down>" : "\<C-o>gj"
inoremap <silent> <expr> <Up>    pumvisible() ? "\<Up>" : "\<C-o>gk"
call IMapWithClosePopup("<Home>", "\\<C-o>:execute printf(\\\"normal! %s\\\", GetGoHomeCmd())\\<CR>")
call IMapWithClosePopup("<End>", "\\<C-o>:call GoEnd(\\\"g$\\\")\\<CR>")
call IMapWithClosePopup("<kHome>","\\<C-o>:execute printf(\\\"normal! %s\\\", GetGoHomeCmd())\\<CR>")
call IMapWithClosePopup("<kEnd>", "\\<C-o>:call GoEnd(\\\"g$\\\")\\<CR>")

" when entering select-mode
call IMapWithClosePopup("<S-Down>", "\\<C-o>vgj\\<C-g>")
call IMapWithClosePopup("<S-Up>",   "\\<C-o>vgk\\<C-g>")

call IMapWithClosePopup("<S-Home>", "\\<C-o>:execute printf(\\\"normal! v%s<C-g>\\\", GetGoHomeCmd())\\<CR>")
call IMapWithClosePopup("<S-End>", "\\<C-o>:call GoEnd(\\\"vg$\\\")\\<CR>\\<C-g>")

" while select-mode
snoremap <silent> <S-Down> <C-O>gj
snoremap <silent> <S-Up> <C-O>gk
snoremap <silent><expr> <S-Home> "\<C-o>".GetGoHomeCmd()
snoremap <silent> <S-End> <C-g>:call GoEnd("gvg$")<CR><C-g>

" when leaving select-mode
snoremap <silent> <Down> <Esc>gj
snoremap <silent> <Up> <Esc>gk
snoremap <silent><expr> <Home> "\<C-G>v`<".GetGoHomeCmd()
snoremap <silent> <End> <C-g>v:call GoEnd("`>g$")<CR>
snoremap <silent><expr> <kHome> "\<C-G>v`<".GetGoHomeCmd()
snoremap <silent> <kEnd> <C-g>v:call GoEnd("`>g$")<CR>

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

" [delete]
" to avoid going to normal-mode
snoremap <BS>  x<BS>
snoremap <Del> x<BS>

" [cut/copy/paste]
" to prevent freezing on nvim exit, i use custom clipboard provider
" i think it caused by the following commit
" https://github.com/neovim/neovim/commit/49f04179888944943f0266cd77810e467f9d68ef
if has('nvim')
  source ~/.vim/clipboard.vim
endif

" Prevent Vim from clearing the clipboard on exit
" http://stackoverflow.com/questions/6453595/prevent-vim-from-clearing-the-clipboard-on-exit
" cant use this on nvim
if !has('nvim')
  augroup xsel
    autocmd!
    autocmd VimLeave * call system("xsel -ib", getreg('+'))
  augroup END
endif

" convert indent before paste, and select pasted text
function! ConvertIndentPaste() abort
  let l:after_indent = &expandtab ? repeat(' ', &shiftwidth) : "\t"
  let l:clipboard = getreg('+')
  let l:converted = ConvertIndent(l:clipboard, l:after_indent)
  call setreg('j', l:converted, 'c')
  normal! "jgP
  if l:converted =~ '[\r?\n]'
    execute "normal! `[v`]l\<C-g>"
  endif
  startinsert
endfunction

function! MapConvertIndentPaste() abort
  noremap  <silent><buffer> <C-v> :call ConvertIndentPaste()<CR>
  inoremap <silent><buffer> <C-v> <C-g>u<C-o>:call ConvertIndentPaste()<CR>
  snoremap <silent><buffer> <C-v> <C-g>d:call ConvertIndentPaste()<CR>
endfunction

if has('nvim')
  augroup convertpaste
    autocmd!
    autocmd FileType * if &buftype == '' | call MapConvertIndentPaste() | endif
  augroup END
endif

" confirm message
" ref. https://github.com/saihoooooooo/dotfiles/
function! s:Confirm(msg)
  return input(printf('%s [y/N]: ', a:msg)) =~? '^y\%[es]$'
endfunction

" write file with `sudo`
" ref. http://stackoverflow.com/questions/2600783/how-does-the-vim-write-with-sudo-trick-work
function! WriteWithSudo(filename) abort
  if s:Confirm('"'.a:filename.'" isnt writable. Write with sudo?')
    " redraw prompt
    " ref. http://vim.1045645.n5.nabble.com/Clear-input-prompt-after-input-is-entered-td5717719.html
    redraw
    execute ":silent write !sudo tee ".a:filename
    set nomodified
    execute ":silent file! ".a:filename
  endif
endfunction

" [save]
function! Save() abort
  let l:filename = expand("%")
  if l:filename == ""
    call SaveAs()
  elseif filewritable(expand("%:p")) != 1 &&
        \ filewritable(expand("%:p:h")) != 2
    call WriteWithSudo(l:filename)
  else
    update
  endif
endfunction

noremap  <C-s> <C-c>:call Save()<CR>
inoremap <C-s> <C-o>:call Save()<CR>
snoremap <C-s> <C-g>v:call Save()<CR>
nnoremap <C-s> :call Save()<CR>

" [save as]
" ref. http://vim.wikia.com/wiki/User_input_from_a_script
function! SaveAs()
  call inputsave()
  let l:inputpath = input('Save As > File Name: ', expand("%"))
  call inputrestore()
  if l:inputpath == ""
    echoerr "empty filename, aborted."
    return
  endif
  
  " ref. http://vim.1045645.n5.nabble.com/dirname-td1185590.html
  let l:savepath = fnamemodify(expand(l:inputpath), ":p")
  let l:savedir = fnamemodify(expand(l:inputpath), ":p:h")

  let l:need_sudo = 0
  if glob(l:savepath) != "" " file exists
    if filewritable(l:savepath) != 1
      let l:need_sudo = 1
    endif
  else
    if !isdirectory(l:savedir) " dir not exists
      " TODO: should `mkdir -p`... ?
    else
      if filewritable(l:savedir) != 2
        let l:need_sudo = 1
      endif
    endif
  endif
  
  if l:need_sudo
    call WriteWithSudo(l:savepath)
    return
  endif
  
  try
    execute ":saveas ".l:savepath
  catch /E13: File exists/
    if s:Confirm('"'.l:savepath.'" already exists. Overwrite?')
      execute ":saveas! ".l:savepath
    endif
  endtry
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
snoremap <C-z> <C-c>u
snoremap <C-y> <C-c><C-r>
inoremap <expr> <C-z>   pumvisible() ? "\<C-e>\<C-o>u" : "\<C-o>u"

" [open]
if !has('win32')
  function! FilesFromRoot() abort
    call fzf#vim#files("/", {'options': '-q '.getcwd()[1:], 'down': '~40%'})
  endfunction
  noremap <C-o> <C-c>:call FilesFromRoot()<CR>
  inoremap <C-o> <C-o>:call FilesFromRoot()<CR>
  nnoremap <C-o> :call FilesFromRoot()<CR>
endif

" [quit]
noremap <C-q> <Esc>:confirm quitall<CR>
call IMapWithClosePopup("<C-q>", "\\<C-o>:confirm quitall<CR>", 1)
nnoremap <C-q> :confirm quitall<CR>


" Set cursor colour different when on a highlighted word
" ref. http://vi.stackexchange.com/questions/2761/set-cursor-colour-different-when-on-a-highlighted-word
function! SearchHighlight()
  silent! call matchdelete(b:ring)
  let b:ring = matchadd('IncSearch', '\c\%#' . @/, 101)
endfunction

function! SearchNext()
  try
    execute 'normal! '.'Nn'[v:searchforward].'zz'
  catch /E385:/
    echohl ErrorMsg | echo "E385: search hit BOTTOM without match for: " . @/ | echohl None
  endtry
  call SearchHighlight()
endfun

function! SearchPrev()
  try
    execute 'normal! '.'nN'[v:searchforward].'zz'
  catch /E384:/
    echohl ErrorMsg | echo "E384: search hit TOP without match for: " . @/ | echohl None
  endtry
  call SearchHighlight()
endfunction

" immediately after search started with Enter, highlight first match
function! SearchStart()
  autocmd! search_start
  augroup! search_start
  set hlsearch
  normal zz
  call SearchHighlight()
endfunction

function! AddSearchStartHook() abort
  augroup search_start
    autocmd!
    autocmd CursorMoved <buffer> call SearchStart()
  augroup END
endfunction

" [find]
set ignorecase
set noincsearch
noremap <C-f> <C-c>:call AddSearchStartHook()<CR>/
inoremap <C-f> <Esc>:call AddSearchStartHook()<CR>/
nnoremap <C-f> :call AddSearchStartHook()<CR>/
snoremap <C-f> <C-g><C-\><C-n>:call AddSearchStartHook()<CR>/\%V
nnoremap <silent> n :call SearchNext()<CR>
nnoremap <silent> N :call SearchPrev()<CR>

" [replace]
noremap <C-r> <C-c>:%s///gc<Left><Left><Left><Left>
inoremap <C-r> <Esc>:%s///gc<Left><Left><Left><Left>
nnoremap <C-r> :%s///gc<Left><Left><Left><Left>
snoremap <C-r> <C-g>:s/\%V\%V//gc<Left><Left><Left><Left><Left><Left><Left>

" for replace with new line
" <C-Enter> = <F23> in my keysym
cnoremap <F23> <C-v><C-m>

" [revert]
" <C-S-r> = <F11> in my keysym
inoremap <F11> <C-o>:GitGutterRevertHunk<CR>
nnoremap <F11> :GitGutterRevertHunk<CR>

" [jump git hunk]
" ref. http://vim.wikia.com/wiki/Capture_ex_command_output
function! s:Warning(msg)
  redraw
  echohl WarningMsg
  echo a:msg
  echohl None
  let v:warningmsg = a:msg
endfunction

function! CirculateNextHunk () abort
  echo ""
  let l:hunks = gitgutter#hunk#hunks()
  if len(l:hunks) == 0
    call s:Warning("buffer has any git hunks")
    return
  endif
  
  redir => m
    silent call gitgutter#hunk#next_hunk(1)
  redir END
  
  if empty(m)
    normal! zz
    return
  endif
  
  if m =~ 'No more hunks'
    normal! gg
    silent call gitgutter#hunk#next_hunk(1)
    normal! zz
    call s:Warning("jump hit BOTTOM. Continueing at TOP")
  endif
endfunction

function! CirculatePrevHunk () abort
  echo ""
  let l:hunks = gitgutter#hunk#hunks()
  if len(l:hunks) == 0
    call s:Warning("buffer has any hunks")
    return
  endif
  
  redir => m
    silent call gitgutter#hunk#prev_hunk(1)
  redir END
  
  if empty(m)
    normal! zz
    return
  endif
  
  if m =~ 'No previous hunks'
    normal! G
    silent call gitgutter#hunk#prev_hunk(1)
    normal! zz
    call s:Warning("jump hit Top. Continueing at BOTTOM")
  endif
endfunction

nnoremap <silent> m :call CirculateNextHunk()<CR>
nnoremap <silent> M :call CirculatePrevHunk()<CR>

" [reformat]
noremap <C-l> <C-v>=i<C-g>u

" [comment toggle]
let g:tcommentMaps = 0
let g:tcommentModeExtra = '#'
if has("gui_running")
  noremap <C-\> :TComment<CR>
  vnoremap <C-\> :TCommentMaybeInline<CR>
  inoremap <C-\> <C-o>:TComment<CR>
else
  " <C-_> means `ctrl+/`
  noremap <C-_> :TComment<CR>
  vnoremap <C-_> :TCommentMaybeInline<CR>
  inoremap <C-_> <C-o>:TComment<CR>
endif

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

" toggle gutter
function! SetGutter() abort
  if !exists('b:gutter_state')
    let b:gutter_state = &buftype == ''
  endif
  
  if b:gutter_state == 0
    setlocal nonumber
    setlocal norelativenumber
  elseif b:gutter_state == 1
    setlocal number
    setlocal norelativenumber
  elseif b:gutter_state == 2
    setlocal nonumber
    setlocal relativenumber
  endif
endfunction

augroup set_gutter
  autocmd!
  autocmd BufWinEnter * :call SetGutter()
augroup END

function! ToggleGutter() abort
  if !exists('b:gutter_state')
    let b:gutter_state = &buftype != ''
  else
    let b:gutter_state += 1
    if b:gutter_state > 2
      let b:gutter_state = 0
    endif
  endif
  call SetGutter()
endfunction

noremap  <silent> <C-M-g> <C-c>:call ToggleGutter()<CR>
inoremap <silent> <C-M-g> <C-o>:call ToggleGutter()<CR>
snoremap <silent> <C-M-g> <C-g>v:call ToggleGutter()<CR>
nnoremap <silent> <C-M-g> :call ToggleGutter()<CR>

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
if has('nvim') || has('gui_running')
  noremap <C-Tab> <C-c>:tabnext<CR>
  inoremap <C-Tab> <C-o>:tabnext<CR>
  nnoremap <C-Tab> :tabnext<CR>
else
  noremap [27;5;9~ <C-c>:tabnext<CR>
  inoremap [27;5;9~ <C-o>:tabnext<CR>
  nnoremap [27;5;9~ :tabnext<CR>
endif
  
" [show prev tab]
" xterm <C-S-Tab> esc seq
if has('nvim') || has('gui_running')
  noremap <C-S-Tab> <C-c>:tabNext<CR>
  inoremap <C-S-Tab> <C-o>:tabNext<CR>
  nnoremap <C-S-Tab> :tabNext<CR>
else
  noremap [27;6;9~ <C-c>:tabNext<CR>
  inoremap [27;6;9~ <C-o>:tabNext<CR>
  nnoremap [27;6;9~ :tabNext<CR>
endif

" TODO: "move tab" keymaps arent working in neovim
" [move tab to left]
if has('nvim') || has('gui_running')
  noremap <C-S-PageUp> <C-c>:tabmove -1<CR>
  inoremap <C-S-PageUp> <C-o>:tabmove -1<CR>
  nnoremap <C-S-PageUp> :tabmove -1<CR>
else
" xterm <C-S-PageUp> esc seq
  noremap [5;6~ <C-c>:tabmove -1<CR>
  inoremap [5;6~ <C-o>:tabmove -1<CR>
  nnoremap [5;6~ :tabmove -1<CR>
endif

" [move tab to right]
if has('nvim') || has('gui_running')
  noremap <C-S-PageDown> <C-c>:tabmove +1<CR>
  inoremap <C-S-PageDown> <C-o>:tabmove +1<CR>
  nnoremap <C-S-PageDown> :tabmove +1<CR>
else
  " xterm <C-S-PageDown> esc seq
  noremap [6;6~ <C-c>:tabmove +1<CR>
  inoremap [6;6~ <C-o>:tabmove +1<CR>
  nnoremap [6;6~ :tabmove +1<CR>
endif
  
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

function! StashLoclist() abort
  let l:start_bufnr = bufnr("%")
  let l:main_win = {}
  let l:start_win_loclist = getloclist(0)
  if &buftype == 'quickfix'
    if len(l:start_win_loclist) " maybe loclist
      " main window is above from loclist in my vim
      let l:loclist_last_cursor = getwinvar(0, 'last_cursor', 0)
      let l:loclist_title = getwinvar(0, 'quickfix_title', 0)
      wincmd k
      let l:above_win_loclist = getloclist(0)
      if l:start_win_loclist == l:above_win_loclist
        let l:main_win.loclist = {}
        let l:main_win.loclist.data = l:above_win_loclist
        let l:main_win.loclist.cursor = l:loclist_last_cursor
        let l:main_win.loclist.title = l:loclist_title
        lclose
      else
        " back to loclist
        wincmd p
        " maybe loclist is alone so close it
        lclose
      endif
    else
      "maybe quickfix
    endif
  else
    if len(l:start_win_loclist)
      " normal buffer has loclist
      let l:main_win.loclist = {}
      let l:main_win.loclist.data = l:start_win_loclist
      
      " go to window below, is it loclist?
      let l:main_winnr = winnr()
      wincmd j
      if l:main_winnr != winnr()
            \ && &buftype == 'quickfix'
            \ && getloclist(0) == l:start_win_loclist
        let l:main_win.loclist.cursor = getwinvar(0, 'last_cursor', 0)
        let l:main_win.loclist.title = getwinvar(0, 'quickfix_title', 0)
      endif

      " back to main window
      execute l:main_winnr.' wincmd w'

      if has_key(l:main_win.loclist, 'cursor')
        lclose
      endif
    endif
  endif
  let l:main_win.bufnr = bufnr("%")
  return l:main_win
endfunction

function! RestoreLoclist(stashed) abort
  if !has_key(a:stashed, 'loclist')
    call setloclist(0, [])
    return
  endif
  call setloclist(0, a:stashed.loclist.data)
  if has_key(a:stashed.loclist, 'cursor')
    lopen
    if type(a:stashed.loclist.cursor) == 3
      let w:last_cursor = a:stashed.loclist.cursor
      call RestoreQuickfixCursor()

      let w:quickfix_title = a:stashed.loclist.title
    endif
  endif
endfunction

function! SwapBuffer(from, to) abort
  let l:from = a:from
  let l:to = a:to
  
  if l:from.bufnr == l:to.bufnr
    return
  endif
  
  let l:from.winnr = bufwinnr(l:from.bufnr)
  let l:to.winnr = bufwinnr(l:to.bufnr)
  execute l:from.winnr " wincmd w"
  execute 'hide buf' l:to.bufnr
  execute l:to.winnr " wincmd w"
  execute 'hide buf' l:from.bufnr
  
  let l:winnr_dict = {}
  let l:winnr_dict[bufwinnr(l:from.bufnr)] = l:from
  let l:winnr_dict[bufwinnr(l:to.bufnr)] = l:to
  
  execute bufwinnr(l:winnr_dict[max(keys(l:winnr_dict))]['bufnr'])." wincmd w"
  call RestoreLoclist(l:winnr_dict[max(keys(l:winnr_dict))])
  execute bufwinnr(l:winnr_dict[min(keys(l:winnr_dict))]['bufnr'])." wincmd w"
  call RestoreLoclist(l:winnr_dict[min(keys(l:winnr_dict))])
  
  execute bufwinnr(l:from.bufnr)." wincmd w"
endfunction

function! SwapBufferArrow(direction) abort
  let l:from = StashLoclist()
  execute 'wincmd '.a:direction
  let l:to = StashLoclist()
  call SwapBuffer(from, to)
endfunction

map <Esc>[1;7A <M-C-Up>
call MapAllMode("\<lt>M-C-Up>", ":call SwapBufferArrow('k')\<lt>CR>")
map <Esc>[1;7B <M-C-Down>
call MapAllMode("\<lt>M-C-Down>", ":call SwapBufferArrow('j')\<lt>CR>")
map <Esc>[1;7C <M-C-Right>
call MapAllMode("\<lt>M-C-Right>", ":call SwapBufferArrow('l')\<lt>CR>")
map <Esc>[1;7D <M-C-Left>
call MapAllMode("\<lt>M-C-Left>", ":call SwapBufferArrow('h')\<lt>CR>")


" lay aside buffer
" 
" ~~~~~~~~~~~~~~~~~~
" before -> after
" -----     -----
" 1 |3      1 |3
"   |--     --|
" --|4      2 |--
" 2 |--     --|4
"   |5*     5*|
" -----     -----
" ~~~~~~~~~~~~~~~~~~
" * = current buffer
"
" but if 2 is empty [no name] buffer,
" 
" ~~~~~~~~~~~~~~~~~~
" before -> after
" -----     -----
" 1 |3      1 |3
"   |--       |
" --|4      --|--
" 2 |--     5*|4
"   |5*       |
" -----     -----
" ~~~~~~~~~~~~~~~~~~

function! LayAsideBufferArrow(direction) abort
  let l:from = {}
  let l:from.bufnr = bufnr('%')
  let l:from.winnr = winnr()
  execute 'wincmd '.a:direction

  if &buftype == 'quickfix'
    new
  else
    let l:stop_win_winnr = winnr()
    let l:stop_win_loclist = getloclist(0)
    if len(l:stop_win_loclist)
      " go to window below, is it loclist?
      wincmd j
      if l:stop_win_winnr != winnr()
          \ && &buftype == 'quickfix'
          \ && getloclist(0) == l:stop_win_loclist
        " loclist is visible. insert new pane below
        new
      else
        " loclist not visible
        wincmd p
        new
      endif
    elseif expand('%') == '' && line('$') == 1 && getline(1) == ''
      " empty new buffer, reuse this
    else
      new
    endif
  endif
  
  " now cursor is in destination pane
  let l:to = StashLoclist()
  execute bufwinnr(l:from.bufnr).' wincmd w'
  unlet l:from
  let l:from = StashLoclist()
  
  call SwapBuffer(from, to)

  " destination is empty so close it
  execute bufwinnr(l:to.bufnr)." wincmd w"
  close
  execute bufwinnr(l:from.bufnr).' wincmd w'
endfunction

map <Esc>[1;8C <M-C-S-Right>
call MapAllMode("\<lt>M-C-S-Right>", ":call LayAsideBufferArrow('l')\<lt>CR>")
map <Esc>[1;8D <M-C-S-Left>
call MapAllMode("\<lt>M-C-S-Left>", ":call LayAsideBufferArrow('h')\<lt>CR>")


" [split pane w/ new file]
set splitbelow
set splitright

" alt-pipe(|)
call MapAllMode("\<lt>M-\\|>", ":vnew\<lt>CR>")
" alt-equal(=)
call MapAllMode("\<lt>M-=>", ":new\<lt>CR>")

" [close pane]
call MapAllMode("\<lt>M-x>", ":confirm quit\<lt>CR>")

" [help]
function! HelpGrepToLoclist(keyword)
  let l:keyword = a:keyword
  let l:from_bufnr = winbufnr(0)
  
  if &buftype == 'quickfix'
    let l:from_loclist =  getloclist(winnr())
  endif
  
  let l:from_empty_window = 0
  if expand('%') == '' && &buftype == ''
    let l:from_empty_window = 1
  endif
  
  for nr in range(1, winnr('$'))
    let l:buf_no = winbufnr(nr)
    let l:buf_type = getbufvar(l:buf_no, '&buftype', '')
    if l:buf_type == 'help'
      let l:help_winnr = nr
      break
    endif
  endfor
  
  let l:from_help_loclist = 0
  
  if !exists("l:help_winnr")
    " open help window newly
    help
    
    if l:from_empty_window
      " help file was splitted to below from an empty window
      " no longer need a window above
      wincmd k
      close
      wincmd j
    endif
  else
    " move cursor to existing help window
    execute l:help_winnr."wincmd w"

    if exists('l:from_loclist')
          \ && getloclist(winnr()) == l:from_loclist
      let l:from_help_loclist = 1
    endif
  endif
  
  let l:win_count_before_lclose = winnr('$')
  try
    lclose
  catch /E776: No location list/
    " ignore error
  endtry
  
  if l:keyword == ""
    return
  endif

  let l:loclist_was_showing = l:win_count_before_lclose > winnr('$')
  
  let l:no_result = 0
  try
    execute "lhelpgrep ".l:keyword."@ja"
  catch /E480/
    let l:no_result = 1
  endtry
  
  if len(getloclist(0)) == 0
    let l:no_result = 1
  endif

  if l:no_result == 1
    set nohlsearch
    
    try
      lolder
    catch /E380: At bottom/
      " ignore error
    endtry
    
    if l:loclist_was_showing
      lopen
    endif

    if !l:from_help_loclist
      execute bufwinnr(l:from_bufnr)."wincmd w"
    endif
    call s:Warning("No result")
    return
  endif
  
  lopen
  lrewind
  wincmd p
  
  " add highlight keyword
  " ref. rking/ag.vim
  let @/ = l:keyword
  call feedkeys(":set hlsearch\<CR>", 'n')
endfunction

noremap  <silent> <F1> :call HelpGrepToLoclist(expand('<cword>'))<CR>
inoremap <silent> <F1> <C-o>:call HelpGrepToLoclist(expand('<cword>'))<CR>

function! HelpGrepToLoclistPrompt() abort
  call inputsave()
  let l:keyword = input('HelpGrep > ', expand('<cword>'))
  call inputrestore()
  call HelpGrepToLoclist(l:keyword)
endfunction

map <F13> <S-F1>
imap <F13> <S-F1>
noremap  <silent> <S-F1> :call HelpGrepToLoclistPrompt()<CR>
inoremap <silent> <S-F1> <C-o>:call HelpGrepToLoclistPrompt()<CR>

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

