function jhv#util#InsertText(text, bytepos)
	let curline = getline('.')
	let curpos = getpos('.')
	let parts = [
		\ strpart(curline, 0, a:bytepos),
		\ a:text,
		\ strpart(curline, a:bytepos)
	\ ]
	call setline('.', join(parts, ''))
	if a:bytepos < curpos[2]
		let curpos[2] += len(a:text)
		call setpos('.', curpos)
	endif
	return ''
endfunction

function jhv#util#DeleteText(nbytes, bytepos)
	let curline = getline('.')
	let curpos = getpos('.')
	let rmend = a:bytepos + a:nbytes
	call setline('.', strpart(curline, 0, a:bytepos) . strpart(curline, rmend))
	if a:bytepos < curpos[2]
		let curpos[2] = max([a:bytepos+1, curpos[2] - a:nbytes])
		call setpos('.', curpos)
	endif
	return ''
endfunction
