runtime! ftplugin/php/expand.vim

runtime! scripts/omniutil.vim
let g:blade_comp = {}

function! s:getDirectives() abort
  if !has_key(g:blade_comp, 'directives')
    let l:dictfiles = globpath(&runtimepath, 'ftplugin/blade/directives.dict', 1)
    if !empty(l:dictfiles)
      let g:blade_comp.directives = readfile(l:dictfiles)
    endif
  endif
  return copy(g:blade_comp.directives)
endfunction

function! s:getPairDirectiveNames() abort
  if !has_key(g:blade_comp, 'pair_directive_names')
    let l:directives = s:getDirectives()
    let l:pair_directive_names = []
    for l:directive in l:directives
      if l:directive !~ '^@end'
        continue
      endif
      let l:directive_name = substitute(l:directive, '@end\(.\+\)$', '\1', '')
      call add(l:pair_directive_names, l:directive_name)
    endfor
    let g:blade_comp.pair_directive_names = l:pair_directive_names
  endif
  return copy(g:blade_comp.pair_directive_names)
endfunction

function! s:getCloseDirective() abort
  let l:directive_names = s:getPairDirectiveNames()
  let l:stack = []
  let l:lnum = line('.')
  let l:cnum = col('.') - 2
  let l:lines = getline(1, l:lnum - 1)
  let l:curline = getline(l:lnum)[: l:cnum]
  call add(l:lines, l:curline)
  let l:code = join(l:lines, "\n")
  let l:i = 1
  while 1
    let l:directive = matchstr(l:code, '@[a-z]\+', 0, l:i)
    if l:directive == ''
      break
    endif
    let l:directive_name = substitute(l:directive, '^@', '', '')
    if l:directive_name =~ 'end'
      let l:idx = index(l:stack, substitute(l:directive_name, '^end', '', ''))
      if l:idx >= 0
        call remove(l:stack, l:idx)
      endif
    endif
    if index(l:directive_names, l:directive_name) >= 0
      call insert(l:stack, l:directive_name)
    endif
    let l:i += 1
  endwhile
  call uniq(l:stack)
  call map(l:stack, '"@end" . v:val')
  return l:stack
endfunction

function! s:getCurrentPhpCode(lnum, cnum) abort
  let l:php = ''
  let l:lnum = a:lnum
  let l:line = getline(l:lnum)
  let l:cnum = a:cnum
  while 1
    if !g:omniutil.is('blade\(Echo\|PhpParenBlock\)', l:lnum, l:cnum)
      break
    endif
    let l:php = l:line[l:cnum] . l:php
    let l:cnum = l:cnum - 1
    if l:cnum < 0
      let l:lnum -= 1
      if l:lnum < 1
        break
      endif
      let l:line = getline(l:lnum)
      let l:cnum = len(l:line) - 1
    endif
  endwhile
  return substitute(l:php, '^{[{! -]*', '', '')
endfunction

function! s:findStartPhp() abort
  let l:line = getline('.')
  let l:start = col('.') - 1

  if l:line[l:start] =~ '\.'
    let start -= 1
  endif

  while l:start > 0 && l:line[l:start - 1] =~ '\w'
    let l:start -= 1
  endwhile

  return l:start
endfunction

function! s:completeEclim(lnum, cnum, phpcode) abort
  let l:tmpfile = expand('%:p:h') . '/TMP__' . expand('%:p:t')
  
  let l:nl = &fileformat == 'dos' ? "\r\n" : "\n"
  let l:phpcode = '<?php ' . a:phpcode
  call writefile(split(l:phpcode, l:nl, ''), l:tmpfile, '')
  
  let l:offset = len(l:phpcode)
  let l:file = eclim#project#util#GetProjectRelativeFilePath(l:tmpfile)
  let l:project = eclim#project#util#GetCurrentProjectName()
  
  let command = '-command php_complete -p "<project>" -f "<file>" -o <offset> -e <encoding>'
  let command = substitute(command, '<project>', l:project, '')
  let command = substitute(command, '<file>', l:file, '')
  let command = substitute(command, '<offset>', l:offset, '')
  let command = substitute(command, '<encoding>', eclim#util#GetEncoding(), '')

  let completions = []
  let results = eclim#Execute(command)
  
  call delete(l:tmpfile)
  
  if type(results) != g:LIST_TYPE
    return
  endif

  let open_paren = getline('.') =~ '\%' . col('.') . 'c\s*('
  let close_paren = getline('.') =~ '\%' . col('.') . 'c\s*(\s*)'

  for result in results
    let word = result.completion

    " strip off close paren if necessary.
    if word =~ ')$' && close_paren
      let word = strpart(word, 0, strlen(word) - 1)
    endif

    " strip off open paren if necessary.
    if word =~ '($' && open_paren
      let word = strpart(word, 0, strlen(word) - 1)
    endif

    let menu = eclim#html#util#HtmlToText(result.menu)
    let info = has_key(result, 'info') ?
      \ eclim#html#util#HtmlToText(result.info) : ''

    let dict = {
        \ 'word': word,
        \ 'menu': menu,
        \ 'info': info,
        \ 'dup': 1
      \ }

    call add(completions, dict)
  endfor

  return completions
endfunction

function! CompleteBlade(findstart, base) abort
  let l:lnum = line('.')
  let l:cnum = col('.')
  
  if g:omniutil.is('blade\(Echo\|PhpParenBlock\)', l:lnum, l:cnum - 1)
    if !eclim#PingEclim(0)
      return call('EclimComplete', [a:findstart, a:base])
    endif
    
    if a:findstart
      let b:phpcode = s:getCurrentPhpCode(l:lnum, l:cnum - 2)
      return s:findStartPhp()
    endif
    
    return s:completeEclim(l:lnum, l:cnum, b:phpcode)
  endif
  
  if a:findstart
    if g:omniutil.isComment(l:lnum, l:cnum - 1)
      return -1
    endif
    
    let l:line = getline('.')[: l:cnum - 1]
    if l:line =~ '^\s*@[a-z]*$'
      return match(l:line, '@')
    endif
    
    return call('htmlcomplete#CompleteTags', [a:findstart, a:base])
  endif
  
  if g:omniutil.isComment(l:lnum, l:cnum - 1)
    return []
  endif
    
  let l:candidates = []
  if a:base =~ '^@end'
    let l:candidates = s:getCloseDirective()
  elseif a:base =~ '^@'
    let l:candidates = s:getDirectives()
  else
    return call('htmlcomplete#CompleteTags', [a:findstart, a:base])
  endif
  
  if a:base == ""
    return l:candidates
  endif
  return MatchCandidates(l:candidates, a:base)
endfunction


