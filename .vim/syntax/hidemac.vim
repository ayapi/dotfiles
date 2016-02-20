" 秀丸マクロ用構文定義
if exists("b:current_syntax")
    finish
endif

if !exists('g:hidemac_builtin')
    runtime ftplugin/hidemac.vim
endif

syntax iskeyword @,48-57,192-255,$,#,_

for name in keys(g:hidemac_builtin.statements.data) + ['loaddll']
    if index(['if', 'else', 'while'], name) >= 0
        continue
    endif
    execute 'syntax match hidemacStatement "\(^\s*\|;\s*\)\@<=' . name . '\(\k\)\@!"'
endfor

for name in g:hidemac_builtin.keywords.data
    execute 'syntax match hidemacSpecial "\(^\s*\|;\s*\|\k\)\@<!' . name . '\(\k\)\@!"'
endfor

for name in keys(g:hidemac_builtin.functions.data) + ['loaddll']
    execute 'syntax match hidemacFunction "\(\k\)\@<!' . name . '\((\)\@="'
endfor

" #var $var ##var $$var
syntax match hidemacVariable "\(\k\)\@<![\$#]\{1,2}[a-zA-Z0-9_]\+"
syntax match hidemacIdentifier "\(\k\)\@<![\$#]\{1,2}\([a-zA-Z0-9_]\)\@=" containedin=hidemacVariable

" if
syntax match hidemacConditional	"\(else\s\+\|^\s*\|;\s*\)\@<=if\(\k\)\@!"

"else
syntax match hidemacConditional	"\(}\s*\|^\s*\|;\s*\)\@<=else\(\k\)\@!"

" while
syntax match hidemacRepeat		"\(^\s*\|;\s*\)\@<=while\(\k\)\@!"

" 以下ゎvimのデフォで入ってるC言語用構文定義ファイルをてきとうに改造

syn keyword hidemacTodo		contained TODO FIXME XXX
syn cluster hidemacCommentGroup	contains=hidemacTodo,hidemacBadContinuation

syn region	hidemacString		start=+L\="+ skip=+\\\\\|\\"+ end=+"+ contains=hidemacSpecial,hidemacFormat,@Spell extend
syn region	hidemacCharacter		start=+L\='+ skip=+\\\\\|\\"+ end=+'+ contains=hidemacSpecial,hidemacFormat,@Spell extend

syn case ignore
syn match hidemacNumbers	display transparent "\<\d\|\.\d" contains=hidemacNumber,hidemacFloat,hidemacOctalError,hidemacOctal
" Same, but without octal error (for comments)
syn match hidemacNumbersCom	display contained transparent "\<\d\|\.\d" contains=hidemacNumber,hidemacFloat,hidemacOctal
syn match hidemacNumber		display contained "\d\+\(u\=l\{0,2}\|ll\=u\)\>"
"hex number
syn match hidemacNumber		display contained "0x\x\+\(u\=l\{0,2}\|ll\=u\)\>"
" Flag the first zero of an octal number as something special
syn match hidemacOctal		display contained "0\o\+\(u\=l\{0,2}\|ll\=u\)\>" contains=hidemacOctalZero
syn match hidemacOctalZero	display contained "\<0"
syn match hidemacFloat		display contained "\d\+f"
"floating point number, with dot, optional exponent
syn match hidemacFloat		display contained "\d\+\.\d*\(e[-+]\=\d\+\)\=[fl]\="
"floating point number, starting with a dot, optional exponent
syn match hidemacFloat		display contained "\.\d\+\(e[-+]\=\d\+\)\=[fl]\=\>"
"floating point number, without dot, with exponent
syn match hidemacFloat		display contained "\d\+e[-+]\=\d\+[fl]\=\>"
" flag an octal number with wrong digits
syn match hidemacOctalError	display contained "0\o*[89]\d*"
syn case match

syn match hidemacCommentSkip	contained "^\s*\*\($\|\s\+\)"
syn region hidemacCommentString	contained start=+L\=\\\@<!"+ skip=+\\\\\|\\"+ end=+"+ end=+\*/+me=s-1 contains=hidemacSpecial,hidemacCommentSkip
syn region hidemacComment2String	contained start=+L\=\\\@<!"+ skip=+\\\\\|\\"+ end=+"+ end="$" contains=hidemacSpecial
syn region  hidemacCommentL	start="//" skip="\\$" end="$" keepend contains=@hidemacCommentGroup,hidemacComment2String,hidemacCharacter,hidemacNumbersCom,hidemacSpaceError,@Spell
syn region hidemacComment	matchgroup=hidemacCommentStart start="/\*" end="\*/" contains=@hidemacCommentGroup,hidemacCommentStartError,hidemacCommentString,hidemacCharacter,hidemacNumbersCom,hidemacSpaceError,@Spell extend

syn match hidemacCommentError	display "\*/"
syn match hidemacCommentStartError display "/\*"me=e-1 contained

syn cluster hidemacMultiGroup	contains=hidemacCommentSkip,hidemacCommentString,hidemacComment2String,@hidemacCommentGroup,hidemacCommentStartError,hidemacUserCont,hidemacUserLabel,hidemacBitField,hidemacOctalZero,hidemacFormat,hidemacNumber,hidemacFloat,hidemacOctal,hidemacOctalError,hidemacNumbersCom
syn region hidemacMulti		transparent start='?' skip='::' end=':' contains=ALLBUT,@hidemacMultiGroup,@Spell,@hidemacStringGroup
syn cluster hidemacLabelGroup	contains=hidemacUserLabel
syn match hidemacUserCont	display "^\s*\I\i*\s*:$" contains=@hidemacLabelGroup
syn match hidemacUserCont	display ";\s*\I\i*\s*:$" contains=@hidemacLabelGroup

syn match hidemacUserCont	display "^\s*\I\i*\s*:[^:]"me=e-1 contains=@hidemacLabelGroup
syn match hidemacUserCont	display ";\s*\I\i*\s*:[^:]"me=e-1 contains=@hidemacLabelGroup

syn match hidemacUserLabel	display "\I\i*" contained

syn match hidemacBitField	display "^\s*\I\i*\s*:\s*[1-9]"me=e-1 contains=hidemacType
syn match hidemacBitField	display ";\s*\I\i*\s*:\s*[1-9]"me=e-1 contains=hidemacType

hi def link hidemacFormat	 hidemacSpecial
hi def link hidemacCommentL	 hidemacComment
hi def link hidemacCommentStart hidemacComment
hi def link hidemacLabel		Label
hi def link hidemacUserLabel		Label
hi def link hidemacConditional	Conditional
hi def link hidemacRepeat		Repeat
hi def link hidemacCharacter		Character
hi def link hidemacSpecialCharacter hidemacSpecial
hi def link hidemacNumber		Number
hi def link hidemacOctal		Number
hi def link hidemacOctalZero		PreProc	 " link this to Error if you want
hi def link hidemacFloat		Float
hi def link hidemacOctalError	 hidemacError
hi def link hidemacParenError	 hidemacError
hi def link hidemacErrInParen	 hidemacError
hi def link hidemacErrInBracket hidemacError
hi def link hidemacCommentError hidemacError
hi def link hidemacCommentStartError hidemacError
hi def link hidemacSpaceError	 hidemacError
hi def link hidemacSpecialError hidemacError
hi def link hidemacCurlyError	 hidemacError
hi def link hidemacOperator		Operator
hi def link hidemacStructure		Structure
hi def link hidemacStorageClass	StorageClass
hi def link hidemacInclude		Include
hi def link hidemacPreProc		PreProc
hi def link hidemacDefine		Macro
hi def link hidemacIncluded	 hidemacString
hi def link hidemacError		Error
hi def link hidemacFunction		Function
hi def link hidemacStatement		Statement
hi def link hidemacPreConditMatch hidemacPreCondit
hi def link hidemacPreCondit		PreCondit
hi def link hidemacType		Type
hi def link hidemacConstant		Constant
hi def link hidemacCommentString hidemacString
hi def link hidemacComment2String hidemacString
hi def link hidemacCommentSkip hidemacComment
hi def link hidemacString		String
hi def link hidemacComment		Comment
hi def link hidemacIdentifier		Identifier
hi def link hidemacSpecial		Special
hi def link hidemacTodo		Todo
hi def link hidemacBadContinuation	Error

