if exists('g:html_candidates')
  finish
endif
if !exists('g:xmldata_html5')
  runtime! autoload/xml/html5.vim
endif
let s:elements = filter(keys(g:xmldata_html5), 'v:val !~ "^vim"')

let g:html_candidates = {}
function! g:html_candidates.getElementNames(...) abort "{{{
  if a:0 == 1 && a:1 != ''
    let l:parent_element = a:1
    if has_key(g:xmldata_html5, l:parent_element)
      return g:xmldata_html5[l:parent_element][0]
    endif
  endif
  return copy(s:elements)
endfunction "}}}
function! g:html_candidates.getAttributeNames(...) abort "{{{
  if a:0 == 1 && a:1 != ''
    let l:element = a:1
    if has_key(g:xmldata_html5, l:element)
      return keys(g:xmldata_html5[l:element][1])
    endif
  endif

  let l:all_attribute_names = []
  for l:el in s:elements
    if type(g:xmldata_html5[l:el]) == 3
          \	&& len(g:xmldata_html5[l:el]) >= 2
          \ && type(g:xmldata_html5[l:el][1]) == 4
      let l:all_attribute_names += keys(g:xmldata_html5[l:el][1])
    endif
  endfor
  return uniq(l:all_attribute_names)
endfunction "}}}
function! g:html_candidates.getAttributeValues(attr, ...) abort "{{{
  if a:0 == 1 && a:1 != ''
    let l:element = a:1
    if has_key(g:xmldata_html5, l:element)
          \	&& has_key(g:xmldata_html5[l:element][1], a:attr)
      return copy(g:xmldata_html5[l:element][1][a:attr])
    endif
  endif

  let l:all_attribute_values = []
  for l:el in s:elements
    if type(g:xmldata_html5[l:el]) == 3
          \	&& len(g:xmldata_html5[l:el]) >= 2
          \ && type(g:xmldata_html5[l:el][1]) == 4
          \ && has_key(g:xmldata_html5[l:el][1], a:attr)
      let l:all_attribute_values += copy(g:xmldata_html5[l:el][1][a:attr])
    endif
  endfor
  return uniq(l:all_attribute_values)
endfunction "}}}
" vim: foldmethod=marker

