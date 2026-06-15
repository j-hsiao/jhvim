" {opening: [closing, {ft: [ipats, rpats]}]}
" {closing: opening}
"
" ipats: [[prepat, postpat, insertion], ...]
"   For each item in insertpats if prepat and postpat match, use insertion
"   Otherwise, use c1 . c2
" rpats: [[prepat, postpat], ...]  If both patterns match, then remove
"   the matched group1 of each pattern.

let s:pairs = [{}, {}]
"Skip regex to find the next close/open for processing.
let s:rmskip = '\m^.*$'

let s:ipats = {}

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
	let s:rmskip = ''
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
		for item in 'brW'
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
					let s:ipats['\'][ft] = [
						\ ['', '\m^\\', s:StepRight],
						\ ['', '', '\']
					\]
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


function s:RmSkip()
	if empty(s:rmskip)
		let characters = []
		for chs in items(s:pairs[1])
			call extend(characters, chs)
		endfor
		let pairs = escape(join(characters, ''), '^]-\')
		let s:rmskip = printf('\m\([%s]\)[^%s]*$', pairs, pairs)
	endif
	return s:rmskip
endfunction
function jhv#pair#PrepRemove()
	"Prep for removal to see what was deleted
	let b:jhv_pair_removed = strpart(getline('.'), 0, col('.')-1)
endfunction
function jhv#pair#RemoveLeft()
	let previous = b:jhv_pair_removed
	let curline = getline('.')
	let curidx = col('.')-1
	let removed = strpart(previous, curidx, len(previous) - len(curline))
	let after = strpart(curline, curidx)
	let lidx = len(removed)
	let ridx = 0
	let extra = []

	let rmpat = s:RmSkip()
	let removal = matchlist(strpart(removed, lidx))
	while not empty(get(removal, 1, ''))
		let lidx -= len(removal[0]) - 1
		for [prepat, postpat] in s:rpats[removal[1]]

		endfor
		let removal = matchlist(strpart(removed, lidx))
	endwhile

	while lidx
		lidx -= 1
		if has_key(s:pairs[0], removed[lidx])
			let [closing, flagd] = s:pairs[0][removed[lidx]]
			let [bflag, rflag] = get(flagd, &l:ft, flagd[''])
			if empty(extra)
				# remove from after
				if cflag
				elseif bflag
				elseif rflag
				endif
			else
				let matched = matchlist(removed[:lidx], extra[-1])
				if len(get(matched, 1, ''))
					let lidx -= len(matched[1]) - 1
					call remove(extra, -1)
				endif
			endif
		elseif has_key(s:pairs[1], removed[lidx])
			let opening = s:pairs[1][removed[lidx]]
			let [closing, flagd] = s:pairs[0][opening]
			let [bflag, rflag] = get(flagd, &l:ft, flagd[''])
			if cflag
				continue
			elseif bflag
				if removed[:lidx] =~ '\m\%(^\|[^\\]\)\(\\\\\|\\%s$\)*$'

				call add(extra, )
				if ! escaped
					add opening to extra
				endif
			elseif rflag
				"if escaped
				"	add bslash opening to extra
				"else
				"	add opening to extra
				"endif
			endif
		endif
	endwhile
endfunction


