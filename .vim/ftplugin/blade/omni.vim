runtime! scripts/omniutil.vim
let g:blade_comp = {}

function! CompleteBlade(findstart, base) abort
  let l:lnum = line('.')
  let l:cnum = col('.')
  
  " TODO: this php completion doesnt work yet...
  if g:omniutil.is('blade\(Echo\|Php\)', l:lnum, l:cnum - 1)
    return call('EclimComplete', [a:findstart, a:base])
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
    
  let l:candidates = []
  if a:base =~ '^@'
    if !has_key(g:blade_comp, 'directives')
      let l:dictfiles = globpath(&runtimepath, 'ftplugin/blade/directives.dict', 1)
      if !empty(l:dictfiles)
        let g:blade_comp.directives = readfile(l:dictfiles)
      endif
    endif
    
    let l:candidates = g:blade_comp.directives
  else
    return call('htmlcomplete#CompleteTags', [a:findstart, a:base])
  endif
  
  if a:base == ""
    return l:candidates
  endif
  return MatchCandidates(l:candidates, a:base)
endfunction


