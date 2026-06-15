" {ch: {ft: [[prepat, postpat, insertion]...]}}
let s:ipats = {}

" {ch: {ft: [[prepat, target],...]}}, {ch: {ft: [pat,...]}}
let s:rpats = [{}, {}]

let s:StepRight = "\<C-G>U\<Right>"
let s:StepLeft = "\<C-G>U\<Left>"

function jhv#pair#Show()
	echom 'ipats'
	for [ch, ftd] in items(s:ipats)
		echom printf('  ch: %s', ch)
		for [ft, info] in items(ftd)
			echom printf('    %s: %s', ft, info)
		endfor
	endfor

	for idx in [0, 1]
		echom printf('rpats%d', idx)
		for [ch, ftd] in items(s:rpats[idx])
			echom printf('  ch: %s', ch)
			for [ft, info] in items(ftd)
				echom printf('    %s: %s', ft, info)
			endfor
		endfor
	endfor
endfunction

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

function s:CalcRpats(c1, c2, flaglist)
	"Calculate removal patterns
	let [bflag, rflag] = a:flaglist
	let ropats = []
	let rcpats = []
	if bflag
		call add(ropats, ['\%(^\|[^\\]\)\%(\\\\\)*\(\\\)$', ''])
	elseif rflag
		call add(ropats, ['\%(^\|[^\\]\)\%(\\\\\)*\(\\\)$', '\' . a:c2])
		call add(rcpats, '\%(^\|[^\\]\)\%(\\\\\)*\(\\\)$')
	endif
	call add(rcpats, '')
	call add(ropats, ['', a:c2])
	return [ropats, rcpats]
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

	let rodict = {}
	let rcdict = {}
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
			let [rodict[ft], rcdict[ft]] = s:CalcRpats(a:c1, a:c2, flaglist)
		endfor
	endfor
	let s:rpats[0][a:c1] = rodict
	let s:rpats[1][a:c2] = rcdict

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
	let b:jhv_pair_pre_remove = getline('.')
	return ''
endfunction

function s:RemoveOpen(before, lidx, after, ridx, stack)
	let before = strpart(a:before, 0, a:lidx)
	let ftpats = s:rpats[0][a:before[a:lidx]]
	for [lreg, target] in get(ftpats, &l:ft, get(ftpats, '', []))
		let lmatch = matchlist(before, lreg)
		if !empty(lmatch)
			let sidx = len(a:stack) - 1
			while sidx >= 0
				if a:stack[sidx] == target
					call remove(a:stack, sidx, -1)
					return [len(lmatch[1]), 0]
				endif
			endwhile
			if strpart(a:after, a:ridx, len(target)) == target
				if !empty(a:stack)
					call remove(a:stack, 0, -1)
				endif
				return [len(lmatch[1]), len(target)]
			endif
		endif
	endfor
	return [0,0]
endfunction

function s:RemoveClose(before, lidx, stack)
	let before = strpart(a:before, 0, a:lidx)
	let ftpats = s:rpats[1][a:before[a:lidx]]
	for pat in get(ftpats, &l:ft, get(ftpats, '', []))
		let lmatch = matchlist(before, pat)
		if !empty(lmatch)
			call add(a:stack, lmatch[1] . a:before[a:lidx])
			return len(lmatch[1])
		endif
	endfor
	return 0
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
	let startidx = col('.')-1
	let before = strpart(previous, 0, startidx + (len(previous) - len(curline)))
	let after = strpart(curline, startidx)
	let lidx = len(before)
	let ridx = 0
	let softstack = []

	while lidx > startidx
		let lidx -= 1
		if has_key(s:rpats[0], before[lidx])
			let [dl, dr] = s:RemoveOpen(before, lidx, after, ridx, softstack)
			if dl || dr
				let lidx -= dl
				let ridx += dr
				continue
			endif
		endif
		if has_key(s:rpats[1], before[lidx])
			let dl = s:RemoveClose(before, lidx, softstack)
			let lidx -= dl
		endif
	endwhile
	return repeat("\<Del>", ridx) . repeat("\<BS>", startidx - lidx)
endfunction
