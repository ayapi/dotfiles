runtime! scripts/html_candidates.vim
runtime! scripts/omniutil.vim

function! CompleteJade(findstart, base)
  let l:lnum = line('.')
  let l:cnum = col('.')
  
  if a:findstart
    let b:jade_completion_cache = {}
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
    elseif g:omniutil.is('pugBlockExpansionChar\|pugTag$', l:lnum, l:cnum - 2)
      let l:categories = ['elementName']
    else
      let l:line = ''
      if l:start > 0
        let l:line = getline('.')[0: l:start - 1]
      endif
      
      if empty(l:synstack)
        if l:line == '' || l:line =~ '^\s*$'
          " beginning of line
          let l:categories = ['statementName', 'elementName']
        elseif l:line =~ '^\s*+$'
          let l:categories = ['mixin']
        else
          let l:bol_synstack = g:omniutil.getSyntaxStack(l:lnum)
          if !empty(l:bol_synstack)
            if l:bol_synstack[0] == 'pugDoctype'
              let l:categories = ['doctype']
            endif
          endif
        endif
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
  unlet! b:jade_completion_cache
  
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
      if !empty(l:values)
        if l:category =~ 'Quote$'
          call map(l:values, '"\"" . v:val . "\""')
        endif
        let l:candidates += l:values
      endif
      unlet l:values
    elseif l:category == 'mixin'
      let l:candidates += s:gatherMixinNames(a:info)
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
  let l:provider = s:getProvider(a:info.lnum, a:info.cnum)
  let l:ancestor_elements = s:getAncestorElements(a:info.lnum, a:info.cnum)
  if empty(l:ancestor_elements)
    return l:provider.getElementNames()
  endif
  return l:provider.getElementNames(
        \ s:getAncestorElements(a:info.lnum, a:info.cnum)[0]
        \ )
endfunction"}}}
function! s:gatherAttributeNames(info) abort"{{{
  let l:provider = s:getProvider(a:info.lnum, a:info.cnum)
  let l:element = s:getElementName(a:info.lnum, a:info.cnum)
  let l:already_defined_attrs = s:getAttributeNames(a:info.lnum, a:info.cnum)
  return filter(
        \ l:provider.getAttributeNames(l:element),
        \ 'index(l:already_defined_attrs, v:val) < 0'
        \ )
endfunction"}}}
function! s:gatherAttributeValues(info) abort"{{{
  let l:provider = s:getProvider(a:info.lnum, a:info.cnum)
  return l:provider.getAttributeValues(
            \ s:getAttributeName(a:info.lnum, a:info.cnum),
            \ s:getElementName(a:info.lnum, a:info.cnum)
            \ )
endfunction"}}}
let s:anywhere_statements = ['if', 'case', 'each', 'while', 'extends', 'include', 'mixin', 'block', 'append']
let s:additional_statements = ['else', 'when', 'default', 'doctype']
function! s:gatherStatementNames(info) abort"{{{
  " TODO: lookup buffer content for additional statements
  return copy(s:anywhere_statements + s:additional_statements)
endfunction"}}}
let s:doctypes = ['html', 'xml', 'transitional', 'strict', 'frameset', '1.1', 'basic', 'mobile']
function! s:gatherDoctypeValues() abort"{{{
  return copy(s:doctypes)
endfunction"}}}
function! s:gatherMixinNames(info) abort"{{{
  let l:candidates = []
  for l:lnum in range(a:info.lnum - 1, 1, -1)
    let l:line = getline(l:lnum)
    let _ = matchlist(l:line, 'mixin \(\w\+\)\((.\+)\)\?')
    if empty(_)
      continue
    endif
    call add(l:candidates, {'word': _[1], 'menu': _[2]})
  endfor
  return l:candidates
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
function! s:getAttributeNames(lnum, cnum) abort"{{{
  let l:lnum = a:lnum
  let l:cnum = a:cnum
  if !g:omniutil.is('pugAttributes', l:lnum, l:cnum - 1)
    return []
  endif
  
  let l:attrs = []
  let l:line = getline(l:lnum)
  
  let l:attr_name = ''
  while g:omniutil.is('pugAttributes', l:lnum, l:cnum - 1)
    if g:omniutil.is('[hH]tmlArg$', l:lnum, l:cnum - 1)
      let l:attr_name = l:line[l:cnum - 1] . l:attr_name
    elseif l:attr_name != ''
      call add(l:attrs, l:attr_name)
      let l:attr_name = ''
    endif
    let l:cnum -= 1
  endwhile
  return l:attrs
endfunction"}}}
function! s:getAncestors(lnum, cnum) abort"{{{
  if has_key(b:jade_completion_cache, 'ancestors')
    return b:jade_completion_cache.ancestors
  endif
  let l:lnum = a:lnum
  let l:cnum = a:cnum
  let l:indent = indent(l:lnum) + 1
  let l:ancestors = []
  
  while l:lnum > 0
    let l:current_indent = indent(l:lnum)
    let l:first_non_white_cnum = g:omniutil.getFirstNonWhiteCnum(l:lnum)
    if l:current_indent < l:indent
          \ && !g:omniutil.isComment(l:lnum, l:first_non_white_cnum)
      let l:name = ''
      let l:line = getline(l:lnum)
      let l:cnum = len(l:line)
      while l:cnum >= l:first_non_white_cnum
        let l:char = l:line[l:cnum - 1]
        if l:char !~ '\s' && g:omniutil.is(
              \ 'pug\%(Tag$\|Id\|Class\|MixinTag\|Script'
              \ . '\%(Conditional\|Statement\|LoopKeywords\)\)',
              \ l:lnum, l:cnum - 1
              \ )
          let l:name = l:char . l:name
        elseif l:name != ''
          if l:name =~ '^+'
            " mixin
            let l:mixin_block_lnum = s:findMixinBlock(l:name[1:], l:lnum)
            if l:mixin_block_lnum >= 0
              let l:ancestors += s:getAncestors(
                    \ l:mixin_block_lnum - 1,
                    \ getline(l:mixin_block_lnum - 1) - 1
                    \ )
            endif
          endif
          call add(l:ancestors, l:name)
          let l:name = ''
        endif
        let l:cnum -= 1
      endwhile
      let l:indent = l:current_indent
    endif
    let l:lnum = prevnonblank(l:lnum - 1)
  endwhile
  call map(l:ancestors, 'substitute(v:val, "[#\\.].\\+$", "", "g")')
  let b:jade_completion_cache.ancestors = l:ancestors
  return l:ancestors
endfunction"}}}
function! s:getAncestorElements(lnum, cnum) abort"{{{
  let l:ancestors = s:getAncestors(a:lnum, a:cnum)
  if empty(l:ancestors)
    return []
  endif
  let l:statements = s:anywhere_statements + s:additional_statements
  return filter(l:ancestors, 'index(l:statements, v:val, 0, 1) == -1')
endfunction"}}}
function! s:findMixin(name, lnum) abort"{{{
  let l:lines = getline(1, a:lnum)
  return match(l:lines, '^\s*mixin\s' . a:name) + 1
endfunction"}}}
function! s:findMixinBlock(name, lnum) abort"{{{
  let l:start = s:findMixin(a:name, a:lnum)
  let l:end = a:lnum
  let l:indent = indent(l:start)
  let l:cur_lnum = l:start
  while 1
    let l:line = getline(l:cur_lnum)
    if l:line =~ '^\s*block'
      return l:cur_lnum
    endif
    let l:cur_lnum += 1
    if l:indent > indent(l:cur_lnum)
      break
    endif
  endwhile
  return -1
endfunction"}}}
function! s:isSVG(lnum, cnum) abort"{{{
  let l:ancestors = s:getAncestors(a:lnum, a:cnum)
  return index(l:ancestors, 'svg', 0, 1) >= 0
endfunction"}}}
function! s:isCode(lnum, cnum) abort"{{{
  return g:omniutil.is('pugJavascript', a:lnum, a:cnum)
endfunction"}}}

" vim: foldmethod=marker
