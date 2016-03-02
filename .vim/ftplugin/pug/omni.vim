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

    let b:jade_completion_info = {
          \ 'categories': l:categories,
          \ 'lnum': l:lnum,
          \ 'cnum': l:start,
          \ 'text': l:line[l:start :],
          \ 'line': l:line[0: l:start - 1]
          \ }
    return l:start
  endif

  if exists("b:jade_completion_external")
    let l:external_name = b:jade_completion_external
    unlet b:jade_completion_external
    if l:external_name == 'Stylus'
      return CompleteStylus(a:findstart, a:base)
    endif
  endif

  let l:candidates = s:gatherCandidates(b:jade_completion_info)
  unlet! b:jade_completion_info
  
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
      let l:candidates += s:gatherElementNames(a:info)
    elseif l:category == 'attrName'
      let l:candidates += s:gatherAttributeNames(a:info)
    elseif l:category =~ '^attrValue'
      let l:values = s:gatherAttributeValues(a:info)
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
function! s:getProvider(lnum, cnum) abort"{{{
  if s:isSVG(a:lnum, a:cnum)
    if !exists('g:svg_candidates')
      runtime! scripts/svg_candidates.vim
    endif
    return g:svg_candidates
  endif
  return g:html_candidates
endfunction"}}}
function! s:gatherElementNames(info) abort"{{{
  return s:getProvider(a:info.lnum, a:info.cnum).getElementNames()
endfunction"}}}
function! s:gatherAttributeNames(info) abort"{{{
  let l:provider = s:getProvider(a:info.lnum, a:info.cnum)
  let l:tag_name = s:getElementName(a:info.lnum, a:info.cnum)
  return l:provider.getAttributeNames(l:tag_name)
endfunction"}}}
function! s:gatherAttributeValues(info) abort"{{{
  let l:provider = s:getProvider(a:info.lnum, a:info.cnum)
  return l:provider.getAttributeValues(
            \ s:getAttributeName(a:info.lnum, a:info.cnum),
            \ s:getElementName(a:info.lnum, a:info.cnum)
            \ )
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
function! s:getElementName(lnum, cnum) abort"{{{
  let l:lnum = a:lnum
  let l:cnum = a:cnum
  let l:tag_name = ''
  while l:lnum > 0
    let l:line = getline(l:lnum)
    let l:first_non_white_cnum = g:omniutil.getFirstNonWhiteCnum(l:lnum)
    while l:cnum >= l:first_non_white_cnum
      if g:omniutil.is('pug\(Tag\|Id\|Class\)', l:lnum, l:cnum - 1)
        let l:tag_name = l:line[l:cnum - 1] . l:tag_name
      elseif l:tag_name != ''
        break
      endif
      let l:cnum -= 1
    endwhile
    if l:tag_name != ''
      break
    endif
    let l:lnum = g:omniutil.getPrevLnum(l:lnum)
    let l:cnum = len(getline(l:lnum))
  endwhile
  return substitute(l:tag_name, '[#\.].\+$', '', '')
endfunction"}}}
function! s:getAttributeName(lnum, cnum) abort"{{{
  let l:line = getline(a:lnum)
  let l:lnum = a:lnum
  let l:cnum = a:cnum
  let l:attr_name = ''
  while l:cnum > 0
    if g:omniutil.is('[hH]tmlArg$', l:lnum, l:cnum - 1)
      let l:attr_name = l:line[l:cnum - 1] . l:attr_name
    elseif l:attr_name != ''
      break
    endif
    let l:cnum -= 1
  endwhile
  return l:attr_name
endfunction"}}}
function! s:getAncestors(lnum, cnum) abort"{{{
  let l:lnum = a:lnum
  let l:cnum = a:cnum
  let l:indent = indent(l:lnum) + 1
  let l:ascentors = []
  
  while l:lnum > 0
    let l:current_indent = indent(l:lnum)
    if l:current_indent < l:indent
      let l:name = ''
      let l:line = getline(l:lnum)
      let l:cnum = len(l:line)
      let l:first_non_white_cnum = g:omniutil.getFirstNonWhiteCnum(l:lnum)
      while l:cnum >= l:first_non_white_cnum
        let l:char = l:line[l:cnum - 1]
        if l:char !~ '\s' && g:omniutil.is(
              \ 'pug\%(Tag$\|Id\|Class\|Script'
              \ . '\%(Conditional\|Statement\|LoopKeywords\)\)',
              \ l:lnum, l:cnum - 1
              \ )
          let l:name = l:char . l:name
        elseif l:name != ''
          call add(l:ascentors, l:name)
          let l:name = ''
        endif
        let l:cnum -= 1
      endwhile
      let l:indent = l:current_indent
    endif
    let l:lnum = g:omniutil.getPrevLnum(l:lnum)
  endwhile
  " echomsg string(l:ascentors)
  return l:ascentors
endfunction"}}}
function! s:isSVG(lnum, cnum) abort"{{{
  let l:ancestors = s:getAncestors(a:lnum, a:cnum)
  return index(l:ancestors, 'svg', 0, 1) >= 0
endfunction"}}}
function! s:isCode(lnum, cnum) abort"{{{
  return g:omniutil.is('pugJavascript', a:lnum, a:cnum)
endfunction"}}}

" vim: foldmethod=marker
