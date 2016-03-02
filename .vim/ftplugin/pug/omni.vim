runtime! scripts/html_candidates.vim
runtime! scripts/omniutil.vim

function! CompleteJade(findstart, base)
  let l:lnum = line('.')
  let l:cnum = col('.')
  let l:synstack = g:omniutil.getSyntaxStack(l:lnum, l:cnum - 1)
  if !empty(l:synstack)
    if l:synstack[0] == 'pugStylusBlock'
      if !exists('CompleteStylus')
        runtime! ftplugin/stylus/omni.vim
      endif
      return CompleteStylus(a:findstart, a:base)
    endif
  endif
  
  if a:findstart
    let l:line = getline('.')
    let l:start = col('.') - 1
    while l:start >= 0 && l:line[l:start - 1] =~ '\%(\k\|-\)'
      let l:start -= 1
    endwhile

    let l:categories = []
    
    if g:omniutil.isComment(l:lnum)
      let l:categories = ['comment']
    endif
    if s:is_code(l:lnum)
      echomsg 'code detect'
      let l:categories = ['code']
    endif

    let l:line = ''
    if l:start > 0
      let l:line = getline('.')[0: l:start - 1]
    endif
  
    if empty(l:synstack)
      if l:line == '' || l:line =~ '^\s*$'
        " beginning of line
        let l:categories = ['statementName', 'elementName']
      else
        let l:bol_synstack = g:omniutil.getSyntaxStack(l:lnum)
        if !empty(l:bol_synstack)
          if l:bol_synstack[0] == 'pugDoctype'
            let l:categories = ['doctype']
          endif
        endif
      endif
    elseif l:synstack[0] == 'pugTag'
      " inpu_
      let l:categories = ['statementName', 'elementName']
    else
      let l:synstack_attr_i = match(l:synstack, '^pugAttributes')
      if l:synstack_attr_i != -1
        if len(l:synstack) > l:synstack_attr_i + 2
          if l:synstack[l:synstack_attr_i + 1] =~ '^javascriptString'
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
          let l:categories = ['attrValueQuote', 'code']
        elseif l:line =~ '[(, ]$' || l:line =~ '^\s*$'
          " input(_
          " input(type='text',_
          let l:categories = ['attrName']
        endif
      endif
    endif
    echomsg string(l:categories)

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
  unlet b:jade_completion_categories
  unlet	b:jade_completion_cur_text
  unlet b:jade_completion_cur_line
  
  " echomsg string(l:candidates)
  " echomsg a:base

  if a:base == ""
    return l:candidates
  endif
  return MatchCandidates(l:candidates, a:base)
endfunction

function! s:gather_candidates(info) abort
  let l:candidates = []
  for l:category in a:info.categories
    if l:category == 'statementName'
      let l:candidates += s:gather_statement_name_candidates(a:info)
    elseif l:category == 'elementName'
      let l:candidates += g:html_candidates.getElementNames()
    elseif l:category == 'attrName'
      let l:candidates += g:html_candidates.getAttributeNames(
            \ s:get_element(a:info.lnum)
            \ )
    elseif l:category =~ '^attrValue'
      let l:values = g:html_candidates.getAttributeValues(
            \ s:get_attribute_name(a:info.lnum),
            \ s:get_element(a:info.lnum)
            \ )
      if l:category =~ 'Quote$'
        call map(l:values, '"\"" . v:val . "\""')
      endif
      let l:candidates += l:values
      unlet l:values
    elseif l:category =~ 'doctype'
      let l:candidates += s:gather_doctype_candidates()
    endif
  endfor
  return l:candidates
endfunction
let s:jade_anywhere_statements = ['if', 'case', 'each', 'while', 'extends', 'include', 'mixin', 'block', 'append']
function! s:gather_statement_name_candidates(info) abort
  " TODO: lookup buffer content for additional statements
  let l:additional_statements = ['else', 'when', 'default', 'doctype']
  return copy(s:jade_anywhere_statements + l:additional_statements)
endfunction
let s:jade_doctypes = ['html', 'xml', 'transitional', 'strict', 'frameset', '1.1', 'basic', 'mobile']
function! s:gather_doctype_candidates() abort
  return copy(s:jade_doctypes)
endfunction

function! s:get_element(lnum) abort
  let l:lnum = a:lnum
  let l:cnum = g:omniutil.getFirstNonWhiteCnum(l:lnum)
  while l:lnum >= 1
    let l:stack = g:omniutil.getSyntaxStack(l:lnum)
    let l:element_start_syntaxes = ['pugTag', 'pugIdChar', 'pugClassChar']
    if index(l:element_start_syntaxes, l:stack[0]) >= 0
      break
    endif
    unlet l:stack
    if l:lnum == 1
      break
    endif
    let l:lnum = g:omniutil.getPrevLnum(l:lnum - 1)
  endwhile
  if l:stack[0] =~ 'Char$'
    return 'div'
  endif
  return matchstr(getline(l:lnum)[l:cnum :], '^[a-zA-Z-]\+')
endfunction
function! s:get_attribute_name(lnum) abort
  let l:line = getline(a:lnum)
  let l:cnum = len(l:line) - 1
  let l:attr_name = ''
  while l:cnum > 0
    let l:stack = g:omniutil.getSyntaxStack(a:lnum, l:cnum - 1)
    if len(l:stack) >= 2 && l:stack[1] =~ '[hH]tmlArg$'
      let l:attr_name = l:line[l:cnum - 1] . l:attr_name
    elseif l:attr_name != ''
      break
    endif
    let l:cnum -= 1
  endwhile
  return l:attr_name
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

function! s:get_ancestors(lnum) abort
  let l:lnum = a:lnum
  let l:current_indent = indent(l:lnum)
  let l:ascentors = []
  while 1
    let l:lnum = g:omniutil.getPrevLnum(l:lnum)
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

" vim: foldmethod=marker
