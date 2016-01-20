function! StylusOmniComplete(findstart, base)
    if a:findstart
        return call("csscomplete#CompleteCSS", [a:findstart, a:base])
    endif
    
    let l:candidates = call("csscomplete#CompleteCSS", [a:findstart, a:base])
    
    if a:base == ""
      return l:candidates
    endif
    
    let l:matches = []
    for k in l:candidates
      if strpart(k, 0, strlen(a:base)) ==# a:base
          call add(l:matches, k)
      endif
    endfor
    
    if len(l:matches) == 0
      return l:candidates
    endif
    
    echomsg string(l:matches)
    return l:matches
endfunction

