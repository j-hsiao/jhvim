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
" {ch: {ft: [[prepat[, target]],...]}}
"   ch: the character that was just removed.
"   ft: the filetype, empty string for deafult
"   prepat: pattern before (not including) deleted character
"           (ie group1 = extra characters to delete)
"   target: empty string: push prepat group1 + ch to stack
"           non-empty string: pop this string from stack
"           omitted: neither
let s:rpats = {}

let s:StepRight = "\<C-G>U\<Right>"
let s:StepLeft = "\<C-G>U\<Left>"
let s:PreBackSlash = '\m\\\@1<!\%(\%(\\\\\)*)\@>\(\\\)$'
let s:Prebackslash = '\\\@1<!\%(\%(\\\\\)\*\)\@>\\'

"Use TMap to extend keymappings, otherwise overwrite.
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
	" Return {ch: [patterns],...}
	let iopats = []
	ret = {a:c1: iopats}
	if a:c1 == a:c2
		let icpats = iopats
	else
		let icpats = []
		let ret[a:c2] = icpats
	endif
	let e1 = escape(a:c1, '\/')
	let e2 = escape(a:c2, '\/')
	let L1 = strchars(a:c1, 1)
	let L2 = strchars(a:c2, 1)
	if flags =~ 'b'
		call add(iopats, [s:PreBackSlash, '', a:c1])
	elseif flags =~ 'r'
		if flags =~ 'r%'
			call add(iopats, [s:PreBackSlash[:-2] . '%\{,2}$', '',
				\ join([a:c1, '\', a:c2, repeat(s:StepLeft, 1+L2)])])
		else
			call add(iopats, [s:PreBackSlash, '',
				\ join([a:c1, '\', a:c2, repeat(s:StepLeft, 1+L2)])])
		endif
		if !has_key(s:ipats, '\')
			let ret['\'] = [['', '\m^\\', s:StepRight]]
			call jhv#mappings#TMap(
				\ 'add=> inoremap <expr> <silent> <special> <Bslash> jhv#pair#Insert(''<Bslash>'')')
		endif
	endif
	call add(icpats, ['', '\m^\V' . e2, repeat(s:StepRight, L2)])
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
			\ printf('%s\V\%%(%s\)\{3}\$', allowedpre, e1),
			\ '\m$\|\W', repeat(a:c2, 3) . repeat(s:StepLeft,3)])
		call add(icpats, [
			\ printf('%s\V\%%(%s\)\{2}\$', allowedpre, e1),
			\ '\m$\|\W', repeat(a:c2, 4) . repeat(s:StepLeft,3)])
	endif
	call add(iopats, [allowedpre, '\m$\|\W', a:c1 . a:c2 . repeat(s:StepLeft, L2)])
	return ret
endfunction

function s:CalcRpats(c1, c2, flags)
	"Calculate removal patterns
	" Return {ch: [patterns],...}
	let ropats = []
	let ret = {a:c1: ropats}
	if a:c2 == a:c1
		let rcpats = ropats
	else
		let rcpats = []
		let ret[a:c2] = rcpats
	endif
	let e1 = escape(a:c1, '\/')
	let e2 = escape(a:c2, '\/')
	if flags =~ 'b'
		call add(ropats, [s:PreBackSlash])
	elseif flags =~ 'r'
		if flags =~ 'r%'
			call add(ropats, [s:PreBackSlash[:-4] . '%\?\)$', '\' . a:c2])
		else
			call add(ropats, [s:PreBackSlash, '\' . a:c2])
		endif
		call add(rcpats, [s:PreBackSlash, ''])
	endif
	if a:c1 == a:c2
		if flags =~ 'b'
			let nopreb = printf('\%%(%s\)\@128<!', s:Prebackslash)
		else
			let nopreb = ''
		endif
		if flags =~ 't'
			let triple = printf('%s\%%(%s\)\{3}', nopreb, e1)
			let double = printf('%s\%%(%s\)\{2}', nopreb, e1)
			let tpaired = printf('%s\.\{-}%s', triple, triple)
			let notT = printf('\%%(%s\)\@!\.', triple)
			let notTE = printf('\%%(%s\%%(%s\|\$\)\)\@!\.', double, e1)
			let endTpair = printf('\(%s\.\{-}%s\)\$', triple, double)
			call add(rcpats, [printf('\V\^\%%(\%%(%s\|%s\)\*\)\@>%s', notT, tpaired, endTpair), ''])
			call add(ropats, [printf('\V\^\%%(\%%(%s\|%s\)\*\)\@>\(%s\)\$', notTE, tpaired, double), repeat(a:c2, 3)])
		endif
		let ch = printf('%s%s', nopreb, e1)
		let pair = printf('%s\.\{-}%s', ch, ch)
		call add(rcpats, [printf('\V\^\%%(\%%(\%%(%s\)\@!\.\|%s\)\*\)\@>%s', ch, pair, ch), ''])
		call add(rcpats, [printf('\V\^\%%(\%%(\%%(%s\)\@!\.\|%s\)\*\)\@>\$', ch, pair), a:c2])
	else
		call add(ropats, ['', a:c2])
		call add(rcpats, ['', ''])
	endif
	return ret
endfunction

"Add a pair of characters to autopair.
"extra args or flags, (ft[,ft]...=flags)
function jhv#pair#Add(c1, c2, ...)
	let s:ipats[a:c1] = {}
	let s:rpats[a:c1] = {}
	if a:c2 != a:c1
		let s:ipats[a:c2] = {}
		let s:rpats[a:c2] = {}
	endif
	let added = []
	for ftflags in a:0 ? a:000 : ['']
		let parts = matchlist(ftflags, '\m^\(\^\)\?\%(\([^=]*\)=\)\?\(.*\)$')
		if empty(parts)
			throw printf('Bad pair flag: %s', ftflags)
		endif
		let [whole, exclude, ftypes, flagstr; ignore] = parts
		if flagstr =~ 'b' && flagstr =~ 'r'
			throw 'Error: b and r pair flags are mutually exclusive.'
		endif
		if !empty(exclude)
			if empty(ftypes)
				let ftypes = ftflags
			endif
			for ft in split(ftypes, ',', v:true)
				let [s:ipats[a:c1][ft], s:ipats[a:c2][ft],
					\ s:rpats[a:c1][ft], s:rpats[a:c2][ft]] = [[], [], [], []]
			endfor
			continue
		endif
		for ft in split(ftypes, ',', v:true)
			for dst, pats in [
				\ [s:ipats, s:CalcIpats(a:c1, a:c2, flagstr)],
				\ [s:rpats, s:CalcRpats(a:c1, a:c2, flagstr)]
			\ ]
				for ch, lst in items(pats)
					if !has_key(dst, ch)
						let dst[ch] = {}
						call add(added, ch)
					endif
					dst[ch][ft] = lst
				endfor
			endfor
		endfor
	endfor
	let pat = 'inoremap <expr> <silent> <special> %s jhv#pair#Insert(%s)'
	for item in added
		let keynot = jhv#mappings#AsKeyNotation(item)
		let mpcmd = printf(
			\ pat, keynot,
			\ jhv#mappings#AsKeyNotation(jhv#mappings#AsEval(keynot)))
		if g:jhv#pair#extend
			call jhv#mappings#Tmap('add=>', printf('name=add_pair_%s', item), mpcmd)
		else
			exe mpcmd
		endif
	endfor
endfunction


"===
"old
"===

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
