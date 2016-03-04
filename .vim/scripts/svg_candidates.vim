if exists('g:svg_candidates')
  finish
endif
function! s:readJson(path) abort
  let l:str = join(readfile(expand(a:path)))
  for l:r in [['true', '1'], ['false', '0']]
    let l:pat = '\("\)\@<!' . l:r[0] . '\("\)\@!'
    let l:str = substitute(l:str, l:pat, l:r[1], 'g')
  endfor
  return eval(l:str)
endfunction

" taken from https://raw.githubusercontent.com/adobe/brackets/master/src/extensions/default/SVGCodeHints/SVGAttributes.json
let s:attrs = s:readJson('~/.vim/scripts/SVGAttributes.json')

" taken from https://raw.githubusercontent.com/adobe/brackets/master/src/extensions/default/SVGCodeHints/SVGTags.json
let s:tags = s:readJson('~/.vim/scripts/SVGTags.json')

let g:svg_candidates = {}
function! g:svg_candidates.getElementNames(...) abort"{{{
  return keys(s:tags.tags)
endfunction"}}}
function! g:svg_candidates.getAttributeNames(...) abort "{{{
  if a:0 == 1 && a:1 != ''
    let l:tagname = a:1
    if has_key(s:tags.tags, l:tagname)
      let l:info = s:tags.tags[l:tagname]
      let l:candidates = []
      if has_key(l:info, 'attributes')
        let l:candidates += copy(l:info.attributes)
      endif
      if has_key(l:info, 'attributeGroups')
        for l:group in l:info.attributeGroups
          let l:candidates += copy(s:tags.attributeGroups[l:group])
        endfor
      endif
      return l:candidates
    endif
  endif
  return keys(s:attrs)
endfunction "}}}
function! g:svg_candidates.getAttributeValues(attr, ...) abort "{{{
  if has_key(s:attrs, a:attr) && has_key(s:attrs[a:attr] , 'attribOptions')
    return copy(s:attrs[a:attr].attribOptions)
  endif
endfunction "}}}

" vim: foldmethod=marker
