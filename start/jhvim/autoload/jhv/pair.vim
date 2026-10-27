" Insert insertion if prepat matches before cursor and postpat matches after
" cursor.
" {ch: {ft: [[prepat, postpat, insertion]...]}}
"   ch: the character (opening or closing)
"   ft: the filetype, empty string for the default settings.
"   prepat: regex matching before the insertion point.
"   postpat: regex to match after the insertion point.
"   insertion: the character to insert if both prepat and postpat match.
let s:ipats = {}

" Removal patterns.
" {ch: {ft: [[prepat, target],...]}}
"   ch: the character that was just removed.
"   ft: the filetype, empty string for deafult
"   prepat: pattern before (not including) deleted character
"           (ie group1 = extra characters to delete)
"   target: corresponding close character(s) if any
let s:rpats = {}

let s:StepRight = "\<C-G>U\<Right>"
let s:StepLeft = "\<C-G>U\<Left>"
let s:PreBackSlash = '\m\%(^\|[^\\]\)\%(\\\\\)*\(\\\)$'

"Use TMap to extend added keymapping, otherwise overwrite.
let jhv#pair#extend = get(g:, 'jhv#pair#extend', 1)

"Show the pair settings.
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

function s:CalcIpats(c1, c2, flags)
	let iopats = []
	let icpats = a:c1 == a:c2 ? iopats : []
	let L1 = strchars(a:c1, 1)
	let L2 = strchars(a:c2, 1)
	if flags =~ 'b'
		call add(iopats, [s:PreBackSlash, '', a:c1])
	elseif flags =~ 'r'
		if flags =~ 'r%'
			call add(iopats, [s:PreBackSlash[:-2] . '%\?$', '',
				\ join([a:c1, '\', a:c2, repeat(s:StepLeft, 1+L2)])])
		else
			call add(iopats, [s:PreBackSlash, '',
				\ join([a:c1, '\', a:c2, repeat(s:StepLeft, 1+L2)])])
		endif
		if !has_key(s:ipats, '\')
			let s:ipats['\'] = {}
			call jhv#mappings#TMap(
				\ 'add=> inoremap <expr> <silent> <special> <Bslash> jhv#pair#Insert(''<Bslash>'')')
		endif
	endif
	call add(icpats, ['', '\m^\V' . escape(a:c2, '\/'), repeat(s:StepRight, L2)])
	let allowedpre = ''
	if flags =~ 'W'
		if flags =~ 'p'
			let allowedpre = '\m\%(^\|\W\|[rfbut]\)'
		else
			let allowedpre = '\m\%(^\|\W\)'
		endif
	endif
	if flags =~ 't' && a:c1 == a:c2
		call add(icpats, [
			\ printf('%s\V\%%(%s\)\{3}\$', allowedpre, escape(a:c1, '\/')),
			\ '\m$\|\W', repeat(a:c2, 3) . repeat(s:StepLeft,3)])
		call add(icpats, [
			\ printf('%s\V\%%(%s\)\{2}\$', allowedpre, escape(a:c1, '\/')),
			\ '\m$\|\W', repeat(a:c2, 4) . repeat(s:StepLeft,3)])
	endif
	call add(iopats, [allowedpre, '\m$\|\W', a:c1 . a:c2 . repeat(s:StepLeft, L2)])
	return [iopats, icpats]
endfunction

function s:CalcRpats(c1, c2, flags)
	"Calculate removal patterns
	let ropats = []
	let rcpats = a:c2 == a:c1 ? ropats : []
	if flags =~ 'b'
		call add(ropats, [s:PreBackSlash, ''])
	elseif flags =~ 'r'
		if flags =~ 'r%'
			call add(ropats, [s:PreBackSlash[:-4] . '%\)$', '\' . a:c2])
		endif
		call add(ropats, [s:PreBackSlash, '\' . a:c2])
		call add(rcpats, [s:PreBackSlash, ''])
	endif
	if flags =~ 't' && a:c1 == a:c2
		call add(ropats, [printf('\V\%%(%s\)\{2}', escape(a:c1, '\/')), repeat(a:c2, 3)])

		let lpat = printf('\%%(^\|[^%s]\)\(\V%s\m\)',
			\ escape(a:c1, '^-]\'), escape(repeat(a:c2, 2), '\/'))
		let emptypair = printf('\V\(%s%s\)\$',
			\ repeat(escape(a:c1, '\/'), 3),
			\ repeat(escape(a:c2, '\/'), 2))
		call add(rcpats, emptypair)
		call add(rcpats, fullpair)
	endif
	call add(rcpats, printf('\V\(%s\)\$', escape(a:c1, '\/')))
	call add(rcpats, '')
	call add(ropats, ['', a:c2])
	return [ropats, rcpats]
endfunction


	"if bflag && rflag
	"	throw 'Error: bflag and rflag are mutually exclusive.'
	"endif
"===
"old
"===

function s:CalcIpats(c1, c2, flaglist)
	" Calculate insertion pattern for open/close
	let [bflag, rflag, Wflag, tflag] = a:flaglist
	let iopats = []
	let icpats = a:c1 == a:c2 ? iopats : []
	if bflag && rflag
		throw 'Error: bflag and rflag are mutually exclusive.'
	endif
	if bflag
		call add(iopats, ['\m\%(^\|[^\\]\)\%(\\\\\)*\\$', '', a:c1])
	elseif rflag
		call add(iopats, ['\m\%(^\|[^\\]\)\%(\\\\\)*\\$', '',
			\ join([a:c1, '\', a:c2, repeat(s:StepLeft, 2)], '')])
		if !has_key(s:ipats, '\')
			let s:ipats['\'] = {}
			call jhv#mappings#TMap(
				\ 'add=> inoremap <expr> <silent> <special> <Bslash> jhv#pair#Insert(''<Bslash>'')')
		endif
	endif
	call add(icpats, ['', '\m^\V' . escape(a:c2, '\/'), s:StepRight])
	if tflag && a:c1 == a:c2
		if Wflag
			"Allows triple after a word-like
			"example: r""""""
			let insertion = repeat(a:c2, 3) . repeat(s:StepLeft, 3)
			let prepat = printf('\V%s\$', repeat(escape(a:c1, '\/'), 3))
			call add(icpats, [prepat, '\m^$\|^\W', insertion])
		endif
		let insertion = repeat(a:c2, 4) . repeat(s:StepLeft, 3)
		let prepat = printf('\V%s\$', repeat(escape(a:c1, '\/'), 2))
		call add(iopats, [prepat, '\m^$\|^\W', insertion])
	endif
	if Wflag
		call add(iopats, ['\m^$\|\W$', '\m^$\|^\W', a:c1 . a:c2 . repeat(s:StepLeft, len(a:c2))])
	else
		call add(iopats, ['', '\m^$\|^\W', a:c1 . a:c2 . repeat(s:StepLeft, len(a:c2))])
	endif
	return [iopats, icpats]
endfunction

function s:CalcRpats(c1, c2, flaglist)
	"Calculate removal patterns
	let [bflag, rflag, Wflag, tflag] = a:flaglist
	let ropats = []
	let rcpats = []
	if bflag
		call add(ropats, ['\%(^\|[^\\]\)\%(\\\\\)*\(\\\)$', ''])
	elseif rflag
		call add(ropats, ['\%(^\|[^\\]\)\%(\\\\\)*\(\\\)$', '\' . a:c2])
		call add(rcpats, '\%(^\|[^\\]\)\%(\\\\\)*\(\\\)$')
	endif
	if tflag
		let lpat = printf('\%%(^\|[^%s]\)\(\V%s\m\)',
			\ escape(a:c1, '^-]\'), escape(repeat(a:c2, 2), '\/'))
		call add(ropats, [lpat, repeat(a:c2, 3)])
		let emptypair = printf('\V\(%s%s\)\$',
			\ repeat(escape(a:c1, '\/'), 3),
			\ repeat(escape(a:c2, '\/'), 2))
		let fullpair = printf('\V%s\.\*\(%s\)\$',
			\ repeat(escape(a:c1, '\/'), 3),
			\ repeat(escape(a:c2, '\/'), 2))
		call add(rcpats, emptypair)
		call add(rcpats, fullpair)
	endif
	call add(rcpats, printf('\V\(%s\)\$', escape(a:c1, '\/')))
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
	let iodict = {}
	let icdict = a:c1 == a:c2 ? iodict : {}

	let rodict = {}
	let rcdict = {}
	for flag in flags
		let parts = matchlist(flag, '\m^\(\^\)\?\%(\([^=]*\)=\)\?\(.*\)$')
		if empty(parts)
			throw printf('Bad pair flag: %s', flag)
		endif
		let [exclude, ftypes, flagstr] = parts[1:3]
		if !empty(exclude)
			if empty(ftypes)
				let ftypes = flagstr
			endif
			for ft in split(ftypes, ',', v:true)
				let [iodict[ft], icdict[ft], rodict[ft], rcdict[ft]] = [[],[],[],[]]
			endfor
			continue
		endif
		let flaglist = []
		for item in 'brWt'
			call add(flaglist, flagstr =~ item)
		endfor
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
		if g:jhv#pair#extend
			call jhv#mappings#TMap('add=>', cmd)
		else
			exe cmd
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
	" TODO
	" if cursor is at beginning... maybe should use
	" getline(line('.')-1)??
	let b:jhv_pair_pre_remove = [col('.'), getline('.')]
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
				let sidx -= 1
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
	let [precol, previous] = b:jhv_pair_pre_remove
	if precol == 1
		"From experimentation, it seems backwards deletes
		"From column 1 will at most delete the joining newline.
		"If greater than column 1, then at most to start of current line.
		return ''
	endif
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
