let g:hidemac_builtin = get(g:, 'hidemac_builtin', {})

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

function! s:load_keywords() abort
  if exists('g:hidemac_builtin') && has_key(g:hidemac_builtin, 'keywords')
    return
  endif
  let l:candidates = []
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
            \ 'menu' : '(Keyword) ' . l:menu
            \})
      call add(l:list, l:word)
      let desc = ''
    endfor
  endfor
  let g:hidemac_builtin.keywords = {
        \ 'candidates': l:candidates,
        \ 'data': l:list
        \}
endfunction

function! s:some_match(str, patterns) abort
  for pat in a:patterns
    if a:str =~ pat
      return 1
    endif
  endfor
  return 0
endfunction

function! s:load_functions() abort
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
          \ 'arg_labels': l:func[2],
          \ 'arg_types': l:arg_types
          \}
  endfor
  let g:hidemac_builtin.functions = {
        \ 'candidates': l:candidates,
        \ 'data': l:dict
        \}
endfunction

function! s:get_cmd_statements() abort
  let l:candidates = []
  let l:dict = {}
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
      call add(l:candidates, {
            \ 'word' : l:word,
            \ 'menu' : '(Statement) ' . s:trim(l:desc)
            \})
      let l:dict[l:word] = []
      let desc = ''
    endfor
  endfor
  return [l:candidates, l:dict]
endfunction

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

function! s:get_other_statements() abort
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
    
    for l:file in glob(s:hidemac_extract_dir . '\html\'	. l:doc_num . '_*.html', 1, 1)
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
            \ 'menu' : '(Statement) ' . l:desc
            \})
        let l:dict[l:word] = []
      endfor
    endfor
  endfor
  
  let l:candidates = l:candidates + [
        \{'word': 'refreshdatetime',
        \ 'menu': '(Statement) 日付と時刻を表すキーワードの値を更新する'},
        \{'word': 'goto',
        \	'menu': '(Statement) マクロの処理を任意の場所に移動させる'},
        \{'word': 'call',
        \	'menu': '(Statement) サブルーチンを呼ぶ'},
        \{'word': 'return',
        \	'menu': '(Statement) サブルーチンから復帰する'}
        \]
  let l:dict['refreshdatetime'] = []
  let l:dict['goto'] = []
  let l:dict['call'] = []
  let l:dict['return'] = []
  return [l:candidates, l:dict]
endfunction

function! s:load_statements() abort
  if exists('g:hidemac_builtin') && has_key(g:hidemac_builtin, 'statements')
    return
  endif
  let g:hidemac_builtin.statements = {}
  let [l:cmd_candidates, l:cmd_data] = s:get_cmd_statements()
  let [l:other_candidates, l:other_data] = s:get_other_statements()
  let g:hidemac_builtin.statements.candidates = l:cmd_candidates + l:other_candidates
  let g:hidemac_builtin.statements.data = extend(l:cmd_data, l:other_data)
endfunction

function! s:statements() abort
  return g:hidemac_builtin.statements.candidates
endfunction

function! s:functions() abort
  return g:hidemac_builtin.functions.candidates
endfunction

function! s:keywords() abort
  return g:hidemac_builtin.keywords.candidates
endfunction

function! s:expressions(...) abort
  if a:0 == 0 || a:1 == '' || a:1 == '?'
    return s:variables() + s:keywords() + s:functions()
  endif
  if a:1 == '#'
    return filter(copy(s:variables()), 'v:val.word =~ "^#"')
            \ + filter(copy(s:keywords()), 'v:val.kind != "$"')
            \ + filter(copy(s:functions()), 'v:val.kind != "$"')
  elseif a:1 == '$'
    return filter(copy(s:variables()), 'v:val.word =~ "^\\$"')
            \ + filter(copy(s:keywords()), 'v:val.kind != "#"')
            \ + filter(copy(s:functions()), 'v:val.kind != "#"')
  endif
endfunction

function! s:variables() abort
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
    
    if l:line =~ '^\s*[$#]'
      if l:in_other_sub && l:line =~ '^\s*[$#]\{2\}' " local var in other sub
        continue
      endif
      call add(l:candidates, {'word': matchstr(l:line, '^\s*\zs[$#][^ \=]*\ze')})
    endif
  endfor
  if l:call_found
    let l:candidates = l:candidates + [{'word': '$$return'}, {'word': '##return'}]
  endif
  return l:candidates
endfunction

function! s:get_after_block(ctx) abort
  if strridx(a:ctx, '(') > strridx(a:ctx, ')')
    " else ifの条件のかくカッコの中にぃる
    return s:expressions()
  elseif a:ctx =~ '^}\s*else\s\+$'
    " } else ってかぃたとこ
    return [{
          \ 'word': 'if',
          \ 'menu': '(Statement) その直後にある条件式が０以外の場合に次のコマンドを実行します。'
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
      return [{'word': 'else', 'menu': '(Statement)'}]
    endif
    return []
  endif
  return []
endfunction

let s:str_patterns = {'''': '''.\{-}\(\\\)\@<!''', '"': '".\{-}\(\\\)\@<!"'}
function! s:get_context(line) abort
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
endfunction

function! s:stash_strings(line) abort
  let l:line = a:line
  while 1
    " ダブルクオートかクオートがひらくとこをさがす
    let l:q_open_pos = match(l:line, '\(\\\)\@<!["'']')
    if l:q_open_pos == -1
      break
    endif
    " 開ぃてたから、閉じるとこまでを置き換ぇる
    let l:q = l:line[l:q_open_pos]
    let l:line = substitute(l:line, s:str_patterns[l:q], '$$str')
  endwhile
  return l:line
endfunction

function! s:analyze_brace(line, target_level) abort
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
endfunction

function! s:analyze_function(line, ...) abort
  " デフォでゎ、ぃま引数をかぃてる関数の名前を取る
  let l:target_level = -1
  if a:0 == 1 && a:1 == 'last'
    " lastだと、もぅかきぉゎってカーソルょり左にぁる中で最も右の関数の名前
    let l:target_level = 0
  endif
  let [l:pos, l:comma_count] = s:analyze_brace(a:line, l:target_level)
  return [matchstr(a:line[: l:pos - 1], '[a-zA-Z0-9_$#]\+$'), l:comma_count]
endfunction

function! s:get_last_type(ctx) abort
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
      else
        for data in s:keywords()
          if data.word == l:k
            return data.kind
          endif
        endfor
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
endfunction

function! s:gather_candidates(cur_line, cur_text) abort
  let l:ctx = s:get_context(a:cur_line)
  echomsg 'ctx: ' . l:ctx
  
  let l:ks = split(l:ctx, '[^a-zA-Z0-9_#$]\+', 1)
  if len(l:ks) == 1
    " 文、変数
    return s:variables() + s:statements()
  elseif l:ctx =~ '^}\s*'
    " ブロックが閉じてる後
    return s:get_after_block(l:ctx)
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
  else
    " 関数か文の引数
    let l:line = s:stash_strings(l:ctx)
    let [l:function_name, l:comma_count] = s:analyze_function(l:line)
    if l:function_name != '' && has_key(g:hidemac_builtin.functions.data, l:function_name)
      " 関数の引数
      let l:arg_types = g:hidemac_builtin.functions.data[l:function_name].arg_types
      if l:comma_count >= len(l:arg_types)
        return []
      endif
      return s:expressions(
          \ g:hidemac_builtin.functions.data[l:function_name].arg_types[l:comma_count]
          \)
    elseif has_key(g:hidemac_builtin.statements.data, l:ks[0])
      " 文の引数かく場面なんだけどまだ演算子とか関数とかゎかぃてなぃ系
      return s:expressions()
    endif
  endif
  return s:expressions()
endfunction

call s:set_hidemac_chm_dir()
call s:set_hidemac_doc_dir()
call s:chm2html()
call s:load_statements()
call s:load_functions()
call s:load_keywords()

function! HidemacOmniComplete(findstart, base)
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
    if strpart(k.word, 0, strlen(a:base)) == a:base
      call add(l:matches, k)
    endif
  endfor
  
  return l:matches
endfunction

setlocal omnifunc=HidemacOmniComplete
