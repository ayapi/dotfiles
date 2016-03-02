runtime! scripts/html_candidates.vim
runtime! scripts/omniutil.vim

function! CompleteJade(findstart, base)
  let l:lnum = line('.')
  let l:cnum = col('.')
  
  if a:findstart
    let l:synstack = g:omniutil.getSyntaxStack(l:lnum, l:cnum - 1)
    if !empty(l:synstack)
      if l:synstack[0] =~ 'pugStylus\(Block\|Filter\)'
        if !exists('CompleteStylus')
          runtime! ftplugin/stylus/omni.vim
        endif
        let b:jade_completion_external = 'Stylus'
        return CompleteStylus(a:findstart, a:base)
      endif
    endif
    
    let l:line = getline('.')
    let l:start = col('.') - 1
    while l:start >= 0 && l:line[l:start - 1] =~ '\%(\k\|-\)'
      let l:start -= 1
    endwhile

    let l:categories = []
    
    if g:omniutil.isComment(l:lnum)
      let l:categories = ['comment']
    elseif s:isCode(l:lnum, l:cnum)
      let l:categories = ['code']
    else
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
    endif
    echomsg string(l:categories)

    let b:jade_completion_categories = l:categories
    let b:jade_completion_cur_text = l:line[l:start :]
    let b:jade_completion_cur_line = l:line[0: l:start - 1]
    return l:start
  endif

  if exists("b:jade_completion_external")
    let l:external_name = b:jade_completion_external
    unlet b:jade_completion_external
    if l:external_name == 'Stylus'
      return CompleteStylus(a:findstart, a:base)
    endif
  endif

  let l:candidates = s:gatherCandidates({
        \ 'lnum': l:lnum,
        \ 'line': b:jade_completion_cur_line,
        \ 'text': b:jade_completion_cur_text,
        \ 'categories': b:jade_completion_categories
        \ })
  unlet! b:jade_completion_categories
  unlet! b:jade_completion_cur_text
  unlet! b:jade_completion_cur_line
  
  " echomsg string(l:candidates)
  " echomsg a:base

  if a:base == ""
    return l:candidates
  endif
  return MatchCandidates(l:candidates, a:base)
endfunction

function! s:gatherCandidates(info) abort"{{{
  let l:candidates = []
  for l:category in a:info.categories
    if l:category == 'statementName'
      let l:candidates += s:gatherStatementNames(a:info)
    elseif l:category == 'elementName'
      let l:candidates += g:html_candidates.getElementNames()
    elseif l:category == 'attrName'
      let l:candidates += g:html_candidates.getAttributeNames(
            \ s:getElementName(a:info.lnum)
            \ )
    elseif l:category =~ '^attrValue'
      let l:values = g:html_candidates.getAttributeValues(
            \ s:getAttributeName(a:info.lnum),
            \ s:getElementName(a:info.lnum)
            \ )
      if l:category =~ 'Quote$'
        call map(l:values, '"\"" . v:val . "\""')
      endif
      let l:candidates += l:values
      unlet l:values
    elseif l:category =~ 'doctype'
      let l:candidates += s:gatherDoctypeValues()
    endif
  endfor
  return l:candidates
endfunction"}}}
let s:jade_anywhere_statements = ['if', 'case', 'each', 'while', 'extends', 'include', 'mixin', 'block', 'append']
function! s:gatherStatementNames(info) abort"{{{
  " TODO: lookup buffer content for additional statements
  let l:additional_statements = ['else', 'when', 'default', 'doctype']
  return copy(s:jade_anywhere_statements + l:additional_statements)
endfunction"}}}
let s:jade_doctypes = ['html', 'xml', 'transitional', 'strict', 'frameset', '1.1', 'basic', 'mobile']
function! s:gatherDoctypeValues() abort"{{{
  return copy(s:jade_doctypes)
endfunction"}}}
function! s:getElementName(lnum) abort"{{{
  let l:lnum = a:lnum
  let l:cnum = g:omniutil.getFirstNonWhiteCnum(l:lnum)
  let l:element_start_syntaxes = ['pugTag', 'pugIdChar', 'pugClassChar']
  while l:lnum >= 1
    let l:stack = g:omniutil.getSyntaxStack(l:lnum)
    if index(l:element_start_syntaxes, l:stack[0]) >= 0
      break
    endif
    unlet l:stack
    if l:lnum == 1
      break
    endif
    let l:lnum = g:omniutil.getPrevLnum(l:lnum)
  endwhile
  if l:stack[0] =~ 'Char$'
    return 'div'
  endif
  return matchstr(getline(l:lnum)[l:cnum :], '^[a-zA-Z-]\+')
endfunction"}}}
function! s:getAttributeName(lnum) abort"{{{
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
endfunction"}}}
function! s:isCode(lnum, cnum) abort"{{{
  return g:omniutil.is('pugJavascript', a:lnum, a:cnum)
endfunction"}}}
function! s:getAncestors(lnum) abort"{{{
  let l:lnum = a:lnum
  let l:indent = indent(l:lnum)
  let l:ascentors = []
  
  " current line, gather block expansion(nested) tags
  " div: a: span
  let l:current_names = s:getTagOrStatementNames(l:lnum)
  if len(l:current_names) > 1
    let l:ascentors += reverse(l:current_names[:-2])
  endif
  
  " previous lines
  while 1
    let l:lnum = g:omniutil.getPrevLnum(l:lnum)
    if l:lnum == 0
      break
    endif
    
    let l:current_indent = indent(l:lnum)
    if l:current_indent >= l:indent
          \ || g:omniutil.is('pugAttributes', l:lnum)
      continue
    endif
    
    let l:names = s:getTagOrStatementNames(l:lnum)
    let l:ascentors += reverse(l:names)
    let l:indent = l:current_indent
  endwhile
  return l:ascentors
endfunction"}}}
function! s:getTagOrStatementNames(lnum) abort"{{{
  let l:lnum = a:lnum
  let l:line = substitute(getline(l:lnum), '^\s*', '', '')
    
  " split with colon for block expansion (nested syntax)
  " ref. http://jade-lang.com/reference/tags/
  let l:names = split(
        \ matchstr(l:line, '^\zs.\{-}\ze\((\|\(:\)\@<! \|$\)'),
        \ ': ', 1)
  return map(l:names, '(v:val =~ "^[#\.]" ? "div" : "") . v:val')
endfunction"}}}

" vim: foldmethod=marker
