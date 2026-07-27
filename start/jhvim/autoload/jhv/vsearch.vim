function jhv#vsearch#Search(chr, useic)
	" search() does not allow use of n/p to go to next.
	" chr: search direction '/'=forward, '?'=backward
	" useic: false = case sensitive, always exact
	"        true  = use the value of &g:ignorecase
	let ret = ["\<C-\>\<C-N>", a:chr, '\V']
	if a:useic && &g:ignorecase
		call add(ret, '\c')
	else
		call add(ret, '\C')
	endif
	let curmode=mode()
	if curmode ==# 'v'
		let col1 = col('v')
		let col2 = col('.')
		if col2 < col1
			let [col1,col2] = [col2, col1]
		endif
		let col1 -= 1
		call add(ret, escape(strpart(getline('.'), col1, col2-col1), '\/'))
	elseif curmode ==# 'V'
		call insert(ret, '^', 1)
		call add(ret, trim(escape(getline('.'), '\/')))
	else
		return "\<C-\>\<C-N>"
	endif
	call add(ret, "\<CR>")
	return join(ret, '')
endfunction

function jhv#vsearch#NoteSearch()
	" Search for the -N.N.N- that I use for header in my notes.
	" Allow N to also be X to indicate un-set numbering
	" It should be surrounded by some kind of barrier
	" usually ---- or =====
	"

	let curline = getline('.')
	let curcol = col('.') - 1
	let idx = 0
	let pattern = '\m\(.\{-0,}\)\([^[:alnum:][:blank:]]\%([0-9]\+\|[xX]\)\%(\.\%([0-9]\+\|[xX]\)\)*\%([^[:alnum:].]\|$\)\)'
	let result = matchlist(curline, pattern, 0)
	let best = len(curline)
	let target = ''
	while len(result)
		let beg = idx + len(result[1])
		let end = idx + len(result[0])
		if beg <= curcol && curcol < end
			let target = result[2]
			break
		elseif curcol < beg
			let distance = beg-curcol
		else
			let distance = (curcol - end) + 1
		endif
		if distance < best
			let best = distance
			let target = result[2]
		endif
		let idx += end
		let result = matchlist(curline, pattern, idx)
	endwhile
	if len(target)
		let pattern = join([
			\ '\m^[[:blank:]]*\(.\)\1*\_$\_.',
			\ '\_^[[:blank:]]*\V', escape(target, '\/')], '')
		return search(pattern, 's') . 'zt'

		"return join([
		"	\ "\<C-\>\<C-N>",
		"	\ '/\m^[[:blank:]]*\(.\)\1*\_$\_.',
		"	\ '\_^[[:blank:]]*\V', target,
		"	\ "\<CR>:nohl\<CR>zt"], '')
	endif
	echo 'No notes title detected.'
	return ''
endfunction
