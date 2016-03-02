if exists('g:omniutil')
  finish
endif
let g:omniutil = {}
function! g:omniutil.getSyntaxStack(lnum, ...) abort "{{{
  let l:cnum = (a:0 == 1) ? a:1 : self.getFirstNonWhiteCnum(a:lnum)
  return map(synstack(a:lnum, l:cnum + 1), 'synIDattr(v:val, "name")')
endfunction "}}}
function! g:omniutil.getFirstNonWhiteCnum(lnum) abort "{{{
  let l:line = getline(a:lnum)
  return match(l:line, '[^ \t]')
endfunction "}}}
function! g:omniutil.isComment(lnum, ...) abort "{{{
  return call(self.is, ['Comment', a:lnum] + a:000, self)
endfunction "}}}
function! g:omniutil.is(synname_pattern, lnum, ...) abort "{{{
  let l:synstack = call(self.getSyntaxStack, [a:lnum] + a:000, self)
  return match(l:synstack, a:synname_pattern) >= 0
endfunction "}}}
function! g:omniutil.getPrevLnum(lnum, ...) abort "{{{
  if a:0 == 1
    let l:synname_filters = a:1
  endif
  let l:lnum = a:lnum - 1
  while l:lnum > 0
    let l:cur_lnum = prevnonblank(l:lnum)
    if l:cur_lnum == 0
      return 0
    endif
    let l:cnum = self.getFirstNonWhiteCnum(l:cur_lnum)
    if exists('l:synname_filters')
      let l:out_of_syntax = 0
      for l:synname_filter in l:synname_filters
        let l:synname = l:synname_filter[0]
        let l:expect = l:synname_filter[1]
        if l:expect != self.is(l:synname, l:cur_lnum, l:cnum)
          let l:out_of_syntax = 1
          break
        endif
      endfor
      if l:out_of_syntax == 1
        return 0
      endif
    endif
    let l:lnum = l:cur_lnum
    let l:is_comment = self.isComment(l:cur_lnum, l:cnum)
    if !l:is_comment
      break
    endif
    let l:lnum = l:cur_lnum - 1
  endwhile
  return l:lnum
endfunction "}}}
