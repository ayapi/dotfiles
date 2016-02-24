function! JadeOmniComplete(findstart, base)
    if a:findstart
        let l:line = getline('.')
        let l:start = col('.') - 1
        while l:start >= 0 && l:line[l:start - 1] =~ '\%(\k\|-\)'
            let l:start -= 1
        endwhile
        return l:start
    endif

    let l:candidates = s:gather_candidates()

    if a:base == ""
        return l:candidates
    endif

    let l:matches = []
    for k in l:candidates
        if strpart(k, 0, strlen(a:base)) ==# a:base
            call add(l:matches, k)
        endif
    endfor
    return l:matches
endfunction

function! s:gather_candidates() abort
    let l:lnum = line('.')
    if s:is_comment(l:lnum)
        return []
    endif
    if s:is_code(l:lnum)
        return []
    endif
    
    let l:line = substitute(getline('.')[0: col('.') - 2], '^\s*', '', 'g')

    let l:before_start_lines = join(getline(1, line('.') - 1), '')
                \	. getline('.')[0 : col('.') - 2]

    let l:last_closeparens_idx = strridx(l:before_start_lines, ')')
    let l:last_openparens_idx = strridx(l:before_start_lines, '(')
    if l:last_closeparens_idx < l:last_openparens_idx
        " in `()` parens
        
        if stridx(l:line, '(') == -1
            " concat continuation lines
            let l:lnum = line('.')-1
            while (l:lnum >= 1 && stridx(l:line, '(') < 0)
                let l:lnum = s:prevnonblanknoncomment(l:lnum)
                let l:line = getline(l:lnum) . l:line
                let l:lnum -= 1
            endwhile
        endif

        let l:before_openparens = l:line[0: strridx(l:line, '(')]
        if l:before_openparens =~ '&attributes$'
            " TODO: `&attribute` syntax
            return []
        endif

        let l:inner_parens = substitute(l:line[strridx(l:line, '(') :], '[, ]', ' ', 'g')
        let l:inner_border_chars = reverse(split(
                    \ substitute(l:inner_parens, '[^= ]', '', 'g'), '.\zs'
                    \))
        if len(l:inner_border_chars) == 0
            " attribute name
            "   input(_
            "   input(typ_
            return []
        elseif l:inner_border_chars[0] == ' '
            let l:after_equal = l:line[strridx(l:line, '=') + 1]
            if l:after_equal !~ '["'']'
                " in expression or attribute name
                "   input(type=variable nam_
                "   input(type=status ? 'submit' : 'button' nam_
                " i have no idea how to get expresssion ending
                " but i add attr names to candidates anyway
                return []
            else
                let l:quote_count = len(substitute(
                            \ l:line[strridx(l:line, '='):],
                            \ '[^' . l:after_equal .']', '', 'g'
                            \))
                if l:quote_count % 2
                    " in string. attribute value
                    "   input(class='btn re_
                    return []
                endif
                " attribute name
                "   input(type='submit' va_
                return []
            endif
        elseif l:inner_border_chars[0] == '='
            " attribute value
            "   input(type=subm_
            "   input(type='subm_
            return []
        endif
    endif
    " element name or jade keyword
    return []
endfunction

function! s:is_code(lnum) abort
    let l:line = getline(a:lnum)
    if matchstr(l:line, '^\s*\zs[^( ]*\ze') =~ '!\?[-=]$'
        return 1
    endif
    let l:ascentors = s:get_ancestors(a:lnum)
    for l:ascentor in l:ascentors
        if l:ascentor =~ '^-' || l:ascentor =~ '^script'
            return 1
        endif
    endfor
    return 0
endfunction

function! s:is_comment(lnum) abort
    let l:line = getline(a:lnum)
    if l:line =~ '^\s*//'
        return 1
    endif
    let l:ascentors = s:get_ancestors(a:lnum)
    for l:ascentor in l:ascentors
        if l:ascentor =~ '^//'
            return 1
        endif
    endfor
    return 0
endfunction

function! s:get_ancestors(lnum) abort
    let l:lnum = a:lnum
    let l:current_indent = indent(l:lnum)
    let l:ascentors = []
    while 1
        let l:lnum = prevnonblank(l:lnum)
        if indent(l:lnum) < l:current_indent
            break
        endif
        let l:line = substitute(getline(l:lnum), '^\s*', '', 'g')
        " TODO: block expansion (nested colon syntax)
        " ref. http://jade-lang.com/reference/tags/
        
        let l:keyword = matchstr(l:line, '^\zs[^( ]*\ze')
        if l:keyword =~ '^[#\.]'
            let l:keyword = 'div' . l:line
        endif
        call add(l:ascentors, l:keyword)
        let l:lnum-=1
    endwhile
    return l:ascentors
endfunction

function! s:prevnonblanknoncomment(lnum) "{{{
    let lnum = a:lnum
    while lnum > 1
        let lnum = prevnonblank(lnum)
        let line = getline(lnum)
        if !s:is_comment(lnum)
            break
        endif
    endwhile
    return lnum
endfunction "}}}

" vim: foldmethod=marker
