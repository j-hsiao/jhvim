"Add bindings to surround visual selection with a character

function! s:Surround(char1, ...)
	if a:0
		let ending = a:1
	else
		let ending = a:char1
	endif
	if exists('*virtcol')
		let col1 = virtcol('v')
		let col2 = virtcol('.')
	else
		let curline = getline('.')
		let col1 = strdisplaywidth(strpart(curline, 0, col('v')))
		let col2 = strdisplaywidth(strpart(curline, 0, col('.')))
	endif
	if col2 < col1
		let [col1,col2] = [col2,col1]
	endif
	return printf("\<Esc>%s|a%s\<Esc>%s|i%s\<Esc>", col2, ending, col1, a:char1)
endfunction

if maparg("<Leader>'", 'v') == ''
	vnoremap <expr> <Leader>' <SID>Surround("'")
endif
if maparg('<Leader>"', 'v') == ''
	vnoremap <expr> <Leader>" <SID>Surround('"')
endif
if maparg('<Leader>(', 'v') == ''
	vnoremap <expr> <Leader>( <SID>Surround('(', ')')
endif
if maparg('<Leader>[', 'v') == ''
	vnoremap <expr> <Leader>[ <SID>Surround('[', ']')
endif
