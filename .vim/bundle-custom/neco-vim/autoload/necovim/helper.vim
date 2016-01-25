"=============================================================================
" FILE: helper.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim

if !exists('s:internal_candidates_list')
  let s:internal_candidates_list = {}
  let s:global_candidates_list = {
        \ 'dictionary_variables' : {}, 'runtimepath' : &runtimepath }
  let s:script_candidates_list = {}
  let s:local_candidates_list = {}
endif

let s:dictionary_path =
      \ substitute(fnamemodify(expand('<sfile>'), ':h'), '\\', '/', 'g')

function! necovim#helper#make_cache() "{{{
  if &filetype !=# 'vim'
    return
  endif

  let s:script_candidates_list[bufnr('%')] =
        \ s:get_script_candidates(bufnr('%'))
endfunction"}}}

function! necovim#helper#get_command_completion(command_name, cur_text, complete_str) "{{{
  let completion_name =
        \ necovim#helper#get_completion_name(a:command_name)
  if completion_name == ''
    " Not found.
    return []
  endif

  let args = (completion_name ==# 'custom' ||
        \     completion_name ==# 'customlist')?
        \ [a:command_name, a:cur_text, a:complete_str] :
        \ [a:cur_text, a:complete_str]
  return call('necovim#helper#'
        \ .completion_name, args)
endfunction"}}}
function! necovim#helper#get_completion_name(command_name) "{{{
  if !has_key(s:internal_candidates_list, 'command_completions')
    let s:internal_candidates_list.command_completions =
          \ s:make_cache_completion_from_dict('command_completions')
  endif
  if s:check_global_candidates('command_completions')
    let s:global_candidates_list.commands = s:get_cmdlist()
  endif

  if has_key(s:internal_candidates_list.command_completions, a:command_name)
        \&& exists('*necovim#helper#'
        \ .s:internal_candidates_list.command_completions[a:command_name])
    return s:internal_candidates_list.command_completions[a:command_name]
  elseif has_key(s:global_candidates_list.command_completions, a:command_name)
        \&& exists('*necovim#helper#'
        \ .s:global_candidates_list.command_completions[a:command_name])
    return s:global_candidates_list.command_completions[a:command_name]
  else
    return ''
  endif
endfunction"}}}

function! necovim#helper#autocmd_args(cur_text, complete_str) "{{{
  let args = s:split_args(a:cur_text, a:complete_str)
  if len(args) < 2
    return []
  endif

  " Make cache.
  if s:check_global_candidates('augroups')
    let s:global_candidates_list.augroups = s:get_augrouplist()
  endif
  if !has_key(s:internal_candidates_list, 'autocmds')
    let s:internal_candidates_list.autocmds = s:make_cache_autocmds()
  endif

  let list = []
  if len(args) == 2
    let list += copy(s:internal_candidates_list.autocmds) +
          \ copy(s:global_candidates_list.augroups)
  elseif len(args) == 3
    if args[1] ==# 'FileType'
      " Filetype completion.
      let list +=
            \ necovim#helper#filetype(
            \   a:cur_text, a:complete_str)
    endif

    let list += s:internal_candidates_list.autocmds
  elseif len(args) == 4
    if args[2] ==# 'FileType'
      " Filetype completion.
      let list += necovim#helper#filetype(
            \ a:cur_text, a:complete_str)
    endif

    let list += necovim#helper#command(
          \ args[3], a:complete_str)
    let list += s:make_completion_list(['nested'])
  else
    let command = args[3] =~ '^*' ?
          \ join(args[4:]) : join(args[3:])
    let list += necovim#helper#command(
          \ command, a:complete_str)
    let list += s:make_completion_list(['nested'])
  endif

  return list
endfunction"}}}
function! necovim#helper#augroup(cur_text, complete_str) "{{{
  " Make cache.
  if s:check_global_candidates('augroups')
    let s:global_candidates_list.augroups = s:get_augrouplist()
  endif

  return copy(s:global_candidates_list.augroups)
endfunction"}}}
function! necovim#helper#buffer(cur_text, complete_str) "{{{
  return []
endfunction"}}}
function! necovim#helper#colorscheme_args(cur_text, complete_str) "{{{
  return s:make_completion_list(map(split(
        \ globpath(&runtimepath, 'colors/*.vim'), '\n'),
        \ 'fnamemodify(v:val, ":t:r")'))
endfunction"}}}
function! necovim#helper#command(cur_text, complete_str) "{{{
  echomsg string(a:cur_text)
  if a:cur_text == '' ||
        \ a:cur_text =~ '^[[:digit:],[:space:][:tab:]$''<>]*\h\w*$'
    " Commands.
    echomsg "Commands"

    " Make cache.
    if s:check_global_candidates('commands')
      let s:global_candidates_list.commands = s:get_cmdlist()
    endif
    if !has_key(s:internal_candidates_list, 'commands')
      let s:internal_candidates_list.commands = s:make_cache_commands()
    endif

    let list = copy(s:internal_candidates_list.commands)
          \ + copy(s:global_candidates_list.commands)
  else
    " Commands args.
    echomsg "Commands args"
    let command = necovim#get_command(a:cur_text)
    let completion_name =
          \ necovim#helper#get_completion_name(command)

    " Prevent infinite loop.
    let cur_text = completion_name ==# 'command' ?
          \ a:cur_text[len(command):] : a:cur_text

    let list = necovim#helper#get_command_completion(
          \ command, cur_text, a:complete_str)

    if a:cur_text =~
          \'[[(,{]\|`=[^`]*$'
      " Expression.
      let list += necovim#helper#expression(
            \ a:cur_text, a:complete_str)
    endif
  endif

  return list
endfunction"}}}
function! necovim#helper#command_args(cur_text, complete_str) "{{{
  " Make cache.
  if !has_key(s:internal_candidates_list, 'command_args')
    let s:internal_candidates_list.command_args =
          \ s:make_completion_list(
          \   readfile(s:dictionary_path . '/command_args.dict'))
    let s:internal_candidates_list.command_replaces =
          \ s:make_completion_list(
        \ ['<line1>', '<line2>', '<count>', '<bang>',
        \  '<reg>', '<args>', '<lt>', '<q-args>', '<f-args>'])
  endif

  return s:internal_candidates_list.command_args +
        \ s:internal_candidates_list.command_replaces
endfunction"}}}
function! necovim#helper#custom(command_name, cur_text, complete_str) "{{{
  if !has_key(g:necovim#complete_functions, a:command_name)
    return []
  endif

  return s:make_completion_list(split(
        \ call(g:necovim#complete_functions[a:command_name],
        \ [a:complete_str, getline('.'), len(a:cur_text)]), '\n'))
endfunction"}}}
function! necovim#helper#customlist(command_name, cur_text, complete_str) "{{{
  if !has_key(g:necovim#complete_functions, a:command_name)
    return []
  endif

  " Ignore error
  try
    let result = call(g:necovim#complete_functions[a:command_name],
          \ [a:complete_str, getline('.'), len(a:cur_text)])
  catch
    let result = []
  endtry

  return s:make_completion_list(result)
endfunction"}}}
function! necovim#helper#dir(cur_text, complete_str) "{{{
  " Todo.
  return []
endfunction"}}}
function! necovim#helper#environment(cur_text, complete_str) "{{{
  " Make cache.
  if s:check_global_candidates('environments')
    let s:global_candidates_list.environments = s:get_envlist()
  endif

  return copy(s:global_candidates_list.environments)
endfunction"}}}
function! necovim#helper#event(cur_text, complete_str) "{{{
  return []
endfunction"}}}
function! necovim#helper#execute(cur_text, complete_str) "{{{
  let candidates = necovim#helper#expression(a:cur_text, a:complete_str)
  if a:cur_text =~ '["''][^"''[:space:]]*$'
    let command = matchstr(a:cur_text, '["'']\zs[^"'']*$')
    let candidates += necovim#helper#command(command, a:complete_str)
  endif

  return candidates
endfunction"}}}
function! necovim#helper#expand(cur_text, complete_str) "{{{
  return s:make_completion_list(
        \ ['<cfile>', '<afile>', '<abuf>', '<amatch>',
        \  '<sfile>', '<cword>', '<cWORD>', '<client>'])
endfunction"}}}
function! necovim#helper#expression(cur_text, complete_str) "{{{
  return necovim#helper#function(a:cur_text, a:complete_str)
        \+ necovim#helper#var(a:cur_text, a:complete_str)
endfunction"}}}
function! necovim#helper#feature(cur_text, complete_str) "{{{
  if !has_key(s:internal_candidates_list, 'features')
    let s:internal_candidates_list.features = s:make_cache_features()
  endif
  return copy(s:internal_candidates_list.features)
endfunction"}}}
function! necovim#helper#file(cur_text, complete_str) "{{{
  " Todo.
  return []
endfunction"}}}
function! necovim#helper#filetype(cur_text, complete_str) "{{{
  if !has_key(s:internal_candidates_list, 'filetypes')
    let s:internal_candidates_list.filetypes =
          \ s:make_completion_list(map(
          \ split(globpath(&runtimepath, 'syntax/*.vim'), '\n') +
          \ split(globpath(&runtimepath, 'indent/*.vim'), '\n') +
          \ split(globpath(&runtimepath, 'ftplugin/*.vim'), '\n')
          \ , "matchstr(fnamemodify(v:val, ':t:r'), '^[[:alnum:]-]*')"))
  endif

  return copy(s:internal_candidates_list.filetypes)
endfunction"}}}
function! necovim#helper#function(cur_text, complete_str) "{{{
  " Make cache.
  if s:check_global_candidates('functions')
    let s:global_candidates_list.functions = s:get_functionlist()
  endif
  if !has_key(s:internal_candidates_list, 'functions')
    let s:internal_candidates_list.functions = s:make_cache_functions()
  endif

  let script_functions = values(s:get_cached_script_candidates().functions)
  if a:complete_str =~ '^s:'
    let list = script_functions
  elseif a:complete_str =~ '^\a:'
    let list = deepcopy(script_functions)
    for keyword in list
      let keyword.word = '<SID>' . keyword.word[2:]
      let keyword.abbr = '<SID>' . keyword.abbr[2:]
    endfor
  else
    let list = copy(s:internal_candidates_list.functions)
          \ + copy(s:global_candidates_list.functions)
          \ + script_functions
    for functions in map(values(s:script_candidates_list), 'v:val.functions')
      let list += values(filter(copy(functions), 'v:val.word[:1] !=# "s:"'))
    endfor
  endif

  return list
endfunction"}}}
function! necovim#helper#help(cur_text, complete_str) "{{{
  return []
endfunction"}}}
function! necovim#helper#highlight(cur_text, complete_str) "{{{
  return []
endfunction"}}}
function! necovim#helper#let(cur_text, complete_str) "{{{
  if a:cur_text !~ '='
    return necovim#helper#var(a:cur_text, a:complete_str)
  elseif a:cur_text =~# '\<let\s\+&\%([lg]:\)\?filetype\s*=\s*'
    " FileType.
    return necovim#helper#filetype(a:cur_text, a:complete_str)
  else
    return necovim#helper#expression(a:cur_text, a:complete_str)
  endif
endfunction"}}}
function! necovim#helper#mapping(cur_text, complete_str) "{{{
  " Make cache.
  if s:check_global_candidates('mappings')
    let s:global_candidates_list.mappings = s:get_mappinglist()
  endif
  if !has_key(s:internal_candidates_list, 'mappings')
    let s:internal_candidates_list.mappings =
          \ s:make_completion_list(
          \   readfile(s:dictionary_path . '/mappings.dict'))
  endif

  let list = copy(s:internal_candidates_list.mappings) +
        \ copy(s:global_candidates_list.mappings)

  if a:cur_text =~ '<expr>'
    let list += necovim#helper#expression(a:cur_text, a:complete_str)
  elseif a:cur_text =~ ':<C-u>\?'
    let command = matchstr(a:cur_text, ':<C-u>\?\zs.*$')
    let list += necovim#helper#command(command, a:complete_str)
  endif

  return list
endfunction"}}}
function! necovim#helper#menu(cur_text, complete_str) "{{{
  return []
endfunction"}}}
function! necovim#helper#option(cur_text, complete_str) "{{{
  " Make cache.
  if !has_key(s:internal_candidates_list, 'options')
    let s:internal_candidates_list.options = s:make_cache_options()
  endif

  if a:cur_text =~ '\<set\%[local]\s\+\%(filetype\|ft\)='
    return necovim#helper#filetype(a:cur_text, a:complete_str)
  else
    return copy(s:internal_candidates_list.options)
  endif
endfunction"}}}
function! necovim#helper#shellcmd(cur_text, complete_str) "{{{
  return []
endfunction"}}}
function! necovim#helper#tag(cur_text, complete_str) "{{{
  return []
endfunction"}}}
function! necovim#helper#tag_listfiles(cur_text, complete_str) "{{{
  return []
endfunction"}}}
function! necovim#helper#var_dictionary(cur_text, complete_str) "{{{
  let var_name = matchstr(a:cur_text,
        \'\%(\a:\)\?\h\w*\ze\.\%(\h\w*\%(()\?\)\?\)\?$')
  let list = []
  if a:cur_text =~ '[btwg]:\h\w*\.\%(\h\w*\%(()\?\)\?\)\?$'
    let list = has_key(s:global_candidates_list.dictionary_variables, var_name) ?
          \ values(s:global_candidates_list.dictionary_variables[var_name]) : []
  elseif a:cur_text =~ 's:\h\w*\.\%(\h\w*\%(()\?\)\?\)\?$'
    let list = values(get(s:get_cached_script_candidates().dictionary_variables,
          \ var_name, {}))
  endif

  return list
endfunction"}}}
function! necovim#helper#var(cur_text, complete_str) "{{{
  " Make cache.
  if s:check_global_candidates('variables')
    let s:global_candidates_list.variables =
          \ s:get_variablelist(g:, 'g:') + s:get_variablelist(v:, 'v:')
          \ + s:make_completion_list(['v:val'])
  endif

  if a:complete_str =~ '^[swtb]:'
    let list = values(s:get_cached_script_candidates().variables)
    if a:complete_str !~ '^s:'
      let prefix = matchstr(a:complete_str, '^[swtb]:')
      let list += s:get_variablelist(eval(prefix), prefix)
    endif
  elseif a:complete_str =~ '^[vg]:'
    let list = copy(s:global_candidates_list.variables)
  else
    let list = s:get_local_variables()
  endif

  return list
endfunction"}}}

function! s:get_local_variables() "{{{
  " Get local variable list.

  let keyword_dict = {}
  " Search function.
  let line_num = line('.') - 1
  let end_line = (line('.') > 100) ? line('.') - 100 : 1
  while line_num >= end_line
    let line = getline(line_num)
    if line =~ '\<endf\%[unction]\>'
      break
    elseif line =~ '\<fu\%[nction]!\?\s\+'
      " Get function arguments.
      call s:analyze_variable_line(line, keyword_dict)
      break
    endif

    let line_num -= 1
  endwhile
  let line_num += 1

  let end_line = line('.') - 1
  while line_num <= end_line
    let line = getline(line_num)

    if line =~ '\<\%(let\|for\)\s\+'
      if line =~ '\<\%(let\|for\)\s\+s:' &&
            \ has_key(s:script_candidates_list, bufnr('%'))
            \ && has_key(s:script_candidates_list[bufnr('%')], 'variables')
        let candidates_list = s:script_candidates_list[bufnr('%')].variables
      else
        let candidates_list = keyword_dict
      endif

      call s:analyze_variable_line(line, candidates_list)
    endif

    let line_num += 1
  endwhile

  return values(keyword_dict)
endfunction"}}}

function! s:get_cached_script_candidates() "{{{
  return has_key(s:script_candidates_list, bufnr('%')) ?
        \ s:script_candidates_list[bufnr('%')] : {
        \   'functions' : {}, 'variables' : {},
        \   'function_prototypes' : {}, 'dictionary_variables' : {} }
endfunction"}}}
function! s:get_script_candidates(bufnumber) "{{{
  " Get script candidate list.

  let function_dict = {}
  let variable_dict = {}
  let dictionary_variable_dict = {}
  let function_prototypes = {}
  let var_pattern = '\a:[[:alnum:]_:]*\.\h\w*\%(()\?\)\?'

  for line in getbufline(a:bufnumber, 1, '$')
    if line =~ '\<fu\%[nction]!\?\s\+'
      call s:analyze_function_line(
            \ line, function_dict, function_prototypes)
    elseif line =~ '\<let\s\+'
      " Get script variable.
      call s:analyze_variable_line(line, variable_dict)
    elseif line =~ var_pattern
      while line =~ var_pattern
        let var_name = matchstr(line, '\a:[[:alnum:]_:]*\ze\.\h\w*')
        let candidates_dict = dictionary_variable_dict
        if !has_key(candidates_dict, var_name)
          let candidates_dict[var_name] = {}
        endif

        call s:analyze_dictionary_variable_line(
              \ line, candidates_dict[var_name], var_name)

        let line = line[matchend(line, var_pattern) :]
      endwhile
    endif
  endfor

  return { 'functions' : function_dict, 'variables' : variable_dict,
        \ 'function_prototypes' : function_prototypes,
        \ 'dictionary_variables' : dictionary_variable_dict }
endfunction"}}}

function! s:make_cache_completion_from_dict(dict_name) "{{{
  let dict_files = split(globpath(&runtimepath,
        \ 'autoload/necovim/'.a:dict_name.'.dict'), '\n')
  if empty(dict_files)
    return {}
  endif

  let keyword_dict = {}
  for line in readfile(dict_files[0])
    let word = matchstr(line, '^[[:alnum:]_\[\]]\+')
    let completion = matchstr(line[len(word):], '\h\w*')
    if completion != ''
      if word =~ '\['
        let [word_head, word_tail] = split(word, '\[')
        let word_tail = ' ' . substitute(word_tail, '\]', '', '')
      else
        let word_head = word
        let word_tail = ' '
      endif

      for i in range(len(word_tail))
        let keyword_dict[word_head . word_tail[1:i]] = completion
      endfor
    endif
  endfor

  return keyword_dict
endfunction"}}}
function! s:make_cache_prototype_from_dict(dict_name) "{{{
  let dict_files = split(globpath(&runtimepath,
        \ 'autoload/necovim/'.a:dict_name.'.dict'), '\n')
  if empty(dict_files)
    return {}
  endif
  if a:dict_name == 'functions'
    let pattern = '^[[:alnum:]_]\+('
  else
    let pattern = '^[[:alnum:]_\[\](]\+'
  endif

  let keyword_dict = {}
  for line in readfile(dict_files[0])
    let word = matchstr(line, pattern)
    let rest = line[len(word):]
    if word =~ '\['
      let [word_head, word_tail] = split(word, '\[')
      let word_tail = ' ' . substitute(word_tail, '\]', '', '')
    else
      let word_head = word
      let word_tail = ' '
    endif

    for i in range(len(word_tail))
      let keyword_dict[word_head . word_tail[1:i]] = rest
    endfor
  endfor

  return keyword_dict
endfunction"}}}
function! s:make_cache_options() "{{{
  let l:options_helpfile = expand(findfile('doc/options.txt', &runtimepath))
  if !filereadable(l:options_helpfile)
    return []
  endif
  
  let l:descriptions = {}
  let l:quickref_helpfiles = [
        \ expand(findfile('doc/quickref.txt', &runtimepath)),
        \ expand("~/.vim/bundle/.neobundle/doc/quickref.jax")]
  for quickref_helpfile in l:quickref_helpfiles
    if !filereadable(quickref_helpfile)
      continue
    endif

    let lines = readfile(quickref_helpfile)
    let start = match(lines, 'option-list')+1
    let end = match(lines, '-----', start)-1
    for l in lines[start : end]
      let _ = matchlist(l, "^'" . '\(\k\+\)' . "'" . '\s\+\(.\+\)$')
      if !empty(_)
        let l:descriptions[_[1]] = substitute(_[2], '^''[^'']\+''\s\+', "", "g")
        let l:prev_option_name = _[1]
      else
        let l:descriptions[l:prev_option_name] .= substitute(l, '^\s\+', "", "g")
      endif
    endfor
  endfor
  
  let l:items = []
  let l:noitems = []
  let l:invitems = []
  
  let lines = readfile(l:options_helpfile)
  let l:start = match(lines, 'Aleph')
  let l:line = ""
  for l in lines[l:start : ]
    if match(l, '^\s\+\*''\w\+''\*') >= 0
      let l:line .= l
      continue
    endif
    if l:line == ""
      continue
    endif
    
    let _ = split(l:line, '\s')
    call filter(_, 'v:val =~ "^\*''"')
    call map(_, "substitute(v:val, '[\*'']', '', 'g')")
    let l:line = ""
    
    let l:name_pattern_count = len(_)
    
    if l:name_pattern_count == 1
      let l:is_bool = 0
      let l:has_short = 0
    elseif l:name_pattern_count == 2
      if match(_, '^no') >= 0
        let l:is_bool = 1
        let l:has_short = 0
      else
        let l:is_bool = 0
        let l:has_short = 1
      endif
    elseif l:name_pattern_count == 4
      let l:is_bool = 1
      let l:has_short = 1
    endif
    
    let l:name = _[0]
    if l:has_short
      let __ = deepcopy(_)
      call filter(__, 'v:val !~ "^no"')
      let l:name_lengths = deepcopy(__)
      call map(l:name_lengths, 'strlen(v:val)')
      let l:name = __[index(l:name_lengths, max(l:name_lengths))]
    else
      let l:name = _[0]
    endif
      
    let l:item = {'word': l:name}
    if has_key(l:descriptions, l:name)
      let l:menu = '(Option) ' . l:descriptions[l:name]
      let l:item.menu = l:menu
    endif
    call add(l:items, deepcopy(l:item))
    unlet l:item
    
    if l:is_bool
      let l:noitem = {'word': 'no' . l:name}
      if exists('l:menu')
        let l:noitem.menu = l:menu
      endif
      call add(l:noitems, deepcopy(l:noitem))
      unlet l:noitem
    
      let l:invitem = {'word': 'inv' . l:name}
      if exists('l:menu')
        let l:invitem.menu = l:menu
      endif
      call add(l:invitems, deepcopy(l:invitem))
      unlet l:invitem
    endif
    if exists('l:menu')
      unlet l:menu
    endif
  endfor
  call extend(l:items, l:noitems)
  call extend(l:items, l:invitems)
  return l:items
endfunction"}}}
function! s:make_cache_features() "{{{
  let features = []
  let helpfiles = [
        \ expand("~/.vim/bundle/.neobundle/doc/eval.jax"),
        \ expand(findfile('doc/eval.txt', &runtimepath))]
  for helpfile in helpfiles
    if !filereadable(helpfile)
      continue
    endif

    let lines = readfile(helpfile)
    let start = match(lines,
          \ ((v:version > 704 || v:version == 704 && has('patch11')) ?
          \   'acl' : '^all_builtin_terms'))
    let end = match(lines, '^x11')
    for l in lines[start : end]
      let _ = matchlist(l, '^\(\k\+\)\t\+\(.\+\)$')
      if !empty(_)
        call add(features, {
              \ 'word' : _[1],
              \ 'menu' : '(Feature) ' . _[2],
              \ })
      endif
    endfor
  endfor

  call add(features, {
        \ 'word' : 'patch',
        \ 'menu' : '; Included patches Ex: patch123',
        \ })
  if has('patch-7.4.237')
    call add(features, {
          \ 'word' : 'patch-',
          \ 'menu' : '; Version and patches Ex: patch-7.4.237'
          \ })
  endif

  return features
endfunction"}}}
function! s:make_cache_functions() "{{{
  return [
\ {
\   "word": "abs(",
\   "menu": "Float/Number {expr}の絶対値"
\ },
\ {
\   "word": "acos(",
\   "menu": "Float {expr}のアークコサイン"
\ },
\ {
\   "word": "add(",
\   "menu": "List {item}をリスト{list}に追加する"
\ },
\ {
\   "word": "and(",
\   "menu": "Number ビット論理積"
\ },
\ {
\   "word": "append(",
\   "menu": "Number 行{list}を{lnum}行目に付け加える"
\ },
\ {
\   "word": "argc()",
\   "menu": "Number 引数内のファイルの数"
\ },
\ {
\   "word": "argidx()",
\   "menu": "Number 引数リスト内の現在のインデックス"
\ },
\ {
\   "word": "arglistid(",
\   "menu": "Number 引数リストID"
\ },
\ {
\   "word": "argv(",
\   "menu": "List 引数リスト"
\ },
\ {
\   "word": "asin(",
\   "menu": "Float {expr}のアークサイン"
\ },
\ {
\   "word": "atan(",
\   "menu": "Float {expr}のアークタンジェント"
\ },
\ {
\   "word": "atan2(",
\   "menu": "Float {expr1} / {expr2} のアークタン ジェント"
\ },
\ {
\   "word": "browse(",
\   "menu": "String ファイル選択ダイアログを表示"
\ },
\ {
\   "word": "browsedir(",
\   "menu": "String ディレクトリ選択ダイアログを表示"
\ },
\ {
\   "word": "bufexists(",
\   "menu": "Number バッファ{expr}が存在すればTRUE"
\ },
\ {
\   "word": "buflisted(",
\   "menu": "Number バッファ{expr}がリストにあるならTRUE"
\ },
\ {
\   "word": "bufloaded(",
\   "menu": "Number バッファ{expr}がロード済みならTRUE"
\ },
\ {
\   "word": "bufname(",
\   "menu": "String バッファ{expr}の名前"
\ },
\ {
\   "word": "bufnr(",
\   "menu": "Number バッファ{expr}の番号"
\ },
\ {
\   "word": "bufwinnr(",
\   "menu": "Number バッファ{nr}のウィンドウ番号"
\ },
\ {
\   "word": "byte2line(",
\   "menu": "Number {byte}番目のバイトの行番号"
\ },
\ {
\   "word": "byteidx(",
\   "menu": "Number {expr}の{nr}文字目のバイトインデックス"
\ },
\ {
\   "word": "byteidxcomp(",
\   "menu": "Number {expr}の{nr}文字目のバイトインデックス"
\ },
\ {
\   "word": "call(",
\   "menu": "any 引数{arglist}をつけて{func}を呼ぶ"
\ },
\ {
\   "word": "ceil(",
\   "menu": "Float {expr} を切り上げる"
\ },
\ {
\   "word": "changenr()",
\   "menu": "Number 現在の変更番号"
\ },
\ {
\   "word": "char2nr(",
\   "menu": "Number {expr}の先頭文字のASCII/UTF8コード"
\ },
\ {
\   "word": "cindent(",
\   "menu": "Number {lnum}行目のCインデント量"
\ },
\ {
\   "word": "clearmatches()",
\   "menu": "none 全マッチをクリアする"
\ },
\ {
\   "word": "col(",
\   "menu": "Number カーソルかマークのカラム番号"
\ },
\ {
\   "word": "complete(",
\   "menu": "none 挿入モード補完の結果を設定する"
\ },
\ {
\   "word": "complete_add(",
\   "menu": "Number 補完候補を追加する"
\ },
\ {
\   "word": "complete_check()",
\   "menu": "Number 補完中に押されたキーをチェックする"
\ },
\ {
\   "word": "confirm(",
\   "menu": "Number ユーザーへの選択肢と番号"
\ },
\ {
\   "word": "copy(",
\   "menu": "any {expr}の浅いコピーを作る"
\ },
\ {
\   "word": "cos(",
\   "menu": "Float {expr} の余弦(コサイン)"
\ },
\ {
\   "word": "cosh(",
\   "menu": "Float {expr}のハイパボリックコサイン"
\ },
\ {
\   "word": "count(",
\   "menu": "Number {list}中に{expr}が何個現れるか数える"
\ },
\ {
\   "word": "cscope_connection(",
\   "menu": "Number cscope接続の存在を判定する"
\ },
\ {
\   "word": "cursor(",
\   "menu": "Number カーソルを{list}の位置へ移動"
\ },
\ {
\   "word": "deepcopy(",
\   "menu": "any {expr}の完全なコピーを作る"
\ },
\ {
\   "word": "delete(",
\   "menu": "Number ファイル{fname}を消す"
\ },
\ {
\   "word": "dictwatcheradd(",
\   "menu": "Start watching a dictionary"
\ },
\ {
\   "word": "dictwatcherdel(",
\   "menu": "Stop watching a dictionary"
\ },
\ {
\   "word": "did_filetype()",
\   "menu": "Number FileTypeのautocommandが実行されたか?"
\ },
\ {
\   "word": "diff_filler(",
\   "menu": "Number 差分モードで{lnum}に挿入された行"
\ },
\ {
\   "word": "diff_hlID(",
\   "menu": "Number 差分モードで{lnum}/{col}位置の強調"
\ },
\ {
\   "word": "empty(",
\   "menu": "Number {expr}が空ならTRUE"
\ },
\ {
\   "word": "escape(",
\   "menu": "String {string}内の{chars}を '\\' でエスケープ"
\ },
\ {
\   "word": "eval(",
\   "menu": "any {string}を評価し、値を得る"
\ },
\ {
\   "word": "eventhandler()",
\   "menu": "Number イベントハンドラの内側ならTRUE"
\ },
\ {
\   "word": "executable(",
\   "menu": "Number 実行可能な{expr}が存在するなら1"
\ },
\ {
\   "word": "exepath(",
\   "menu": "String コマンド {expr} のフルパス"
\ },
\ {
\   "word": "exists(",
\   "menu": "Number 変数{var}が存在したらTRUE"
\ },
\ {
\   "word": "extend(",
\   "menu": "List/Dict {expr1}に{expr2}の要素を挿入"
\ },
\ {
\   "word": "exp(",
\   "menu": "Float {expr}の指数"
\ },
\ {
\   "word": "expand(",
\   "menu": "any {expr}内の特別なキーワードを展開"
\ },
\ {
\   "word": "feedkeys(",
\   "menu": "Number 先行入力バッファにキーシーケンスを追加"
\ },
\ {
\   "word": "filereadable(",
\   "menu": "Number {file}が読みこみ可能ならTRUE"
\ },
\ {
\   "word": "filewritable(",
\   "menu": "Number {file}が書き込み可能ならTRUE"
\ },
\ {
\   "word": "filter(",
\   "menu": "List/Dict {string}が0となる要素を{expr}から とり除く"
\ },
\ {
\   "word": "finddir(",
\   "menu": "String {path}からディレクトリ{name}を探す"
\ },
\ {
\   "word": "findfile(",
\   "menu": "String {path}からファイル{name}を探す"
\ },
\ {
\   "word": "float2nr(",
\   "menu": "Number 浮動小数点数 {expr} を数値に変換する"
\ },
\ {
\   "word": "floor(",
\   "menu": "Float {expr} を切り捨てる"
\ },
\ {
\   "word": "fmod(",
\   "menu": "Float {expr1} / {expr2} の余り"
\ },
\ {
\   "word": "fnameescape(",
\   "menu": "String {fname} 内の特殊文字をエスケープする"
\ },
\ {
\   "word": "fnamemodify(",
\   "menu": "String ファイル名を変更"
\ },
\ {
\   "word": "foldclosed(",
\   "menu": "Number {lnum}の折り畳みの最初の行(閉じている なら)"
\ },
\ {
\   "word": "foldclosedend(",
\   "menu": "Number {lnum}の折り畳みの最後の行(閉じている なら)"
\ },
\ {
\   "word": "foldlevel(",
\   "menu": "Number {lnum}の折り畳みレベル"
\ },
\ {
\   "word": "foldtext()",
\   "menu": "String 閉じた折り畳みに表示されている行"
\ },
\ {
\   "word": "foldtextresult(",
\   "menu": "String {lnum}で閉じている折り畳みのテキスト"
\ },
\ {
\   "word": "foreground()",
\   "menu": "Number Vimウィンドウを前面に移動する"
\ },
\ {
\   "word": "function(",
\   "menu": "Funcref 関数{name}への参照を取得"
\ },
\ {
\   "word": "garbagecollect(",
\   "menu": "none メモリを解放する。循環参照を断ち切る"
\ },
\ {
\   "word": "get(",
\   "menu": "any {dict}や{def}から要素{key}を取得"
\ },
\ {
\   "word": "getbufline(",
\   "menu": "List バッファ{expr}の{lnum}から{end}行目"
\ },
\ {
\   "word": "getbufvar(",
\   "menu": "any バッファ{expr}の変数 {varname}"
\ },
\ {
\   "word": "getchar(",
\   "menu": "Number get one character from the user"
\ },
\ {
\   "word": "getcharmod()",
\   "menu": "Number modifiers for the last typed character"
\ },
\ {
\   "word": "getcmdline()",
\   "menu": "String 現在のコマンドラインを取得"
\ },
\ {
\   "word": "getcmdpos()",
\   "menu": "Number コマンドラインのカーソル位置を取得"
\ },
\ {
\   "word": "getcmdtype()",
\   "menu": "String 現在のコマンドラインの種類を取得"
\ },
\ {
\   "word": "getcmdwintype()",
\   "menu": "String 現在のコマンドラインウィンドウの種類"
\ },
\ {
\   "word": "getcurpos()",
\   "menu": "List カーソルの位置"
\ },
\ {
\   "word": "getcwd()",
\   "menu": "String 現在の作業ディレクトリ"
\ },
\ {
\   "word": "getfontname(",
\   "menu": "String 使用しているフォントの名前"
\ },
\ {
\   "word": "getfperm(",
\   "menu": "String ファイル{fname}の許可属性を取得"
\ },
\ {
\   "word": "getfsize(",
\   "menu": "Number ファイル{fname}のバイト数を取得"
\ },
\ {
\   "word": "getftime(",
\   "menu": "Number ファイルの最終更新時間"
\ },
\ {
\   "word": "getftype(",
\   "menu": "String ファイル{fname}の種類の説明"
\ },
\ {
\   "word": "getline(",
\   "menu": "List カレントバッファの{lnum}から{end}行目"
\ },
\ {
\   "word": "getloclist(",
\   "menu": "List ロケーションリストの要素のリスト"
\ },
\ {
\   "word": "getmatches()",
\   "menu": "List 現在のマッチのリスト"
\ },
\ {
\   "word": "getpid()",
\   "menu": "Number Vim のプロセス ID"
\ },
\ {
\   "word": "getpos(",
\   "menu": "List カーソル・マークなどの位置を取得"
\ },
\ {
\   "word": "getqflist()",
\   "menu": "List quickfixリストの要素のリスト"
\ },
\ {
\   "word": "getreg(",
\   "menu": "String/List レジスタの中身を取得"
\ },
\ {
\   "word": "getregtype(",
\   "menu": "String レジスタの種類を取得"
\ },
\ {
\   "word": "gettabvar(",
\   "menu": "any タブ{nr}の変数{varname}または{def}"
\ },
\ {
\   "word": "gettabwinvar(",
\   "menu": "any タブページ{tabnr}の{winnr}の{name}"
\ },
\ {
\   "word": "getwinposx()",
\   "menu": "Number GUI vim windowのX座標"
\ },
\ {
\   "word": "getwinposy()",
\   "menu": "Number GUI vim windowのY座標"
\ },
\ {
\   "word": "getwinvar(",
\   "menu": "any ウィンドウ{nr}の変数{varname}"
\ },
\ {
\   "word": "glob(",
\   "menu": "any {expr}内のfile wildcardを展開"
\ },
\ {
\   "word": "glob2regpat(",
\   "menu": "String globパターンを検索パターンに変換"
\ },
\ {
\   "word": "globpath(",
\   "menu": "String {path}の全ディレクトリに対し glob({expr})を行う"
\ },
\ {
\   "word": "has(",
\   "menu": "Number 機能{feature}がサポートならばTRUE"
\ },
\ {
\   "word": "has_key(",
\   "menu": "Number {dict}が要素{key}を持つならTRUE"
\ },
\ {
\   "word": "haslocaldir()",
\   "menu": "Number 現在のウィンドウで|:lcd|が実行された ならTRUE"
\ },
\ {
\   "word": "hasmapto(",
\   "menu": "Number {what}へのマッピングが存在するならTRUE"
\ },
\ {
\   "word": "histadd(",
\   "menu": "String ヒストリに追加"
\ },
\ {
\   "word": "histdel(",
\   "menu": "String ヒストリからitemを削除"
\ },
\ {
\   "word": "histget(",
\   "menu": "String ヒストリから{index}アイテムを取得"
\ },
\ {
\   "word": "histnr(",
\   "menu": "Number ヒストリの数"
\ },
\ {
\   "word": "hlexists(",
\   "menu": "Number highlight group {name}が存在したらTRUE"
\ },
\ {
\   "word": "hlID(",
\   "menu": "Number highlight group {name}のID"
\ },
\ {
\   "word": "hostname()",
\   "menu": "String vimが動作しているマシンの名前"
\ },
\ {
\   "word": "iconv(",
\   "menu": "String {expr}のエンコーディングを変換する"
\ },
\ {
\   "word": "indent(",
\   "menu": "Number 行{lnum}のインデントを取得"
\ },
\ {
\   "word": "index(",
\   "menu": "Number {list}中に{expr}が現れる位置"
\ },
\ {
\   "word": "input(",
\   "menu": "String ユーザーからの入力を取得"
\ },
\ {
\   "word": "inputdialog(",
\   "menu": "String input()と同様。GUIのダイアログを使用"
\ },
\ {
\   "word": "inputlist(",
\   "menu": "Number ユーザーに選択肢から選ばせる"
\ },
\ {
\   "word": "inputrestore()",
\   "menu": "Number 先行入力を復元する"
\ },
\ {
\   "word": "inputsave()",
\   "menu": "Number 先行入力を保存し、クリアする"
\ },
\ {
\   "word": "inputsecret(",
\   "menu": "String input()だがテキストを隠す"
\ },
\ {
\   "word": "insert(",
\   "menu": "List {list}に要素{item}を挿入 [{idx}の前]"
\ },
\ {
\   "word": "invert(",
\   "menu": "Number ビット反転"
\ },
\ {
\   "word": "isdirectory(",
\   "menu": "Number {directory}がディレクトリならばTRUE"
\ },
\ {
\   "word": "islocked(",
\   "menu": "Number {expr}がロックされているならTRUE"
\ },
\ {
\   "word": "items(",
\   "menu": "List {dict}のキーと値のペアを取得"
\ },
\ {
\   "word": "jobclose(",
\   "menu": "Number Closes a job stream(s)"
\ },
\ {
\   "word": "jobresize(",
\   "menu": "Number Resize {job}'s pseudo terminal window"
\ },
\ {
\   "word": "jobsend(",
\   "menu": "Number Writes {data} to {job}'s stdin"
\ },
\ {
\   "word": "jobstart(",
\   "menu": "Number Spawns {cmd} as a job"
\ },
\ {
\   "word": "jobstop(",
\   "menu": "Number Stops a job"
\ },
\ {
\   "word": "jobwait(",
\   "menu": "Number Wait for a set of jobs"
\ },
\ {
\   "word": "join(",
\   "menu": "String {list}の要素を連結して文字列にする"
\ },
\ {
\   "word": "keys(",
\   "menu": "List {dict}のキーを取得"
\ },
\ {
\   "word": "len(",
\   "menu": "Number {expr}の長さを取得"
\ },
\ {
\   "word": "libcall(",
\   "menu": "String call {func} in library {lib} with {arg}"
\ },
\ {
\   "word": "libcallnr(",
\   "menu": "Number idem, but return a Number"
\ },
\ {
\   "word": "line(",
\   "menu": "Number 行番号の取得"
\ },
\ {
\   "word": "line2byte(",
\   "menu": "Number 行{lnum}のバイトカウント"
\ },
\ {
\   "word": "lispindent(",
\   "menu": "Number {lnum}行目のLispインデント量を取得"
\ },
\ {
\   "word": "localtime()",
\   "menu": "Number 現在時刻"
\ },
\ {
\   "word": "log(",
\   "menu": "Float {expr}の自然対数(底e)"
\ },
\ {
\   "word": "log10(",
\   "menu": "Float 浮動小数点数 {expr} の 10 を底 とする対数"
\ },
\ {
\   "word": "map(",
\   "menu": "List/Dict {expr}の各要素を{expr}に変える"
\ },
\ {
\   "word": "maparg(",
\   "menu": "String/Dict モード{mode}でのマッピング{name}の値"
\ },
\ {
\   "word": "mapcheck(",
\   "menu": "String {name}にマッチするマッピングを確認"
\ },
\ {
\   "word": "match(",
\   "menu": "Number {expr}内で{pat}がマッチする位置"
\ },
\ {
\   "word": "matchadd(",
\   "menu": "Number {pattern} を {group} で強調表示する"
\ },
\ {
\   "word": "matchaddpos(",
\   "menu": "Number 位置を {group} で強調表示する"
\ },
\ {
\   "word": "matcharg(",
\   "menu": "List |:match|の引数"
\ },
\ {
\   "word": "matchdelete(",
\   "menu": "Number {id} で指定されるマッチを削除する"
\ },
\ {
\   "word": "matchend(",
\   "menu": "Number {expr}内で{pat}が終了する位置"
\ },
\ {
\   "word": "matchlist(",
\   "menu": "List {expr}内の{pat}のマッチと部分マッチ"
\ },
\ {
\   "word": "matchstr(",
\   "menu": "String {expr}内の{count}番目の{pat}のマッチ"
\ },
\ {
\   "word": "max(",
\   "menu": "Number {list}内の要素の最大値"
\ },
\ {
\   "word": "min(",
\   "menu": "Number {list}内の要素の最小値"
\ },
\ {
\   "word": "mkdir(",
\   "menu": "Number ディレクトリ{name}を作成"
\ },
\ {
\   "word": "mode(",
\   "menu": "String 現在の編集モード"
\ },
\ {
\   "word": "msgpackdump(",
\   "menu": "List dump a list of objects to msgpack"
\ },
\ {
\   "word": "msgpackparse(",
\   "menu": "List parse msgpack to a list of objects"
\ },
\ {
\   "word": "nextnonblank(",
\   "menu": "Number {lnum}行目以降で空行でない行の行番号"
\ },
\ {
\   "word": "nr2char(",
\   "menu": "String ASCII/UTF8コード{expr}で示される文字"
\ },
\ {
\   "word": "or(",
\   "menu": "Number ビット論理和"
\ },
\ {
\   "word": "pathshorten(",
\   "menu": "String path内の短縮したディレクトリ名"
\ },
\ {
\   "word": "pow(",
\   "menu": "Float {x} の {y} 乗"
\ },
\ {
\   "word": "prevnonblank(",
\   "menu": "Number {lnum}行目以前の空行でない行の行番号"
\ },
\ {
\   "word": "printf(",
\   "menu": "String 文字列を組み立てる"
\ },
\ {
\   "word": "pumvisible()",
\   "menu": "Number ポップアップメニューが表示されているか"
\ },
\ {
\   "word": "pyeval(",
\   "menu": "any |Python| の式を評価する"
\ },
\ {
\   "word": "py3eval(",
\   "menu": "any |python3| の式を評価する"
\ },
\ {
\   "word": "range(",
\   "menu": "List {expr}から{max}までの要素のリスト"
\ },
\ {
\   "word": "readfile(",
\   "menu": "List ファイル{fname}から行のリストを取得"
\ },
\ {
\   "word": "reltime(",
\   "menu": "List 時刻の値を取得"
\ },
\ {
\   "word": "reltimestr(",
\   "menu": "String 時刻の値を文字列に変換"
\ },
\ {
\   "word": "remote_expr(",
\   "menu": "String 式を送信する"
\ },
\ {
\   "word": "remote_foreground(",
\   "menu": "Number Vimサーバーを前面に出す"
\ },
\ {
\   "word": "remote_peek(",
\   "menu": "Number 返信文字列を確認する"
\ },
\ {
\   "word": "remote_read(",
\   "menu": "String 返信文字列を読み込む"
\ },
\ {
\   "word": "remote_send(",
\   "menu": "String キーシーケンスを送信する"
\ },
\ {
\   "word": "remove(",
\   "menu": "any {dict}から要素{key}を削除"
\ },
\ {
\   "word": "rename(",
\   "menu": "Number {file}から{to}へファイル名変更"
\ },
\ {
\   "word": "repeat(",
\   "menu": "String {expr}を{count}回繰り返す"
\ },
\ {
\   "word": "resolve(",
\   "menu": "String ショートカットが指す先のファイル名"
\ },
\ {
\   "word": "reverse(",
\   "menu": "List {list}をその場で反転させる"
\ },
\ {
\   "word": "round(",
\   "menu": "Float {expr} を四捨五入する"
\ },
\ {
\   "word": "rpcnotify(",
\   "menu": "Sends a |msgpack-rpc| notification to {channel}"
\ },
\ {
\   "word": "rpcrequest(",
\   "menu": "Sends a |msgpack-rpc| request to {channel}"
\ },
\ {
\   "word": "rpcstart(",
\   "menu": "Spawns {prog} and opens a |msgpack-rpc| channel"
\ },
\ {
\   "word": "rpcstop(",
\   "menu": "Closes a |msgpack-rpc| {channel}"
\ },
\ {
\   "word": "screenattr(",
\   "menu": "Number スクリーン位置の属性"
\ },
\ {
\   "word": "screenchar(",
\   "menu": "Number スクリーン位置の文字"
\ },
\ {
\   "word": "screencol()",
\   "menu": "Number 現在のカーソル列"
\ },
\ {
\   "word": "screenrow()",
\   "menu": "Number 現在のカーソル行"
\ },
\ {
\   "word": "search(",
\   "menu": "Number {pattern} を検索する"
\ },
\ {
\   "word": "searchdecl(",
\   "menu": "Number 変数の宣言を検索"
\ },
\ {
\   "word": "searchpair(",
\   "menu": "Number 開始/終端のペアの他方を検索"
\ },
\ {
\   "word": "searchpairpos(",
\   "menu": "List 開始/終端のペアの他方を検索"
\ },
\ {
\   "word": "searchpos(",
\   "menu": "List {pattern}を検索"
\ },
\ {
\   "word": "server2client(",
\   "menu": "Number 返信文字列を送信する"
\ },
\ {
\   "word": "serverlist()",
\   "menu": "String 利用可能なサーバーのリストを取得"
\ },
\ {
\   "word": "setbufvar(",
\   "menu": "set をセット"
\ },
\ {
\   "word": "setcharsearch()",
\   "menu": "Dict set character search from {dict}"
\ },
\ {
\   "word": "setcmdpos(",
\   "menu": "Number コマンドライン内のカーソル位置を設定"
\ },
\ {
\   "word": "setline(",
\   "menu": "Number 行{lnum}に{line}(文字列)をセット"
\ },
\ {
\   "word": "setloclist(",
\   "menu": "Number {list}を使ってロケーションリストを変更"
\ },
\ {
\   "word": "setmatches(",
\   "menu": "Number マッチのリストを復元する"
\ },
\ {
\   "word": "setpos(",
\   "menu": "Number {expr}の位置を{list}にする"
\ },
\ {
\   "word": "setqflist(",
\   "menu": "Number {list}を使ってQuickFixリストを変更"
\ },
\ {
\   "word": "setreg(",
\   "menu": "Number レジスタの値とタイプを設定"
\ },
\ {
\   "word": "settabvar(",
\   "menu": "set 設定する"
\ },
\ {
\   "word": "settabwinvar(",
\   "menu": "set ドウ{winnr}の変数{varname}に{val}を セット"
\ },
\ {
\   "word": "setwinvar(",
\   "menu": "set セット"
\ },
\ {
\   "word": "sha256(",
\   "menu": "String {string}のSHA256チェックサム"
\ },
\ {
\   "word": "shellescape(",
\   "menu": "String {string}をシェルコマンド引数として使う ためにエスケープする。"
\ },
\ {
\   "word": "shiftwidth()",
\   "menu": "Number 実際に使用される 'shiftwidth' の値"
\ },
\ {
\   "word": "simplify(",
\   "menu": "String ファイル名を可能なかぎり簡略化する"
\ },
\ {
\   "word": "sin(",
\   "menu": "Float {expr} の正弦(サイン)"
\ },
\ {
\   "word": "sinh(",
\   "menu": "Float {expr}のハイパボリックサイン"
\ },
\ {
\   "word": "sort(",
\   "menu": "List 比較に{func}を使って{list}をソートする"
\ },
\ {
\   "word": "soundfold(",
\   "menu": "String {word}のsound-fold"
\ },
\ {
\   "word": "spellbadword(",
\   "menu": "String カーソル位置のスペルミスした単語"
\ },
\ {
\   "word": "spellsuggest(",
\   "menu": "List スペリング補完"
\ },
\ {
\   "word": "split(",
\   "menu": "List {expr}を{pat}で区切ってリストを作る"
\ },
\ {
\   "word": "sqrt(",
\   "menu": "Float {expr} の平方根"
\ },
\ {
\   "word": "str2float(",
\   "menu": "Float 文字列を浮動小数点数に変換する"
\ },
\ {
\   "word": "str2nr(",
\   "menu": "Number 文字列を数値に変換する"
\ },
\ {
\   "word": "strchars(",
\   "menu": "Number 文字列{expr}の文字の数"
\ },
\ {
\   "word": "strdisplaywidth(",
\   "menu": "Number 文字列{expr}の表示幅"
\ },
\ {
\   "word": "strftime(",
\   "menu": "String 指定されたフォーマットでの時刻"
\ },
\ {
\   "word": "stridx(",
\   "menu": "Number {haystack}内の{needle}のインデックス"
\ },
\ {
\   "word": "string(",
\   "menu": "String {expr}の値の文字列表現"
\ },
\ {
\   "word": "strlen(",
\   "menu": "Number 文字列{expr}の長さ"
\ },
\ {
\   "word": "strpart(",
\   "menu": "String {src}内{start}から長さ{len}の部分"
\ },
\ {
\   "word": "strridx(",
\   "menu": "Number {haystack}内の最後の{needle}のインデッ クス"
\ },
\ {
\   "word": "strtrans(",
\   "menu": "String 文字列を表示可能に変更"
\ },
\ {
\   "word": "strwidth(",
\   "menu": "Number 文字列{expr}の表示セル幅"
\ },
\ {
\   "word": "submatch(",
\   "menu": "String/List \":s\" やsubstitute()における特定のマッチ"
\ },
\ {
\   "word": "substitute(",
\   "menu": "String {expr}の{pat}を{sub}に置換え"
\ },
\ {
\   "word": "synID(",
\   "menu": "Number {line}と{col}のsyntax IDを取得"
\ },
\ {
\   "word": "synIDattr(",
\   "menu": "String syntax ID{synID}の属性{what}を取得"
\ },
\ {
\   "word": "synIDtrans(",
\   "menu": "Number {synID}の翻訳されたsyntax ID"
\ },
\ {
\   "word": "synconcealed(",
\   "menu": "List Conceal の情報"
\ },
\ {
\   "word": "synstack(",
\   "menu": "List {lnum}行{col}列目における構文IDの スタック"
\ },
\ {
\   "word": "system(",
\   "menu": "String シェルコマンド{expr}の出力結果"
\ },
\ {
\   "word": "systemlist(",
\   "menu": "List シェルコマンド{expr}の出力結果"
\ },
\ {
\   "word": "tabpagebuflist(",
\   "menu": "List タブページ内のバッファ番号のリスト"
\ },
\ {
\   "word": "tabpagenr(",
\   "menu": "Number 現在または最後のタブページの番号"
\ },
\ {
\   "word": "tabpagewinnr(",
\   "menu": "Number タブページ内の現在のウィンドウの番号"
\ },
\ {
\   "word": "taglist(",
\   "menu": "List {expr}にマッチするタグのリスト"
\ },
\ {
\   "word": "tagfiles()",
\   "menu": "List 使用しているタグファイルのリスト"
\ },
\ {
\   "word": "tempname()",
\   "menu": "String テンポラリファイルの名前"
\ },
\ {
\   "word": "tan(",
\   "menu": "Float {expr}のタンジェント"
\ },
\ {
\   "word": "tanh(",
\   "menu": "Float {expr}のハイパボリックタンジェ ント"
\ },
\ {
\   "word": "tolower(",
\   "menu": "String 文字列{expr}を小文字にする"
\ },
\ {
\   "word": "toupper(",
\   "menu": "String 文字列{expr}を大文字にする"
\ },
\ {
\   "word": "tr(",
\   "menu": "String {src}中に現れる文字{fromstr}を{tostr} に変換する。"
\ },
\ {
\   "word": "trunc(",
\   "menu": "Float 浮動小数点数{expr}を切り詰める"
\ },
\ {
\   "word": "type(",
\   "menu": "Number 変数{name}の型"
\ },
\ {
\   "word": "undofile(",
\   "menu": "String {name}に対するアンドゥファイルの名前"
\ },
\ {
\   "word": "undotree()",
\   "menu": "List アンドゥファイルツリー"
\ },
\ {
\   "word": "uniq(",
\   "menu": "List リストから隣接した重複を削除"
\ },
\ {
\   "word": "values(",
\   "menu": "List {dict}の値のリスト"
\ },
\ {
\   "word": "virtcol(",
\   "menu": "Number カーソルのスクリーンカラム位置"
\ },
\ {
\   "word": "visualmode(",
\   "menu": "String 最後に使われたビジュアルモード"
\ },
\ {
\   "word": "wildmenumode()",
\   "menu": "Number 'wildmenu' モードが有効かどうか"
\ },
\ {
\   "word": "winbufnr(",
\   "menu": "Number ウィンドウ{nr}のバッファ番号"
\ },
\ {
\   "word": "wincol()",
\   "menu": "Number カーソル位置のウィンドウ桁"
\ },
\ {
\   "word": "winheight(",
\   "menu": "Number ウィンドウ{nr}の高さ"
\ },
\ {
\   "word": "winline()",
\   "menu": "Number カーソル位置のウィンドウ行"
\ },
\ {
\   "word": "winnr(",
\   "menu": "Number 現在のウィンドウの番号"
\ },
\ {
\   "word": "winrestcmd()",
\   "menu": "String ウィンドウサイズを復元するコマンド"
\ },
\ {
\   "word": "winrestview(",
\   "menu": "none 現在のウィンドウのビューを復元"
\ },
\ {
\   "word": "winsaveview()",
\   "menu": "Dict 現在のウィンドウのビューを保存"
\ },
\ {
\   "word": "winwidth(",
\   "menu": "Number ウィンドウ{nr}の幅を取得"
\ },
\ {
\   "word": "writefile(",
\   "menu": "Number 行のリストをファイル{fname}に書き込む"
\ },
\ {
\   "word": "xor(",
\   "menu": "Number ビット排他的論理和"
\ }
\]
endfunction"}}}
function! s:make_cache_commands() "{{{
  let helpfiles = [
        \ expand(findfile('doc/index.txt', &runtimepath)),
        \ expand("~/.vim/bundle/.neobundle/doc/index.jax")]
  for helpfile in helpfiles
    if !filereadable(helpfile)
      continue
    endif

    let lines = readfile(helpfile)
    let commands = []
    let start = match(lines, '^|:!|')
    let end = match(lines, '^|:\~|', start)
    let desc = ''
    for lnum in range(end, start, -1)
      let desc = substitute(lines[lnum], '^\s\+\ze', '', 'g') . desc
      let _ = matchlist(desc, '^|:\(.\{-}\)|\(.\+\)$')
      if !empty(_)
        call add(commands, {
              \ 'word' : _[1],
              \ 'menu' : '(Command) ' . substitute(_[2], '^\s*:\S*\t*', '', 'g')
              \ })
        let desc = ''
      endif
    endfor
  endfor
  return reverse(commands)
endfunction"}}}
function! s:make_cache_autocmds() "{{{
  let helpfiles = [
        \ expand(findfile('doc/autocmd.txt', &runtimepath)),
        \ expand("~/.vim/bundle/.neobundle/doc/autocmd.jax")]
  for helpfile in helpfiles
    if !filereadable(helpfile)
      continue
    endif

    let lines = readfile(helpfile)
    let autocmds = []
    let start = match(lines, '^|BufNewFile|')
    let end = match(lines, '^|User|', start)
    let desc = ''
    for lnum in range(end, start, -1)
      let desc = substitute(lines[lnum], '^\s\+\ze', '', 'g') . ' ' . desc
      let _ = matchlist(desc, '^|\(.\{-}\)|\s\+\(.\+\)$')
      if !empty(_)
        call add(autocmds, { 'word' : _[1], 'menu' : '(AutoCmdEvent) ' . _[2]})
        let desc = ''
      endif
    endfor
  endfor

  return reverse(autocmds)
endfunction"}}}

function! s:get_cmdlist() "{{{
  " Get command list.
  redir => redir
  silent! command
  redir END

  let keyword_list = []
  let completions = [ 'augroup', 'buffer', 'behave',
        \ 'color', 'command', 'compiler', 'cscope',
        \ 'dir', 'environment', 'event', 'expression',
        \ 'file', 'file_in_path', 'filetype', 'function',
        \ 'help', 'highlight', 'history', 'locale',
        \ 'mapping', 'menu', 'option', 'shellcmd', 'sign',
        \ 'syntax', 'tag', 'tag_listfiles',
        \ 'var', 'custom', 'customlist' ]
  let command_prototypes = {}
  let command_completions = {}
  for line in split(redir, '\n')[1:]
    let word = matchstr(line, '\u\w*')

    " Analyze prototype.
    let end = matchend(line, '\u\w*')
    let args = matchstr(line, '[[:digit:]?+*]', end)
    if args != '0'
      let prototype = matchstr(line, '\u\w*', end)
      let found = 0
      for comp in completions
        if comp == prototype
          let command_completions[word] = prototype
          let found = 1

          break
        endif
      endfor

      if !found
        let prototype = 'arg'
      endif

      if args == '*'
        let prototype = '[' . prototype . '] ...'
      elseif args == '?'
        let prototype = '[' . prototype . ']'
      elseif args == '+'
        let prototype = prototype . ' ...'
      endif

      let command_prototypes[word] = ' ' . repeat(' ', 16 - len(word)) . prototype
    else
      let command_prototypes[word] = ''
    endif
    let prototype = command_prototypes[word]

    call add(keyword_list, {
          \ 'word' : word, 'abbr' : word . prototype,
          \ 'description' : word . prototype, 'kind' : 'c'
          \})
  endfor
  let s:global_candidates_list.command_prototypes = command_prototypes
  let s:global_candidates_list.command_completions = command_completions

  return keyword_list
endfunction"}}}
function! s:get_variablelist(dict, prefix) "{{{
  let kind_dict = ['0', '""', '()', '[]', '{}', '.']
  return values(map(copy(a:dict), "{
        \ 'word' : a:prefix.v:key,
        \ 'kind' : kind_dict[type(v:val)],
        \}"))
endfunction"}}}
function! s:get_functionlist() "{{{
  " Get function list.
  redir => redir
  silent! function
  redir END

  let keyword_dict = {}
  let function_prototypes = {}
  for line in split(redir, '\n')
    let line = line[9:]
    if line =~ '^<SNR>'
      continue
    endif
    let orig_line = line

    let word = matchstr(line, '\h[[:alnum:]_:#.]*()\?')
    if word != ''
      let keyword_dict[word] = {
            \ 'word' : word, 'abbr' : line,
            \ 'description' : line,
            \}

      let function_prototypes[word] = orig_line[len(word):]
    endif
  endfor

  let s:global_candidates_list.function_prototypes = function_prototypes

  return values(keyword_dict)
endfunction"}}}
function! s:get_augrouplist() "{{{
  " Get augroup list.
  redir => redir
  silent! augroup
  redir END

  let keyword_list = []
  for group in split(redir . ' END', '\s\|\n')
    call add(keyword_list, { 'word' : group, 'menu': '(augroup)' })
  endfor
  return keyword_list
endfunction"}}}
function! s:get_mappinglist() "{{{
  " Get mapping list.
  redir => redir
  silent! map
  redir END

  let keyword_list = []
  for line in split(redir, '\n')
    let map = matchstr(line, '^\a*\s*\zs\S\+')
    if map !~ '^<' || map =~ '^<SNR>'
      continue
    endif
    call add(keyword_list, { 'word' : map })
  endfor
  return keyword_list
endfunction"}}}
function! s:get_envlist() "{{{
  " Get environment variable list.

  let keyword_list = []
  for line in split(system('set'), '\n')
    let word = '$' . toupper(matchstr(line, '^\h\w*'))
    call add(keyword_list, { 'word' : word, 'kind' : 'e' })
  endfor
  return keyword_list
endfunction"}}}
function! s:make_completion_list(list) "{{{
  return map(copy(a:list), "{ 'word' : v:val }")
endfunction"}}}
function! s:analyze_function_line(line, keyword_dict, prototype) "{{{
  " Get script function.
  let line = substitute(matchstr(a:line,
        \ '\<fu\%[nction]!\?\s\+\zs.*)'), '".*$', '', '')
  let orig_line = line
  let word = matchstr(line, '^\h[[:alnum:]_:#.]*()\?')
  if word != '' && !has_key(a:keyword_dict, word)
    let a:keyword_dict[word] = {
          \ 'word' : word, 'abbr' : line, 'kind' : 'f'
          \}
    let a:prototype[word] = orig_line[len(word):]
  endif
endfunction"}}}
function! s:analyze_variable_line(line, keyword_dict) "{{{
  if a:line =~ '\<\%(let\|for\)\s\+\a[[:alnum:]_:]*'
    " let var = pattern.
    let word = matchstr(a:line, '\<\%(let\|for\)\s\+\zs\a[[:alnum:]_:]*')
    let expression = matchstr(a:line, '\<let\s\+\a[[:alnum:]_:]*\s*=\s*\zs.*$')
    if !has_key(a:keyword_dict, word) 
      let a:keyword_dict[word] = {
            \ 'word' : word,
            \ 'kind' : s:get_variable_type(expression)
            \}
    elseif expression != '' && a:keyword_dict[word].kind == ''
      " Update kind.
      let a:keyword_dict[word].kind = s:get_variable_type(expression)
    endif
  elseif a:line =~ '\<\%(let\|for\)\s\+\[.\{-}\]'
    " let [var1, var2] = pattern.
    let words = split(matchstr(a:line,
          \'\<\%(let\|for\)\s\+\[\zs.\{-}\ze\]'), '[,[:space:]]\+')
      let expressions = split(matchstr(a:line,
            \'\<let\s\+\[.\{-}\]\s*=\s*\[\zs.\{-}\ze\]$'), '[,[:space:];]\+')

      let i = 0
      while i < len(words)
        let expression = get(expressions, i, '')
        let word = words[i]

        if !has_key(a:keyword_dict, word) 
          let a:keyword_dict[word] = {
                \ 'word' : word,
                \ 'kind' : s:get_variable_type(expression)
                \}
        elseif expression != '' && a:keyword_dict[word].kind == ''
          " Update kind.
          let a:keyword_dict[word].kind = s:get_variable_type(expression)
        endif

        let i += 1
      endwhile
    elseif a:line =~ '\<fu\%[nction]!\?\s\+'
      " Get function arguments.
      for arg in split(matchstr(a:line, '^[^(]*(\zs[^)]*'), '\s*,\s*')
        let word = 'a:' . (arg == '...' ?  '000' : arg)
        let a:keyword_dict[word] = {
              \ 'word' : word,
              \ 'kind' : (arg == '...' ?  '[]' : '')
              \}

      endfor
      if a:line =~ '\.\.\.)'
        " Extra arguments.
        for arg in range(5)
          let word = 'a:' . arg
          let a:keyword_dict[word] = {
                \ 'word' : word,
                \ 'kind' : (arg == 0 ?  '0' : '')
                \}
        endfor
      endif
    endif
endfunction"}}}
function! s:analyze_dictionary_variable_line(line, keyword_dict, var_name) "{{{
  let let_pattern = '\<let\s\+'.a:var_name.'\.\h\w*'
  let call_pattern = '\<call\s\+'.a:var_name.'\.\h\w*()\?'

  if a:line =~ let_pattern
    let word = matchstr(a:line, a:var_name.'\zs\.\h\w*')
    let kind = ''
  elseif a:line =~ call_pattern
    let word = matchstr(a:line, a:var_name.'\zs\.\h\w*()\?')
    let kind = '()'
  else
    let word = matchstr(a:line, a:var_name.'\zs.\h\w*\%(()\?\)\?')
    let kind = s:get_variable_type(
          \ matchstr(a:line, a:var_name.'\.\h\w*\zs.*$'))
  endif

  if !has_key(a:keyword_dict, word)
    let a:keyword_dict[word] = { 'word' : word, 'kind' : kind }
  elseif kind != '' && a:keyword_dict[word].kind == ''
    " Update kind.
    let a:keyword_dict[word].kind = kind
  endif
endfunction"}}}
function! s:split_args(cur_text, complete_str) "{{{
  let args = split(a:cur_text)
  if a:complete_str == ''
    call add(args, '')
  endif

  return args
endfunction"}}}

" Initialize return types. "{{{
function! s:set_dictionary_helper(variable, keys, value) "{{{
  for key in split(a:keys, ',')
    let a:variable[key] = a:value
  endfor
endfunction"}}}
let s:function_return_types = {}
call s:set_dictionary_helper(
      \ s:function_return_types,
      \ 'len,match,matchend',
      \ '0')
call s:set_dictionary_helper(
      \ s:function_return_types,
      \ 'input,matchstr',
      \ '""')
call s:set_dictionary_helper(
      \ s:function_return_types,
      \ 'expand,filter,sort,split',
      \ '[]')
"}}}
function! s:get_variable_type(expression) "{{{
  " Analyze variable type.
  if a:expression =~ '^\%(\s*+\)\?\s*\d\+\.\d\+'
    return '.'
  elseif a:expression =~ '^\%(\s*+\)\?\s*\d\+'
    return '0'
  elseif a:expression =~ '^\%(\s*\.\)\?\s*["'']'
    return '""'
  elseif a:expression =~ '\<function('
    return '()'
  elseif a:expression =~ '^\%(\s*+\)\?\s*\['
    return '[]'
  elseif a:expression =~ '^\s*{\|^\.\h[[:alnum:]_:]*'
    return '{}'
  elseif a:expression =~ '\<\h\w*('
    " Function.
    let func_name = matchstr(a:expression, '\<\zs\h\w*\ze(')
    return has_key(s:function_return_types, func_name) ? s:function_return_types[func_name] : ''
  else
    return ''
  endif
endfunction"}}}

function! s:set_dictionary_helper(variable, keys, pattern) "{{{
  for key in split(a:keys, '\s*,\s*')
    if !has_key(a:variable, key)
      let a:variable[key] = a:pattern
    endif
  endfor
endfunction"}}}

function! s:check_global_candidates(key) "{{{
  if s:global_candidates_list.runtimepath !=# &runtimepath
    let s:global_candidates_list.runtimepath = &runtimepath
    return 1
  endif

  return !has_key(s:global_candidates_list, a:key)
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
