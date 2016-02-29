if !exists('g:html_candidates')
  runtime! scripts/html_candidates.vim
endif

function! JadeOmniComplete(findstart, base)
  let l:lnum = line('.')
  if a:findstart
    let l:line = getline('.')
    let l:start = col('.') - 1
    while l:start >= 0 && l:line[l:start - 1] =~ '\%(\k\|-\)'
      let l:start -= 1
    endwhile

    let l:categories = []
    
    if s:is_comment(l:lnum)
      let l:categories = ['comment']
    endif
    if s:is_code(l:lnum)
      let l:categories = ['code']
    endif

    let l:line = ''
    if l:start > 0
      let l:line = getline('.')[0: l:start - 1]
    endif
    let l:cnum = col('.')
    let l:synstack = s:get_syntax_stack(l:lnum, l:cnum)
  
    if empty(l:synstack)
      if l:line == '' || l:line =~ '^\s*$'
        " element name or jade keyword
        let l:categories = ['elementName']
      endif
    elseif l:synstack[0] == 'pugTag'
      " inpu_
      let l:categories = ['elementName']
    else
      let l:synstack_attr_i = index(l:synstack, 'pugAttributes')
      if l:synstack_attr_i != -1
        if len(l:synstack) > l:synstack_attr_i + 1
          if l:synstack[l:synstack_attr_i] =~ '^javascriptString'
            " input(type='a_
            let l:categories = ['attrValue']
          else
            " javascript expression?
            let l:categories = ['code']
          endif
        elseif l:line =~ "=[\"']$"
          " input(type='_
          let l:categories = ['attrValue']
        elseif l:line =~ '=$'
          " input(type=_
          let l:categories = ['attrValue', 'code']
        elseif l:line =~ '[(, ]$' || l:line =~ '^\s*$'
          " input(_
          " input(type='text',_
          let l:categories = ['attrName']
        endif
      endif
    endif

    let b:jade_completion_categories = l:categories
    let b:jade_completion_cur_text = l:line[l:start :]
    let b:jade_completion_cur_line = l:line[0: l:start - 1]
    return l:start
  endif

  let l:candidates = s:gather_candidates({
        \ 'lnum': l:lnum,
        \ 'line': b:jade_completion_cur_line,
        \ 'text': b:jade_completion_cur_text,
        \ 'categories': b:jade_completion_categories
        \ })
  
  echomsg string(l:candidates)
  echomsg a:base

  return l:candidates

  " if a:base == ""
  " 	return l:candidates
  " endif
  " 
  " let l:matches = []
  " for k in l:candidates
  " 	if strpart(k, 0, strlen(a:base)) ==# a:base
  " 		call add(l:matches, k)
  " 	endif
  " endfor
  " return l:matches
endfunction

function! s:gather_candidates(info) abort
  let l:candidates = []
  for l:category in a:info.categories
    if l:category == 'elementName'
      return g:html_candidates.getElementNames()
    elseif l:category == 'attrName'
      return g:html_candidates.getAttributeNames(s:get_element(a:info.lnum))
    else
      return []
    endif
  endfor
endfunction

function! s:get_syntax_stack(lnum, cnum) abort
  return map(synstack(a:lnum, a:cnum), 'synIDattr(v:val, "name")')
endfunction
function! s:get_first_non_white_col(lnum) abort
  let l:line = getline(a:lnum)
  return match(l:line, '[^ \t]')
endfunction
function! s:get_element(lnum) abort
  let l:lnum = a:lnum
  while l:lnum >= 1
    let l:cnum = s:get_first_non_white_col(lnum)
    let l:stack = s:get_syntax_stack(l:lnum, l:cnum + 1)
    let l:element_start_syntaxes = ['pugTag', 'pugIdChar', 'pugClassChar']
    if index(l:element_start_syntaxes, l:stack[0]) >= 0
      break
    endif
    unlet l:stack
    if l:lnum == 1
      break
    endif
    let l:lnum = s:prevnonblanknoncomment(l:lnum - 1)
  endwhile
  if l:stack[0] =~ 'Char$'
    return 'div'
  endif
  return matchstr(getline(l:lnum)[l:cnum :], '^[a-zA-Z-]\+')
endfunction
function! s:is_code(lnum) abort
  let l:line = getline(a:lnum)
  if matchstr(l:line, '^\s*\zs[^( ]*\ze') =~ '!\?[-=]$'
    return 1
  endif
  let l:ascentors = s:get_ancestors(a:lnum)
  for l:ascentor in l:ascentors
    if l:ascentor =~ '^-' || l:ascentor =~ '^script'
      return 1
    endif
  endfor
  return 0
endfunction

function! s:is_comment(lnum) abort
  let l:line = getline(a:lnum)
  if l:line =~ '^\s*//'
    return 1
  endif
  let l:ascentors = s:get_ancestors(a:lnum)
  for l:ascentor in l:ascentors
    if l:ascentor =~ '^//'
      return 1
    endif
  endfor
  return 0
endfunction

function! s:get_ancestors(lnum) abort
  let l:lnum = a:lnum
  let l:current_indent = indent(l:lnum)
  let l:ascentors = []
  while 1
    let l:lnum = prevnonblank(l:lnum)
    if indent(l:lnum) < l:current_indent
      break
    endif
    let l:line = substitute(getline(l:lnum), '^\s*', '', 'g')
    " TODO: block expansion (nested colon syntax)
    " ref. http://jade-lang.com/reference/tags/
    
    let l:keyword = matchstr(l:line, '^\zs[^( ]*\ze')
    if l:keyword =~ '^[#\.]'
      let l:keyword = 'div' . l:line
    endif
    call add(l:ascentors, l:keyword)
    let l:lnum-=1
  endwhile
  return l:ascentors
endfunction

function! s:prevnonblanknoncomment(lnum) "{{{
  let lnum = a:lnum
  while lnum > 1
    let lnum = prevnonblank(lnum)
    let line = getline(lnum)
    if !s:is_comment(lnum)
      break
    endif
  endwhile
  return lnum
endfunction "}}}

" vim: foldmethod=marker

