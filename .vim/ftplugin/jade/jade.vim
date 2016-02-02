function! HTML2JadePaste() abort
    let l:indent_cmd = repeat('>gvl', indent('.')/&tabstop)
    let l:html = getreg('+')
    let l:jade = HTML2Jade(l:html, {
                \ 'tabs': 1,
                \ 'bodyless': 1,
                \ 'numeric': 1,
                \ 'noemptypipe': 1
                \})
    call setreg('j', l:jade)
    execute 'normal! "jgP`[v`]V' . l:indent_cmd . 'V'
endfunction

" <C-S-s> = <F24> in my keysym
noremap  <silent><buffer> <F24> :call HTML2JadePaste()<CR>
inoremap <silent><buffer> <F24> <C-o>:call HTML2JadePaste()<CR><C-o>l
snoremap <silent><buffer> <F24> <C-g>d:call HTML2JadePaste()<CR>li
