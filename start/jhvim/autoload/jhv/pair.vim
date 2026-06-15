" {opening: [closing, {ft: [ipats, rpats]}]}
" {closing: opening}
"
" ipats: [[prepat, postpat, insertion], ...]
"   For each item in insertpats if prepat and postpat match, use insertion
"   Otherwise, use c1 . c2
" rpats: [[prepat, postpat], ...]  If both patterns match, then remove
"   the matched group1 of each pattern.

" ch: [[prepat, postpat, insertion]...]
let s:ipats = {}

"
" och: [[prepat, target]] -> matched before and after respectively
" cch: [pat, ...] -> stuff to remove...
let s:rpats = [{}, {}]


let s:StepRight = "\<C-G>U\<Right>"
let s:StepLeft = "\<C-G>U\<Left>"

function s:CalcIpats(c1, c2, flaglist)
	" Calculate insertion pattern for open/close
	let [bflag, rflag] = a:flaglist
	let iopats = []
	let icpats = a:c1 == a:c2 ? iopats : []
	if bflag && rflag
		throw 'Error: bflag and rflag are mutually exclusive.'
	endif
	if bflag
		call add(iopats, ['\m\%(^\|[^\\]\)\%(\\\\\)*\\$', '', a:c1])
	elseif rflag
		call add(iopats, ['\m\%(^\|[^\\]\)\%(\\\\\)*\\$', '',
			\ join([a:c1, '\', a:c2, repeat(s:StepLeft, 1 + len(a:c2))], '')])
		if !has_key(s:ipats, '\')
			let s:ipats['\'] = {}
			call jhv#mappings#ExtendMap(
				\ 'inoremap <expr> <silent> <special> <Bslash> jhv#pair#Insert(''<Bslash>'')')
		endif
	endif
	call add(icpats, ['', '\V' . escape(a:c2, '\/'), s:StepRight])
	call add(iopats, ['', '', a:c1 . a:c2 . repeat(s:StepLeft, len(a:c2))])
	if a:c1 != a:c2
		call add(icpats, ['', '', a:c2])
	endif
	return [iopats, icpats]
endfunction

function jhv#pair#Add(c1, c2, ...)
	let s:ipats[a:c1] = {}
	if a:c2 != a:c1
		let s:ipats[a:c2] = {}
	endif

	let flags = a:0 ? a:000 : ['']
	let hasdefault = v:false
	let forced = v:false
	let iodict = {}
	let icdict = a:c1 == a:c2 ? iodict : {}
	for flag in flags
		let parts = split(flag, '=', v:true)
		if len(parts) == 1
			let parts = ['', parts[0]]
		elseif len(parts) != 2
			throw 'Invalid flags: ' . flag
		endif
		let [ftypes, flagstr] = parts
		let flaglist = []
		for item in 'br'
			call add(flaglist, flagstr =~ item)
		endfor
		if flagstr =~ 'f'
			let forced = v:true
		endif
		let [iopats, icpats] = s:CalcIpats(a:c1, a:c2, flaglist)
		for ft in split(ftypes, ',', v:true)
			let iodict[ft] = iopats
			let icdict[ft] = icpats
			if flaglist[1]
				if !has_key(s:ipats['\'], ft)
					let s:ipats['\'][ft] = [['', '\m^\\', s:StepRight]]
				endif
			endif
		endfor
	endfor

	let s:ipats[a:c1] = iodict
	let pat = 'inoremap <expr> <silent> <special> %s jhv#pair#Insert(%s)'
	if a:c2 != a:c1
		let s:ipats[a:c2] = icdict
		let items = [a:c1, a:c2]
	else
		let items = [a:c1]
	endif
	for item in items
		let lhs = substitute(substitute(item, '<', '<lt>', 'g'), '\\', '<Bslash>', 'g')
		let rhs = substitute(substitute(string(item), '<', '<lt>', 'g'), '\\', '<Bslash>', 'g')
		let cmd = printf(pat, lhs, rhs)
		if forced
			exe cmd
		else
			call jhv#mappings#ExtendMap(cmd)
		endif
	endfor
endfunction


function jhv#pair#Insert(c)
	let ftpats = s:ipats[a:c]
	let curtxt = getline('.')
	let curidx = col('.')-1
	let pre = strpart(curtxt, 0, curidx)
	let post = strpart(curtxt, curidx)
	for [prepat, postpat, insertion] in get(ftpats, &l:ft, get(ftpats, '', []))
		if match(pre, prepat)>=0 && match(post, postpat)>=0
			return insertion
		endif
	endfor
	return a:c
endfunction


function jhv#pair#PrepRemove()
	"Prep for removal to see what was deleted
	let b:jhv_pair_pre_remove = strpart(getline('.'), 0, col('.')-1)
endfunction

"When removing...
"()|)
" From | to beginning, would expect a single ) remaining.
" If don't detect closing chars, after 1 deletion, see (), so delete the )
" afterwards aswell. which is undesired.  However, closing does not
" necessarily mean an opening char exists:
" example: ')|' -> would search for an opening ( which does not exist.
" As a result, the () is never closed and the ending quote is never removed.
" therefore... generate a soft-stack.  push closing char onto soft stack.
" If opening char detected and matches end of soft stack, pop it.
" Othewrise, compare with right string.  If removal, clear the stack too.
function jhv#pair#RemoveLeft()
	let previous = b:jhv_pair_pre_remove
	let curline = getline('.')
	let curidx = col('.')-1
	let before = strpart(previous, 0, curidx + (len(previous) - len(curline)))
	let after = strpart(curline, curidx)
	let lidx = len(before)
	let ridx = 0
	let softstack = []
	while lidx > curidx
		let lidx -= 1
		if has_key(s:rpats[0], before[lidx])
			let before = before[:lidx]
			for [lreg, target] in s:rpats[0][before[lidx]]
				let lmatch = matchlist(before, lreg)
				if !empty(lmatch)
					let sidx = len(softstack) - 1
					while sidx >= 0
						if softstack[sidx] == target
							call remove(softstack, sidx, -1)
							let lidx -= len(lmatch[1])-1
							break
						endif
						let sidx -= 1
					endwhile
					if sidx >= 0
						break
					elseif after[ridx:ridx+(len(target)-1)] == target
						let lidx -= len(lmatch[1])-1
						let ridx += len(target)
						call remove(softstack, 0, -1)
						break
					endif
				endif
			endfor
		elseif has_key(s:rpats[1], before[lidx])
			let before = before[:lidx]
			for pat in s:rpats[1][before[lidx]]
				let lmatch = matchlist(before, pat)
				if !empty(lmatch)
					call add(softstack, lmatch[1])
					break
				endif
			endfor
		endif
	endwhile
	return repeat("\<Del>", ridx)
endfunction
