let g:hidemac_builtin = get(g:, 'hidemac_builtin', {})

let s:chm_filenames = ['hidemac_html.chm', 'hmjre.chm']
function! s:set_hidemac_chm_dir() abort"{{{
  if exists("g:hidemac_chm_dir") && filereadable(g:hidemac_chm_dir . '\' . s:chm_filenames[0])
    let s:hidemac_chm_dir = g:hidemac_chm_dir
    return
  endif
  let l:path_candidates = [
        \ 'C:\Program Files\Hidemaru',
        \ 'C:\Program Files (x86)\Hidemaru',
        \ 'C:\Hidemaru']
  for dirname in l:path_candidates
    if filereadable(dirname . '\\' . s:chm_filenames[0])
      let s:hidemac_chm_dir = dirname
      return
    endif
  endfor
  echoerr 'couldnt find Hidemaru directory'
endfunction"}}}
function! s:set_hidemac_doc_dir() abort"{{{
  if exists("g:hidemac_extract_dir")
    let s:hidemac_extract_dir = g:hidemac_extract_dir
  else
    let s:hidemac_extract_dir = $HOME . '\hidemac_doc'
  endif
endfunction"}}}
function! s:chm2html() abort"{{{
  for l:chm_filename in s:chm_filenames
    let l:extract_dir = shellescape(
          \ s:hidemac_extract_dir	. '\' .fnamemodify(l:chm_filename, ':t:r')
          \)                          "拡張子なしbasenameをdirnameにっかぅ
    if !isdirectory(l:extract_dir)
      call system('mkdir ' . l:extract_dir)
    endif
    let l:escaped_chm_path = shellescape(s:hidemac_chm_dir . '\' . l:chm_filename)
    call system(printf('cp %s %s', l:escaped_chm_path, l:extract_dir . '\' . l:chm_filename))
    let l:extract_cmd = printf(
            \ 'cd %s && hh.exe -decompile .\ %s',
            \	l:extract_dir,
            \ l:chm_filename
            \)
    call system(l:extract_cmd)
  endfor
endfunction"}}}
function! s:trim(str) abort"{{{
  return substitute(a:str, '^[ \t\r\n　]\+', '', 'g')
endfunction"}}}
function! s:remove_tags(str) abort"{{{
  return substitute(a:str, '<[^>]\+>', '', 'g')
endfunction"}}}
function! s:get_html_lines(fullpath_or_filename, ...) abort"{{{
  let l:doc = 'hidemac_html'
  if a:0 == 1
    let l:doc = a:1
  endif
  if a:fullpath_or_filename =~ '\'
    let l:path = a:fullpath_or_filename
  else
    let l:path = s:hidemac_extract_dir . '\' . l:doc . '\html\' . a:fullpath_or_filename
  endif
  let l:sjis_html = join(readfile(l:path, 'b'))
  let l:utf8_html = iconv(l:sjis_html, 'cp932', 'utf-8')
  return split(l:utf8_html, "\r", 1)
endfunction"}}}
function! s:load_keywords() abort"{{{
  if exists('g:hidemac_builtin') && has_key(g:hidemac_builtin, 'keywords')
    return
  endif
  let l:candidates = []
  let l:dict = {}
  for l:file in glob(s:hidemac_extract_dir . '\hidemac_html\html\060_Keyword_*.html', 1, 1)
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
      
      let l:type = '#'
      if l:file =~ 'DateTime'
        if index(['tickcount', 'dayofweeknum'], l:word) == -1
          let l:type = '$'
        endif
      elseif l:file=~ 'File' || l:word =~ 'buffer$'
            \ || index(['getclipboard', 'fontname', 'fontcharset'], l:word) >= 0
        let l:type = '$'
      endif
      
      call add(l:candidates, {
            \ 'word' : l:word,
            \ 'kind' : l:type,
            \ 'menu' : '(値) ' . l:menu
            \})
      let l:dict[l:word] = {'type': l:type}
      let desc = ''
    endfor
  endfor
  let g:hidemac_builtin.keywords = {
        \ 'candidates': l:candidates,
        \ 'data': l:dict
        \}
endfunction"}}}
function! s:full2half(str) abort"{{{
  let l:list = [['（', '('], ['）', ')']]
  let l:str = a:str
  for [full, half] in l:list
    let l:str = substitute(l:str, full, half, 'g')
  endfor
  return l:str
endfunction"}}}
function! s:load_configs() abort"{{{
  if exists('g:hidemac_builtin') && has_key(g:hidemac_builtin, 'configs')
    return
  endif
  let l:dict = {}
  
  let l:lines = s:get_html_lines('150_ConfigStatement_config_x.html')
  let l:start = match(l:lines, '<TD VALIGN=TOP><NOBR><B>xFont')
  let l:end = match(l:lines, '</TABLE>')
  let l:html = join(l:lines[l:start : l:end], "\r")
  
  let l:pos = 0
  let l:len = len(l:html)
  
  " 改行を含む最短一致で内包要素のみマッチ
  let l:td_pattern = '<TD\( VALIGN=TOP\)*>\zs\_.\{-}\ze</TD>'
  
  while 1
    let l:left = match(l:html, l:td_pattern, l:pos)
    if l:left == -1
      break
    endif
    let l:right = matchend(l:html, l:td_pattern, l:pos)
    let l:pos = l:right + 1
    
    let l:txt = l:html[l:left : l:right - 1]
    if l:txt =~ '<NOBR><B>x'
      let l:word = substitute(s:remove_tags(l:txt), '^x', '', '')
      continue
    elseif l:txt =~ '<NOBR>'
      let l:type = s:remove_tags(l:txt) == '文字列' ? '$' : '#'
      continue
    else
      let l:desc = s:trim(s:full2half(substitute(l:txt, '<BR>\_.*', '', '')))
      if l:word == 'AutoAdjustOrikaeshi'
        let l:desc = '折り返し桁数の動作'
      elseif l:word == 'OrikaeshiLine'
        let l:desc = substitute(l:desc, '　.*', '', '')
      endif
      let l:dict[l:word] = {
          \ 'type': l:type,
          \ 'desc': l:desc
          \}
    endif
  endwhile
  let g:hidemac_builtin.configs = {
        \ 'data': l:dict
        \}
endfunction"}}}
function! s:load_filters() abort"{{{
  if exists('g:hidemac_builtin') && has_key(g:hidemac_builtin, 'filters')
    return
  endif
  let l:dict = {}
  
  let l:lines = s:get_html_lines('080_CmdStatement_Edit_filter.html')
  let l:start = match(l:lines, '<TABLE') + 1
  let l:end = match(l:lines, '</TABLE>') - 1
  for l:lnum in range(l:start, l:end)
    let l:line = l:lines[l:lnum]
    let l:line = substitute(l:line, '^\s*<tr><td>', '', '')
    let l:line = substitute(l:line, '</td></tr>$', '', '')
    let [l:word, l:desc] = split(l:line, '</td><td>')
    let l:desc = substitute(l:desc, ' (※注)', '', '')
    
    let l:dict[l:word] = {'type': '$', 'desc': l:desc}
  endfor
  let g:hidemac_builtin.filters = {
        \ 'data': l:dict
        \}
endfunction"}}}
function! s:some_match(str, patterns) abort"{{{
  for pat in a:patterns
    if a:str =~ pat
      return 1
    endif
  endfor
  return 0
endfunction"}}}
function! s:load_dlls() abort"{{{
  if !exists('g:hidemac_builtin')
        \	|| !has_key(g:hidemac_builtin, 'functions')
        \ || !has_key(g:hidemac_builtin, 'statements')
        \ || !has_key(g:hidemac_builtin, 'keywords')
    echoerr "めんどぃからload_dllゎほかのビルトインをロードしてからにして"
    return
  endif
  
  let l:lines = s:get_html_lines('200_Dll.html')
  let l:start = match(l:lines, '<DL>')
  let l:end = match(l:lines, '</DL>', 0, 2)
  let l:html = join(l:lines[l:start : l:end], "\r")
  
  let l:pos = 0
  let l:len = len(l:html)
  
  let l:dt_pattern = '<DT CLASS="SUBTITLE2">\zs.\{-}\ze\r'
  let l:categories_ja = ['文', '関数', '値']
  let l:categories_en = ['statement', 'function', 'keyword']
  
  while 1
    let l:left = match(l:html, l:dt_pattern, l:pos)
    if l:left == -1
      break
    endif
    let l:right = matchend(l:html, l:dt_pattern, l:pos)
    let l:pos = l:right + 1

    let l:txt = l:html[l:left : l:right - 1]
    let l:word = matchstr(l:txt, '[a-z]\+')
    let l:desc = s:trim(s:remove_tags(matchstr(l:html, '\_.\{-}\ze<BR>', l:right)))

    let l:category_ja = matchstr(l:txt, '（\zs.\{-}\ze）')
    let l:category = l:categories_en[index(l:categories_ja, l:category_ja)]
    if has_key(g:hidemac_builtin[l:category . 's'].data, l:word)
      continue
    endif
    if l:category == 'statement'
      let l:candidate = {
            \ 'word': l:word,
            \ 'menu': '(' . l:category_ja .') ' . l:desc
            \}
      let l:data = []
    elseif l:category == 'function'
      if l:word =~ '^dllfunc'
        " 本当ゎ、複数のDLLを扱ぅとき引数パターンがちがぅんだけど、
        " そーゅー関数がほかにもぁったらまたかんがぇる
        let l:type = l:word =~ '^dllfuncstr' ? '$' : '?'
        let l:arg_string = 'funcname, ...'
        let l:arg_types = ['$']
      elseif l:word == 'loaddll'
        let l:desc = '複数のDLLを扱うためのloaddll文の代わり'
        let l:type = '#'
        let l:arg_string = 'filename'
        let l:arg_types = ['$']
      elseif l:word == 'getloaddllfile'
        let l:type = '$'
        let l:arg_string = 'dll_id'
        let l:arg_types = ['#']
      endif
      
      let l:candidate = {
          \ 'word' : l:word . '(',
          \ 'info' : l:word . '(' . l:arg_string . ')',
          \ 'kind' : l:type,
          \ 'menu' : l:desc
          \}
      let l:data = {
            \ 'type': l:type,
            \ 'args': {'str': l:arg_string, 'types': l:arg_types}
            \}
    elseif l:category == 'keyword'
      let l:type = '?'
      if l:word == 'loaddllfile'
        let l:desc = 'ロードされているDLLのファイル名'
        let l:type = '$'
      endif
      let l:candidate = {
            \ 'word': l:word,
            \ 'kind': l:type,
            \ 'menu': '(' . l:category_ja .') ' . l:desc
            \}
      let l:data = {'type': l:type}
    endif
    call add(g:hidemac_builtin[l:category . 's'].candidates, l:candidate)
    let g:hidemac_builtin[l:category . 's'].data[l:word] = l:data
    unlet l:data
  endwhile
endfunction"}}}

let s:load_dllfuncs = {}
function! s:load_dllfuncs.hmjre() abort"{{{
  if exists('g:hidemac_dlls')	&& has_key(g:hidemac_builtin, 'hmjre')
    return
  endif
  let g:hidemac_dlls = get(g:, 'hidemac_dlls', {})
  
  let l:dict = {}
  let l:lines = s:get_html_lines('0008_API_MACRO.html', 'hmjre')
  let l:start = match(l:lines, '^\s<DL>')
  let l:end = match(l:lines, '^\s</DL>')
  let l:html = join(l:lines[l:start : l:end], "\r")
  
  let l:pos = 0
  let l:len = len(l:html)
  
  let l:dt_pattern = '[^\t]<DT CLASS="SUBTITLE2">\zs.\{-}\ze\r'
  
  while 1
    let l:dt_start = match(l:html, l:dt_pattern, l:pos)
    if l:dt_start == -1
      break
    endif
    let l:dt_end = matchend(l:html, l:dt_pattern, l:pos)
    let l:words = split(s:remove_tags(l:html[l:dt_start : l:dt_end - 1]), ',')
    
    let l:dd_end = matchend(l:html, '[^\t]<DD>\zs\_.\{-}</DD>', l:dt_end)
    if l:dd_end == -1
      break
    endif
    let l:dd = l:html[l:dt_end : l:dd_end - 1]
    let l:pos = l:dd_end + 1

    for l:word in l:words
      let l:word = matchstr(l:word, '[a-zA-Z_]\+')
      if l:word == ''
        continue
      endif
      if l:word == 'SetUnicodeIndexAutoConvert'
        let l:desc = 'HmJre.dll側での文字コードインデックス自動変換をONにする'
      elseif len(l:words) == 1
        let l:desc = matchstr(l:dd, '関数は、\?\zs.\{-}\ze。')
        if l:desc == ''
          let l:desc = matchstr(l:dd, '^\zs.\{-}\ze。')
        endif
      else
        let l:desc = matchstr(l:dd, l:word . '関数は、\?\zs.\{-}\ze。')
      endif
      let l:desc = s:trim(s:remove_tags(l:desc))
      
      let l:type = l:word =~ '^ReplaceRegular' ? '$' : '#'
      
      let l:params = []
      if l:word =~ '^GetLastMatchTag' || l:word == 'SetUnicodeIndexAutoConvert'
        call add(l:params, '#')
      elseif l:dd !~ 'パラメータはありません'
        let l:param_i = 1
        if l:dd =~ 'パラメータ１'
          let l:param_pattern = 'パラメータ[１-８][(（]\zs\(数値\|文字列\)\ze型[)）]'
        else
          let l:param_pattern = '第[１-８]パラメータ[(（]\zs\(数値\|文字列\)\ze型[)）]'
        endif
        while 1
          let l:param = matchstr(l:dd, l:param_pattern, 0, l:param_i)
          if l:param == ''
            break
          endif
          call add(l:params, ['#', '$'][index(['数値', '文字列'], l:param)])
          let l:param_i = l:param_i + 1
        endwhile
      endif
      let l:dict[l:word] = {
            \ 'type': l:type,
            \ 'arg_types': l:params,
            \ 'desc': '(HmJre) ' . l:desc
            \}
    endfor
  endwhile
  let g:hidemac_dlls.hmjre = l:dict
endfunction"}}}
function! s:load_functions() abort"{{{
  if exists('g:hidemac_builtin') && has_key(g:hidemac_builtin, 'functions')
    return
  endif
  let l:candidates = []
  let l:dict = {}
  let l:lines = s:get_html_lines('070_Function.html')
  let l:start = match(l:lines, '<TABLE') + 1
  let l:end = match(l:lines, '</TABLE>') - 1
  let l:type_num_desc = ['数値取得', '状態を取得']
  let l:type_num_detail = ['返す値は数値', '数値を取得します', '0 を返します', 'ハンドルを取得します', 'コードを返します']
  let l:type_str_detail = ['返\(す\|り\)値は文字列', '文字列を取得します', '文字列を返します']
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
    
    call add(l:candidates, {
          \ 'word' : l:func[1] . '(',
          \ 'info' : l:func[1] . '(' . l:func[2] . ')',
          \ 'kind' : l:type,
          \ 'menu' : _[3]
          \})
    
    let l:arg_types = map(split(l:func[2], ', '), 'v:val =~ "^s" ? "$" : "#"')
    let l:dict[l:func[1]] = {
          \ 'type': l:type,
          \ 'args': {'str': l:func[2], 'types': l:arg_types}
          \}
  endfor
  let g:hidemac_builtin.functions = {
        \ 'candidates': l:candidates,
        \ 'data': l:dict
        \}
endfunction"}}}
function! s:get_cmd_statements() abort"{{{
  let l:candidates = []
  let l:dict = {}
  for l:file in glob(s:hidemac_extract_dir . '\hidemac_html\html\080_CmdStatement_*.html', 1, 1)
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
      call add(l:candidates, {
            \ 'word' : l:word,
            \ 'menu' : '(文) ' . s:trim(l:desc)
            \})
      let l:dict[l:word] = []
      let desc = ''
    endfor
  endfor
  return [l:candidates, l:dict]
endfunction"}}}

let s:other_statements = {
      \ 'openreg': 'レジストリをオープンする',
      \ 'createreg': 'サブキーが存在しない場合新たに作成してレジストリをオープンする',
      \ 'enableerrormsg': 'disableerrormsgを元に戻す',
      \ 'menu': 'コンマ区切りで項目を指定し、文字カーソルの近くにポップアップメニューを表示',
      \ 'mousemenu': 'コンマ区切りで項目を指定し、マウスカーソルの近くにポップアップメニューを表示',
      \ 'menuarray': '配列変数で項目を指定し、文字カーソルの近くにポップアップメニューを表示',
      \ 'mousemenuarray': '配列変数で項目を指定し、マウスカーソルの近くにポップアップメニューを表示',
      \ 'envchanged': 'レジストリから設定内容を再読込みし、秀丸エディタの設定を更新',
      \ 'writeregstr': 'レジストリにREG_SZ型の値を書き込む',
      \ 'writeregnum': 'レジストリにREG_DWORD型の値を書き込む',
      \ 'begingroupundo': 'やり直しのグループ化を開始する',
      \ 'endgroupundo': 'やり直しのグループ化を終了する',
      \}
function! s:get_other_statements() abort"{{{
  let l:candidates = []
  let l:dict = {}
  for l:num in range(9, 15)
    if l:num == 9
      let l:doc_num = '090'
    elseif l:num == 15
      let l:doc_num = '15[05]'
    else
      let l:doc_num = l:num . '0'
    endif
    
    for l:file in glob(s:hidemac_extract_dir . '\hidemac_html\html\'	. l:doc_num . '_*.html', 1, 1)
      let l:lines = s:get_html_lines(l:file)
      let l:title_line = s:remove_tags(matchstr(l:lines, '<TITLE>'))
      if l:title_line !~ '文$'
        continue
      endif
      let l:words = split(substitute(l:title_line, '文', '', 'g'), '[,，]')
      for l:word in l:words
        let l:word = s:trim(l:word)
        if has_key(s:other_statements, l:word)
          let l:desc = s:other_statements[l:word]
        else
          let l:desc = matchstr(l:lines, l:word . '文*は')
          if l:desc == ''
            let l:desc = matchstr(l:lines, join(l:words, '[, ，]') . '文*は')
          endif
          if l:desc != ''
            let l:desc = matchstr(l:desc, l:word . '文*は、*\zs.\{-}\ze。')
          else
            let l:desc = matchstr(matchstr(l:lines, '。'), '^\zs.\{-}\ze。')
          endif
        endif
        let l:desc = s:trim(s:remove_tags(l:desc))
        
        call add(l:candidates, {
            \ 'word' : l:word,
            \ 'menu' : '(文) ' . l:desc
            \})
        let l:dict[l:word] = []
      endfor
    endfor
  endfor
  
  let l:candidates = l:candidates + [
        \{'word': 'refreshdatetime',
        \ 'menu': '(文) 日付と時刻を表すキーワードの値を更新する'},
        \{'word': 'goto',
        \	'menu': '(文) マクロの処理を任意の場所に移動させる'},
        \{'word': 'call',
        \	'menu': '(文) サブルーチンを呼ぶ'},
        \{'word': 'return',
        \	'menu': '(文) サブルーチンから復帰する'}
        \]
  let l:dict['refreshdatetime'] = []
  let l:dict['goto'] = []
  let l:dict['call'] = []
  let l:dict['return'] = []
  return [l:candidates, l:dict]
endfunction"}}}
function! s:load_statements() abort"{{{
  if exists('g:hidemac_builtin') && has_key(g:hidemac_builtin, 'statements')
    return
  endif
  let g:hidemac_builtin.statements = {}
  let [l:cmd_candidates, l:cmd_data] = s:get_cmd_statements()
  let [l:other_candidates, l:other_data] = s:get_other_statements()
  let g:hidemac_builtin.statements.candidates = l:cmd_candidates + l:other_candidates
  let g:hidemac_builtin.statements.data = extend(l:cmd_data, l:other_data)
endfunction"}}}
function! s:statements() abort"{{{
  return g:hidemac_builtin.statements.candidates
endfunction"}}}
function! s:functions(...) abort"{{{
  if a:0 == 0 || a:1 == '' || a:1 == '?'
    return copy(g:hidemac_builtin.functions.candidates)
  endif
  let l:type = substitute('#$', a:1, '', '')
  if a:1 =~ '[$#]'
    return filter(copy(g:hidemac_builtin.functions.candidates), 'v:val.kind != l:type')
  endif
endfunction"}}}
function! s:keywords(...) abort"{{{
  if a:0 == 0 || a:1 == '' || a:1 == '?'
    return copy(g:hidemac_builtin.keywords.candidates)
  endif
  let l:type = substitute('#$', a:1, '', '')
  if a:1 =~ '[$#]'
    return filter(copy(g:hidemac_builtin.keywords.candidates), 'v:val.kind != l:type')
  endif
endfunction"}}}
function! s:expressions(...) abort"{{{
  if a:0 == 0 || a:1 == '' || a:1 == '?'
    return s:variables() + s:keywords() + s:functions()
  endif
  if a:1 =~ '[$#]'
    return s:variables(a:1) + s:keywords(a:1) + s:functions(a:1)
  endif
endfunction"}}}
function! s:variables(...) abort"{{{
  let l:type_pattern = '[$#]'
  if a:0 == 1 && a:1 =~ '[$#]'
    let l:type_pattern = a:1
  endif
  let l:candidates = []
  let l:in_other_sub = 0
  let l:call_found = 0
  for l:lnum in range(line('.') - 1, 1, -1)
    let l:line = getline(l:lnum)
    
    if l:line =~ ':\s*$' "label
      if l:in_other_sub == 0
        let l:in_other_sub = 1
      endif
    endif
    
    if l:line =~ '^\s*return' "subroutine end
      let l:in_other_sub = 1
    endif

    if !l:call_found && l:line =~ '^\s*call .*;' && !l:in_other_sub
      let l:call_found = 1
    endif
    
    let l:i = 1
    while 1
      let l:var = matchstr(l:line, l:type_pattern . '[a-zA-Z0-9_]\+\s*=[^;]\{-};', 0, l:i)
      let l:i = l:i + 1
      if l:var == ''
        break
      endif
      if l:in_other_sub && l:var =~ '^' . l:type_pattern .'\{2\}' " local var in other sub
        continue
      endif
      call add(l:candidates, {
            \ 'word': matchstr(l:var, '^' . l:type_pattern . '.\{-}\ze[ \=]'),
            \ 'menu': matchstr(l:var, '\s*\zs=.\{-};$')
            \})
    endwhile
  endfor
  if l:call_found
    let l:returns = [{'word': '$$return'}, {'word': '##return'}]
    if l:type_pattern == '$'
      let l:type_pattern = '\$'
    endif
    call filter(l:returns, 'v:val.word =~ "^" . l:type_pattern')
    let l:candidates = l:candidates + l:returns
  endif
  return l:candidates
endfunction"}}}
function! s:labels() abort"{{{
  let l:candidates = []
  for l:lnum in range(1, line('$'))
    let l:line = getline(l:lnum)
    let l:label = matchstr(l:line, '^\s*\zs[a-zA-Z0-9_"]\+\ze:\s*$')
    if l:label != ''
      call add(l:candidates, {'word': l:label})
    endif
  endfor
  return l:candidates
endfunction"}}}
function! s:get_after_block(ctx) abort"{{{
  if strridx(a:ctx, '(') > strridx(a:ctx, ')')
    " else ifの条件のかくカッコの中にぃる
    return s:expressions()
  elseif a:ctx =~ '^}\s*else\s\+$'
    " } else ってかぃたとこ
    return [{
          \ 'word': 'if',
          \ 'menu': '(文) その直後にある条件式が０以外の場合に次のコマンドを実行します。'
          \}]
  elseif a:ctx =~ '^}\s*$'
    " } ってだけかぃたとこ
    " 閉じたブロックの開始地点をみにぃく
    let l:lnum = line('.') - 1
    if l:lnum < 1
      return []
    endif
    for l:lnum in range(l:lnum, 1, -1)
      let l:line = getline(l:lnum)
      if l:line =~ '\s*{\s*' && l:line !~ '^\s*//'
        break
      endif
    endfor
    if l:line =~ 'if\s*([^)]\+)\s*{\s*'
      " ifブロックを閉じた直後だった
      return [{'word': 'else', 'menu': '(文)'}]
    endif
    return []
  endif
  return []
endfunction"}}}

let s:str_patterns = {'''': '''.\{-}\(\\\)\@<!''', '"': '".\{-}\(\\\)\@<!"'}
function! s:get_context(line) abort"{{{
  let l:line = a:line
  let l:str_ranges = []
  let l:i = 0
  while 1
    if l:i >= len(l:line)
      break
    endif
    " ダブルクオートかクオートがひらくとこをさがす
    let l:q_open_pos = match(l:line, '\(\\\)\@<!["'']', l:i)
    if l:q_open_pos == -1
      break
    endif
    " 開ぃてたから、閉じるとこをさがす
    let l:q = l:line[l:q_open_pos]
    let l:q_close_pos = matchend(l:line, s:str_patterns[l:q], l:q_open_pos)
    if l:q_close_pos == -1
      " 閉じてなぃっぽぃ
      call add(l:str_ranges, [l:q_open_pos, len(l:line)+1])
      break
    endif
    " 閉じられてた
    call add(l:str_ranges, [l:q_open_pos, l:q_close_pos])
    let l:i = l:q_close_pos + 1
  endwhile

  let l:i = 0
  let l:sep_pattern = '\(;\s*\|\(if\|while\)\s*([^)]\+)\s*{*\s*\|else\s{*\s*\)'
  let l:head_position = 0
  while 1
    if l:i >= len(l:line)
      break
    endif
    " echomsg l:line[l:i :]
    let l:sep_start = match(l:line, l:sep_pattern, l:i)
    if l:sep_start == -1
      break
    endif
    let l:sep_end = matchend(l:line, l:sep_pattern, l:i)
    if len(l:str_ranges) == 0
      let l:i = l:sep_end
      continue
    endif
    " echomsg 'matchstr:' . matchstr(l:line, l:sep_pattern, l:i)
    let l:match = 1
    for [qd_open, qd_close] in l:str_ranges
      " echomsg 'qd_open :' . qd_open
      " echomsg 'qd_close:' . qd_close
      " echomsg 'sep_start:' . l:sep_start
      " echomsg 'sep_end :' . l:sep_end
      if !(qd_close <= l:sep_start	|| l:sep_end <= qd_open
            \ || (l:sep_start <= qd_open && qd_close <= l:sep_end))
        let l:match = 0
        break
      endif
    endfor
    " echomsg 'match:' . l:match
    if !l:match
      let l:i = qd_close + 1
      continue
    endif
    let l:head_position = l:sep_end
    let l:i = l:sep_end
  endwhile

  " echomsg l:head_position . '/' . len(l:line)
  return s:trim(l:line[l:head_position: ])
endfunction"}}}
function! s:stash_strings(line) abort"{{{
  let l:line = a:line
  while 1
    " ダブルクオートかクオートがひらくとこをさがす
    let l:q_open_pos = match(l:line, '\(\\\)\@<!["'']')
    if l:q_open_pos == -1
      break
    endif
    " 開ぃてたから、閉じるとこまでを置き換ぇる
    let l:q = l:line[l:q_open_pos]
    let l:replaced_line = substitute(l:line, s:str_patterns[l:q], '$$str', '')
    if l:replaced_line == l:line
      " そも②閉じられてなかった
      let l:line = l:line[: l:q_open_pos - 1] . '$$str'
      break
    endif
    let l:line = l:replaced_line
  endwhile
  return l:line
endfunction"}}}
function! s:analyze_brace(line, target_level) abort"{{{
  let l:level = 0
  let l:last_pos = len(a:line) - 1
  let l:comma_count = 0
  for i in range(l:last_pos, 0, -1)
    let l:char = a:line[i]
    " echomsg 'char:' . l:char
    
    let l:cur_level = l:level
    if l:char == ')'
      let l:cur_level = l:cur_level + 1
    elseif l:char == '('
      let l:cur_level = l:cur_level - 1
    endif
    " echomsg 'level:' . l:level
    " echomsg 'curlevel:' . l:cur_level
    
    if l:char == ',' && l:cur_level == a:target_level + 1
      let l:comma_count = l:comma_count + 1
    endif
    if l:level > a:target_level && l:cur_level == a:target_level
      break
    endif
    let l:level = l:cur_level
  endfor
  return [i, l:comma_count]
endfunction"}}}
function! s:analyze_function(line, ...) abort"{{{
  " デフォでゎ、ぃま引数をかぃてる関数の名前を取る
  let l:target_level = -1
  if a:0 == 1 && a:1 == 'last'
    " lastだと、もぅかきぉゎってカーソルょり左にぁる中で最も右の関数の名前
    let l:target_level = 0
  endif
  let [l:pos, l:comma_count] = s:analyze_brace(a:line, l:target_level)
  return [matchstr(a:line[: l:pos - 1], '[a-zA-Z0-9_$#]\+$'), l:comma_count]
endfunction"}}}
function! s:get_last_type(ctx) abort"{{{
  let l:line = s:stash_strings(a:ctx)
  let l:type = '?'
  while len(l:line) >= 0
    if l:line !~ ')\s*$'
      let l:ks = split(l:line, '[^a-zA-Z0-9_$#\.]\+')
      if len(l:ks) == 0
        " なんかへんみたぃだからぁきらめる
        break
      endif
      let l:k = l:ks[len(l:ks) - 1]
      " キーワードか変数かリテラルかゎかんなぃのをゲットした
      " echomsg 'what?: ' . l:k
      
      if l:k =~ '^[0-9x.]\+$'
        return '#'
      elseif l:k =~ '^\$'
        return '$'
      elseif l:k =~ '^#'
        return '#'
      elseif has_key(g:hidemac_builtin.keywords.data, l:k)
        return g:hidemac_builtin.keywords.data[l:k].type
      endif
      break
    else
      let [l:function_name, l:unused] = s:analyze_function(l:line, 'last')
      if l:function_name == ''
        " カッコの正体が関数じゃなかった
        let l:line = substitute(l:line, ')\s*$', '', '')
      else
        " echomsg 'funcname:' . l:function_name
        if has_key(g:hidemac_builtin.functions.data, l:function_name)
          return g:hidemac_builtin.functions.data[l:function_name].type
        endif
        " 関数っぽぃものだけど型の情報がなぃょ
        break
      endif
    endif
  endwhile
  return l:type
endfunction"}}}
function! s:split_arguments(line) abort"{{{
  let l:line = a:line
  let l:pos = 0
  let l:level = 0
  let l:commas = []

  while 1
    let l:pos = match(l:line, '[(),"'']', l:pos)
    if l:pos == -1
      break
    endif
    let l:char = l:line[l:pos]
    
    if l:char =~ '["'']'
      " 文字列リテラルがはじまったからスキップする
      let l:q_close_pos = matchend(l:line, s:str_patterns[l:char], l:pos)
      if l:q_close_pos == -1
        " 閉じてなぃっぽぃ
        break
      endif
      let l:pos = l:q_close_pos
      continue
    elseif l:char == '('
      let l:level = l:level + 1
    elseif l:char == ')'
      let l:level = l:level - 1
    elseif l:char == ',' && l:level == 0
      call add(l:commas, l:pos)
    endif
    let l:pos = l:pos + 1
  endwhile
  
  if len(l:commas) == 0
    return [substitute(l:line, '^\s*', '', '')]
  endif
  
  let l:args = []
  let l:commas_count = len(l:commas)
  call add(l:args, l:line[: l:commas[0] - 1])
  for l:cnum in range(0, l:commas_count - 2)
    call add(l:args, l:line[l:commas[l:cnum] + 1 : l:commas[l:cnum + 1] - 1])
  endfor
  call add(l:args, l:line[l:commas[l:commas_count - 1] + 1 :])
  
  call map(l:args, 'substitute(v:val, "^\\s*", "", "")')
  return l:args
endfunction"}}}
function! s:get_candidates_from_data(data) abort"{{{
  return values(map(deepcopy(a:data),
        \ '{"word": v:key, "menu": v:val.desc, "kind": v:val.type}'))
endfunction"}}}
function! s:stringify_candidates(cur_arg_text, candidates) abort"{{{
  if a:cur_arg_text =~ '^"'
    return a:candidates
  endif
  let l:candidates = a:candidates
  for i in range(0, len(l:candidates) - 1)
    let l:candidates[i].word = '"' . l:candidates[i].word . '"'
  endfor
  return l:candidates
endfunction"}}}

let s:special_functions = {}
function! s:special_functions.getconfig(i, args) abort"{{{
  if a:i > 0
    return []
  endif
  call s:load_configs()
  let l:candidates = s:get_candidates_from_data(g:hidemac_builtin.configs.data)
  return s:stringify_candidates(a:args[0],l:candidates)
endfunction"}}}
function! s:special_functions.filter(i, args) abort"{{{
  if a:i == 0
    return s:stringify_candidates(a:args[a:i],
          \	[{'word': 'HmFilter', 'menu': '標準の変換モジュール'}])
  elseif a:i == 1
    if a:args[0] =~ '^""' || a:args[0] =~ '^"HmFilter"'
      call s:load_filters()
      let l:candidates = s:get_candidates_from_data(g:hidemac_builtin.filters.data)
      return s:stringify_candidates(a:args[1], l:candidates)
    endif
  elseif a:i == 2
    if a:args[1] =~ '^"To\(Space\|Tab\)"'
      return s:stringify_candidates(a:args[a:i],
            \ [{'word': '1', 'menu': '範囲指定を無視して計算する'}])
    endif
  endif
  return []
endfunction"}}}
function! s:special_functions.loaddll(i, args) abort"{{{
  if a:i > 0
    return []
  endif
  if a:args[a:i] =~ '^"' " 文字列リテラルをかぃてる
    return [{'word': 'hmjre.dll'}]
  endif
  " ぃまのところ文字列リテラルじゃなぃ
  return filter(s:variables('$'), 'v:val.menu =~ "\\.dll"')
        \ + s:stringify_candidates(a:args[a:i],	[{'word': 'hmjre.dll'}])
        \ + s:keywords('$')
        \ + s:functions('$')
endfunction"}}}
function! s:special_functions.dllfunc(i, args) abort"{{{
  let l:loaded_dll = ''
  let l:id_specified = 0
  let l:i = a:i
  if l:i >= 1
    if a:args[0] =~ '^#' || a:args[0] =~ 'loaddll('
    " 最初の引数に数値型がぁる場合特別
      if a:args[0] =~ '^#'
        " 数値型変数名だったらloaddll()関数の返り値(dllの識別子)が代入されてるはず
        for l:var in s:variables('#')
          if a:args[0] == l:var.word
            let l:loaded_dll = matchstr(l:var.menu, 'loaddll("\zs.\{-}\ze\.dll')
            if l:loaded_dll != ''
              break
            endif
          endif
        endfor
      elseif a:args[0] =~ 'loaddll('
        let l:loaded_dll = matchstr(a:args[0], 'loaddll("\zs.\{-}\ze\.dll')
      endif
      let l:i = l:i - 1
      let l:id_specified = 1
    endif
  endif
  if !l:id_specified
    " loaddll文のdllをみっける
    for l:lnum in range(line('.'), 1, -1) + range(line('$'), line('.') + 1, -1)
      let l:line = getline(l:lnum)
      let l:loaddll_arg = matchstr(l:line, 'loaddll\s\zs[^;]\{-}\ze;', 0, l:i)
      if l:loaddll_arg != ''
        let l:dll_pattern = '"\zs[^\.]\{-}\ze\.dll"'
        if l:loaddll_arg =~ '^\$'
          for l:var in s:variables('$')
            if l:var.word == l:loaddll_arg
              let l:loaded_dll = matchstr(l:var.menu, l:dll_pattern)
              break
            endif
          endfor
        else
          let l:loaded_dll = matchstr(l:loaddll_arg, l:dll_pattern)
        endif
        break
      endif
    endfor
  endif
  if l:i == 0
    let l:candidates = []
    if !l:id_specified
      " loaddll()関数の返り値が代入されてるっぽぃ変数をぜんぶ拾って候補に出す
      let l:vars = s:variables('#')
      call filter(l:vars, 'v:val.menu =~ "\\s*=\\s*loaddll("')
      let l:candidates = l:candidates + l:vars
    endif

    let l:dllfunc_names = []
    if l:loaded_dll != '' && has_key(s:load_dllfuncs, l:loaded_dll)
      " dllの関数名を候補に出す
      call s:load_dllfuncs[l:loaded_dll]()
      let l:candidates = l:candidates + s:stringify_candidates(
            \ a:args[a:i],
            \ s:get_candidates_from_data(g:hidemac_dlls[l:loaded_dll])
            \)
    endif
    return l:candidates + s:expressions('$')
  else
    if l:loaded_dll != '' && has_key(s:load_dllfuncs, l:loaded_dll)
      " 指定されてるdllがゎかった
      let l:candidates = []
      call s:load_dllfuncs[l:loaded_dll]()
      let l:dllfunc_name = substitute(a:args[l:id_specified], '"', '', 'g')
      if has_key(g:hidemac_dlls[l:loaded_dll], l:dllfunc_name)
        " dllの関数名もゎかった
        let l:arg_types = g:hidemac_dlls[l:loaded_dll][l:dllfunc_name].arg_types
        if (l:i - 1) < len(l:arg_types)
          let l:type = l:arg_types[l:i - 1]
          " 引数の型がゎかった
          let l:candidates = s:expressions(l:type)
        else
          " 仕様ょり引数多く入力しょーとしてる
          return []
        endif
      endif
      if empty(l:candidates)
        " しらなぃdllとかで引数の情報がなぃ
        let l:candidates = s:expressions()
      endif
      " 数値型変数名の候補からdll識別子が代入されてるのゎ除外する
      return filter(l:candidates, 'v:val.menu !~ "\\s*=\\s*loaddll("')
    endif
  endif
  return []
endfunction"}}}
function! s:special_functions.dllfuncstr(i, args) abort"{{{
  return s:special_functions.dllfunc(a:i, a:args)
endfunction"}}}
function! s:special_functions.dllfuncw(i, args) abort"{{{
  return s:special_functions.dllfunc(a:i, a:args)
endfunction"}}}
function! s:special_functions.dllfuncstrw(i, args) abort"{{{
  return s:special_functions.dllfunc(a:i, a:args)
endfunction"}}}

let s:special_statements = {}
function! s:special_statements.loaddll(i, args) abort"{{{
  return s:special_functions.loaddll(a:i, a:args)
endfunction"}}}
function! s:special_statements.execmacro(i, args) abort"{{{
  if a:i == 0
    if !exists("g:hidemac_macro_dir") || !isdirectory(g:hidemac_macro_dir)
      return s:expressions('$')
    endif
    let l:files = glob(g:hidemac_macro_dir . '\*.mac', 1, 1)
          \	+ glob(g:hidemac_macro_dir . '\**\*.mac', 1, 1)
    let l:relative_pos = len(g:hidemac_macro_dir) + 1
    call map(l:files,
          \ '{ "word" : v:val[l:relative_pos :], '
          \ . '"menu" : g:hidemac_macro_dir }')
    return s:stringify_candidates(a:args[a:i], l:files) + s:expressions('$')
  elseif a:i == 1
    return s:expressions('$')
  endif
  return []
endfunction"}}}
function! s:special_statements.goto(i, args) abort"{{{
  if a:i > 0
    return []
  endif
  return s:labels()
endfunction"}}}
function! s:special_statements.call(i, args) abort"{{{
  " 文ゎふっぅ名前の後に引数カンマ区切りだけど、
  " callゎ例外だと思ぅたぶん
  " call Label $arg1, #arg2
  " てかんじだからラベル名の後にゎカンマがこなぃ
  let l:label_arg = matchstr(a:args[0], '^.\{-}\ze ')
  if l:label_arg == ''
    let l:args = a:args
  else
    let l:args = [
          \ matchstr(a:args[0], '^.\{-}\ze '),
          \ matchstr(a:args[0], ' \zs.*$')
          \]
    if len(a:args) > 1
      let l:args = l:args + a:args[1:]
    endif
  endif
  
  let l:i = len(l:args) - 1
  if l:i == 0
    return s:labels()
  endif
  if l:i > 9
    return []
  endif
  " 呼ぼーとしてるサブルーチンをさがす
  let l:in_target_sub = 0
  let l:type = '?'
  for l:lnum in range(1, line('$'))
    let l:line = getline(l:lnum)
    if l:line =~ '^\s*' . l:args[0] . ':'
      let l:in_target_sub = 1
      continue
    endif
    if l:in_target_sub
      " 呼ぼーとしてるサブルーチンの中で引数っぽぃものをさがす
      let l:arg = matchstr(l:line, '[$#]\{2}' . string(l:i))
      if l:arg != ''
        let l:type = l:arg[0]
        break
      endif
    endif
    if l:line =~ '^\s*return;' && l:in_target_sub
      break
    endif
  endfor
  return s:expressions(l:type)
endfunction"}}}
function! s:gather_candidates(cur_line, cur_text) abort"{{{
  let l:ctx = s:get_context(a:cur_line)
  echomsg 'ctx: ' . l:ctx
  
  let l:ks = split(l:ctx, '[^a-zA-Z0-9_#$]\+', 1)
  if len(l:ks) == 1
    " 文、変数
    return s:variables() + s:statements()
  elseif l:ctx =~ '^}\s*'
    " ブロックが閉じてる後
    return s:get_after_block(l:ctx)
  elseif l:ctx =~ '[#$]\k\+\[\s*$'
    " 配列のキーをかきはじめるとこ
    return s:expressions('#')
  elseif l:ctx =~ '#\k\+\s*=\s*$'
    " 数値型変数に代入するとこ
    return s:expressions('#')
  elseif l:ctx =~ '$\k\+\s*=\s*$'
    " 文字列型変数に代入するとこ
    return s:expressions('$')
  elseif l:ctx =~ '\([-*/%<>!^]\|<=\|>=\|\(&\)\@<!&\|\(|\)\@<!|\)\s*$'
    " - * / % < > ! ^ <= >= & |
    " 数値型だけでできるっぽぃ演算子の直後
    return s:expressions('#')
  elseif l:ctx =~ '\(+\|!=\|==\)\s*$'
    " 文字列型かもしれなぃ演算子の直後
    return s:expressions(s:get_last_type(substitute(l:ctx, '\(+\|!=\|==\)\s*$', '', '')))
  elseif l:ctx =~ '[#$]\k\+\s*$'
    " 変数名を入力しぉゎってるけどその次のイコールとか打ってなぃ
    return []
  else
    " 関数か文の引数
    let l:line = s:stash_strings(l:ctx)
    let [l:function_name, l:comma_count] = s:analyze_function(l:line)
    if l:function_name != '' && has_key(g:hidemac_builtin.functions.data, l:function_name)
      " 関数の引数
      if has_key(s:special_functions, l:function_name)
        " 特別な補完候補の用意がぁる
        let l:args_text = l:ctx[strridx(l:ctx, l:function_name . '(') + len(l:function_name) + 1 :]
        let l:args = s:split_arguments(l:args_text)
        return s:special_functions[l:function_name](len(l:args) - 1, l:args)
      endif
      " 特別じゃなくただ型で候補をだす
      let l:arg_types = g:hidemac_builtin.functions.data[l:function_name].args.types
      if l:comma_count >= len(l:arg_types)
        return []
      endif
      return s:expressions(l:arg_types[l:comma_count])
    elseif has_key(g:hidemac_builtin.statements.data, l:ks[0])
      let l:statement_name = l:ks[0]
      if l:ctx =~ '^' . l:statement_name . '$'
        " 文の名前ゎかきぉゎってんだけどスペースゎ打ってなぃ
        return []
      endif
      " 文の引数かく場面なんだけどまだ演算子とか関数とかゎかぃてなぃ系
      if has_key(s:special_statements, l:statement_name)
        " 特別な補完候補の用意がぁる
        let l:args_text = substitute(l:ctx, '^' . l:statement_name, ' ', '')
        let l:args = s:split_arguments(l:args_text)
        return s:special_statements[l:statement_name](len(l:args) - 1, l:args)
      endif
      return s:expressions()
    endif
  endif
  return s:expressions()
endfunction"}}}

call s:set_hidemac_chm_dir()
call s:set_hidemac_doc_dir()
call s:chm2html()
call s:load_statements()
call s:load_functions()
call s:load_keywords()
call s:load_dlls()

let g:hidemac_macro_dir = 'C:\Users\color_000\AppData\Roaming\Hidemaruo\Hidemaru\Macro'

function! s:sort_candidates(l, r) abort"{{{
  let l = a:l.pos
  let r = a:r.pos
  return l == r ? 0 : l > r ? 1 : -1
endfunction"}}}
function! CompleteHidemac(findstart, base)"{{{
  if a:findstart
    let l:line = getline('.')
    let l:start = col('.') - 1
    while l:start >= 0 && l:line[l:start - 1] =~ '\%(\k\|[$#_]\)'
      let l:start -= 1
    endwhile
    let b:cur_text = l:line[l:start :]
    let b:cur_line = l:line[0: l:start - 1]
    return l:start
  endif
  
  let l:candidates = s:gather_candidates(substitute(b:cur_line, '^\s\+', "", "g"), b:cur_text)

  if a:base == ""
    return l:candidates
  endif

  let l:matches = []
  for k in l:candidates
    " 行頭からの完全一致だと、変数名の最初の#$とか、
    " 文字列リテラルのダブルクオートが候補に入ってると、
    " それをぃち②打っのめんどぃから、ここで調整
    " ちな、ファジーでゎなぃ ぁくまでマッチの開始位置にこだゎらなぃだけ
    let k.pos = stridx(k.word, b:cur_text)
    if k.pos == -1
      continue
    endif
    " どっかにマッチゎした
    if k.word =~ '^[$#"]' && b:cur_text !~ '^[$#"]'
      " 候補が記号ではじまってんだけど入力にゎ記号がなかった場合、
      " マッチした位置を1文字分有利(上のほーにくる)にする
      let k.pos = k.pos - 1
    endif
    call add(l:matches, k)
  endfor
  " マッチした位置でソートする関数に渡す
  " 左でマッチした候補ほど上に出る
  return sort(l:matches, function("s:sort_candidates"))
endfunction"}}}

setlocal omnifunc=CompleteHidemac

setlocal cindent
