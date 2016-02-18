let s:chm_filename = "hidemac_html.chm"
function! s:set_hidemac_chm_dir() abort
  if exists("g:hidemac_chm_dir") && filereadable(g:hidemac_chm_dir . '\' . s:chm_filename)
    let s:hidemac_chm_dir = g:hidemac_chm_dir
    return
  endif
  let l:path_candidates = [
        \ 'C:\Program Files\Hidemaru',
        \ 'C:\Program Files (x86)\Hidemaru',
        \ 'C:\Hidemaru']
  for dirname in l:path_candidates
    if filereadable(dirname . '\\' . s:chm_filename)
      let s:hidemac_chm_dir = dirname
      return
    endif
  endfor
  echoerr 'couldnt find Hidemaru directory'
endfunction

function! s:set_hidemac_doc_dir() abort
  if exists("g:hidemac_extract_dir")
    let s:hidemac_extract_dir = g:hidemac_extract_dir
  else
    let s:hidemac_extract_dir = $HOME . '\hidemac_doc'
  endif
endfunction

function! s:chm2html() abort
  let l:escaped_extract_dir = shellescape(s:hidemac_extract_dir)
  if !isdirectory(s:hidemac_extract_dir)
    call system('mkdir ' . l:escaped_extract_dir)
  endif
  let l:escaped_chm_path = shellescape(s:hidemac_chm_dir . '\' . s:chm_filename)
  call system(printf('cp %s %s', l:escaped_chm_path, l:escaped_extract_dir . '\' . s:chm_filename))
  let l:extract_cmd = printf(
          \ 'cd %s && hh.exe -decompile .\ %s',
          \	l:escaped_extract_dir,
          \ s:chm_filename
          \)
  call system(l:extract_cmd)
endfunction

function! s:trim(str) abort
  return substitute(a:str, '^[\s　]\+', '', '')
endfunction

function! s:get_keywords() abort
  let l:list = []
  for l:file in glob(s:hidemac_extract_dir . '\html\060_Keyword_*.html', 1, 1)
    let l:sjis_html = join(readfile(l:file, 'b'))
    let l:utf8_html = iconv(l:sjis_html, 'cp932', 'utf-8')
    let l:desc = ''
    let l:lines = split(l:utf8_html, "\r", 1)
    let l:start = match(l:lines, '<TABLE')
    let l:end = match(l:lines, '</TABLE>')
    for l:lnum in range(l:end, l:start, -1)
      let l:line = l:lines[l:lnum]
      let l:word = matchstr(l:line, '^ \s<TD VALIGN=TOP><NOBR>.*<B>\zs[^<]\+\ze</B>')
      if l:word == ''
        let l:desc = substitute(l:line, '^\s\+\ze', '', 'g') . l:desc
        continue
      endif
      let l:desc = substitute(l:desc, '<[^>]\+>', '', 'g')
      let l:menu = s:trim(matchstr(l:desc, '^.\{-}[\.。]'))
      call add(l:list, {
            \ 'word' : l:word,
            \ 'menu' : '(Keyword) ' . l:menu
            \})
      let desc = ''
    endfor
  endfor
  return l:list
endfunction

call s:set_hidemac_chm_dir()
call s:set_hidemac_doc_dir()
call s:chm2html()
