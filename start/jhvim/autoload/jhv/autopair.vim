let s:pairs = [{}, {}]


for [s:k,s:v] in items(s:pairs[0])
	let s:pairs[1][s:v] = s:k
endfor


function jhv#autopair#Add(c1, c2, ...)
	if a:0
		let flags = a:1
	else
		let flags = ''
	endif
	let s:pairs[0][a:c1] = [a:c2, flags]
	let s:pairs[1][a:c2] = a:c1

	let pat = 'inoremap <expr> <silent> <special> %s jhv#autopair#Insert(%s)'
	let items = [a:c1]
	if a:c2 != a:c1
		call add(items, a:c2)
	endif
	for item in items
		let lhs = substitute(item, '<', '<lt>', 'g')
		let rhs = substitute(string(item), '<', '<lt>', 'g')
		call jhv#mappings#ExtendMap(printf(pat, lhs, rhs))
	endfor
endfunction

function jhv#autopair#Insert(c)
	if has_key(s:pairs[0], a:c)
		let opening = a:c
	else
		let opening = s:pairs[1][a:c]
	endif
	let [closing, flags] = s:pairs[0][opening]

	let curtxt = getline('.')
	let curidx = col('.')-1
	let pre = strpart(curtxt, 0, curidx)
	let post = strpart(curtxt, curidx)
	echom [pre, post, a:c, opening, closing]

	if opening == closing
		" TODO determine whether opening or closing...
	else
		let opened = (a:c == opening)
	endif

	if opened
		let parts = []
		let bchar = ''
		if flags =~ '.*r.*'
			let bslash = match(pre, '\m\\*$')
			if bslash >= 0
				if (len(pre) - bslash) % 2
					let bchar = '\'
				endif
			endif
		endif
		return join([
			\ opening, bchar, closing,
			\ repeat("\<C-G>U\<Left>", len(closing) + len(bchar))], '')
	else
		if post[:0] == closing
			return "\<C-G>U\<Right>"
		else
			return a:c
		endif
	endif
endfunction



function jhv#autopair#PrepRemove()
	"Prep for removal to see what was deleted
	let b:jhv_autopair_removed = strpart(getline('.'), 0, col('.')-1)
endfunction

function jhv#autopair#Remove()
	let cur = strpart(getline('.'), 0, col('.')-1)
	let b:jhv_autopair_removed
	" TODO search through removed to text to remove closing pair if
	" applicable.
endfunction
