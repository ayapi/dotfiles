" message文
" question文
" beep文
" play,
" playsync文
" debuginfo文
" showvars文
" title文
" run，
" runsync
" ，runsync2文
" runex文
" endmacro,
"  endmacroall文
" execmacro文
" disabledraw，
" enabledraw文
" disablebreak文
" disableinvert,
"  enableinvert文
" if文
" while文
" break文
" continue文
" goto文
" disableerrormsg,
"  enableerrormsg文
" disablehistory文
" inputpos文
" menu，
" mousemenu,
" menuarray,
" mousemenuarray文
" writeinistr文，
" writeininum文
" openreg文
" createreg文
" deletereg文
" writeregstr文,
" writeregnum文
" writeregbinary文
" getregbinary
" closereg文
" configset文
" config文
" configcolor文
" saveconfig文
" envchanged文
" loadkeyassign文
" savekeyassign文
" loadhilight文
" savehilight文
" loadbookmark文
" savebookmark文
" setfontchangemode文
" setcompatiblemode文
" setfloatmode文
" seterrormode文
" setwindowsize文
" setwindowpos文
" showwindow文
" setmonitor文
" setfocus文
" begingroupundo文
" endgroupundo文
" deletefile文
" findspecial文
" setstaticvariable文
" 

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
  return substitute(a:str, '^[ \t　]\+', '', 'g')
endfunction

function! s:remove_tags(str) abort
  return substitute(a:str, '<[^>]\+>', '', 'g')
endfunction

function! s:get_html_lines(fullpath_or_filename) abort
  if a:fullpath_or_filename =~ '\'
    let l:path = a:fullpath_or_filename
  else
    let l:path = s:hidemac_extract_dir . '\html\' . a:fullpath_or_filename
  endif
  let l:sjis_html = join(readfile(l:path, 'b'))
  let l:utf8_html = iconv(l:sjis_html, 'cp932', 'utf-8')
  return split(l:utf8_html, "\r", 1)
endfunction

function! s:get_keywords() abort
  let l:list = []
  for l:file in glob(s:hidemac_extract_dir . '\html\060_Keyword_*.html', 1, 1)
    let l:lines = s:get_html_lines(l:file)
    let l:desc = ''
    let l:start = match(l:lines, '<TABLE')
    let l:end = match(l:lines, '</TABLE>')
    for l:lnum in range(l:end, l:start, -1)
      let l:line = l:lines[l:lnum]
      let l:word = matchstr(l:line, '^ \s<TD VALIGN=TOP><NOBR>.*<B>\zs[^<]\+\ze</B>')
      if l:word == ''
        let l:desc = substitute(l:line, '^\s\+\ze', '', 'g') . l:desc
        continue
      endif
      let l:desc = s:remove_tags(l:desc)
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

function! s:some_match(str, patterns) abort
  for pat in a:patterns
    if a:str =~ pat
      return 1
    endif
  endfor
  return 0
endfunction

function! s:get_functions() abort
  let l:list = []
  let l:lines = s:get_html_lines('070_Function.html')
  let l:start = match(l:lines, '<TABLE') + 1
  let l:end = match(l:lines, '</TABLE>') - 1
  let l:type_num_desc = ['数値取得', '状態を取得']
  let l:type_num_detail = ['返す値は数値', '数値を取得します', '0 を返します', 'ハンドルを取得します', 'コードを返します']
  let l:type_str_detail = ['返\(す\|り\)値は\(基本的に\)\?文字列', '文字列を取得します', '文字列を返します']
  for l:lnum in range(l:start, l:end, 1)
    let l:line = l:lines[l:lnum]
    let _ = matchlist(l:line, '<A HREF="\([^\"]\+\)">\([^<]\+\)</A><NOBR></TD><TD>\([^<]\+\)</TD>')
    let l:desc = _[3]
    let l:func = matchlist(_[2], '^\(.*\)( \(.*\) )')
    
    let l:type = '?'
    if l:desc =~ '文字列取得'
      let l:type = '$'
    elseif s:some_match(l:desc, l:type_num_desc)
      let l:type = '#'
    elseif l:func[1] =~ '\(index\|handle\|order\|mode\)$'
          \	|| l:func[1] =~ '^find\(window\|hidemaru\)'
          \	|| l:func[1] =~ 'event'
          \ || l:func[1] == 'sendmessage'
      let l:type ='#'
    elseif index(['gettext2', 'tolower', 'toupper', 'getenv', 'dderequest'], l:func[1]) >= 0
      let l:type = '$'
    else
      let l:detail_filename = _[1]
      if l:detail_filename =~ '^070_Function_'
        let l:detail = join(s:get_html_lines(l:detail_filename))
        if s:some_match(l:detail, l:type_num_detail) && !s:some_match(l:detail, l:type_str_detail)
          let l:type = '#'
        elseif !s:some_match(l:detail, l:type_num_detail)	&& s:some_match(l:detail, l:type_str_detail)
          let l:type = '$'
        endif
      endif
    endif
    
    call add(l:list, {
          \ 'word' : l:func[1] . '(',
          \ 'info' : l:func[1] . '(' . l:func[2] . ')',
          \ 'kind' : l:type,
          \ 'menu' : _[3]
          \})
  endfor
  return l:list
endfunction

function! s:get_cmd_statements() abort
  let l:list = []
  for l:file in glob(s:hidemac_extract_dir . '\html\080_CmdStatement_*.html', 1, 1)
    if l:file !~ '080_CmdStatement_[^_]\+\.html'
      continue
    endif
    let l:lines = s:get_html_lines(l:file)
    let l:desc = ''
    let l:start = match(l:lines, '<TABLE')
    let l:end = match(l:lines, '</TABLE>', 0, 1)
    for l:lnum in range(l:end, l:start, -1)
      let l:line = l:lines[l:lnum]
      if l:line =~ '^ \s<TD VALIGN=TOP><NOBR>'
        let l:word = s:trim(substitute(l:line, '<[^>]\+>', '', 'g'))
      else
        let l:desc = substitute(l:line, '^\s\+\ze', '', 'g') . l:desc
        continue
      endif
      let l:desc = s:remove_tags(l:desc)
      call add(l:list, {
            \ 'word' : l:word,
            \ 'menu' : '(Statement) ' . s:trim(l:desc)
            \})
      let desc = ''
    endfor
  endfor
  return l:list
endfunction

function! s:get_other_statements() abort
  let l:list = []
  for l:num in range(9, 15)
    let l:padded_num = l:num == 9 ? '09' : l:num
    for l:file in glob(s:hidemac_extract_dir . '\html\'	. l:padded_num . '0_*.html', 1, 1)
      let l:lines = s:get_html_lines(l:file)
      let l:title_line = s:remove_tags(matchstr(l:lines, '<TITLE>'))
      if l:title_line !~ '文$'
        continue
      endif
      for l:word in split(substitute(l:title_line, '文', '', 'g'), '[,，]')
        let l:word = s:trim(l:word)
        call add(l:list, {
            \ 'word' : l:word,
            \})
      endfor
    endfor
  endfor
  
  " add 'goto'
  return l:list
endfunction

call s:set_hidemac_chm_dir()
call s:set_hidemac_doc_dir()
call s:chm2html()
