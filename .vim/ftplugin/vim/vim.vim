" to use neco-vim without deoplete|neocomplete
function! VimScriptOmniComplete(findstart, base)
  let l:line = getline('.')
  let l:input = l:line[:col('.')-1]
  if a:findstart
    return call("necovim#get_complete_position", [l:input])
  endif

  let l:candidates = call("necovim#gather_candidates", [l:input, a:base])
  let l:matches = []
  for k in l:candidates
    if strpart(k.word, 0, strlen(a:base)) ==# a:base
      call add(l:matches, k)
    endif
  endfor
  return l:matches
endfunction

setlocal omnifunc=VimScriptOmniComplete

