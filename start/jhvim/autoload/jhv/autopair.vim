let s:pairs = [{}, {}]

function jhv#autopair#Add(c1, c2, ...)
	let s:pairs[0][a:c1] = [a:c2]
	let s:pairs[1][a:c2] = a:c1
	let flags = a:0 ? a:000 : ['']
	let flagdict = {}
	let forced = v:false
	for flag in flags
		let parts = split(flag, '=', v:true)
		if len(parts) == 1
			let parts = ['', parts[0]]
		endif
		let [ftypes, flagstr] = parts
		let flaglist = []
		for item in 'brWc'
			call add(flaglist, flagstr =~ item)
		endfor
		if flagstr =~ 'f'
			let forced = v:true
		endif
		for ft in split(ftypes, ',', v:true)
			let flagdict[ft] = flaglist
		endfor
	endfor
	if ! has_key(flagdict, '')
		let flagdict[''] = repeat([v:false], len(values(flagdict)[0]))
	endif
	call add(s:pairs[0][a:c1], flagdict)

	let pat = 'inoremap <expr> <silent> <special> %s jhv#autopair#Insert(%s)'
	if a:c2 != a:c1
		let items = [a:c1, a:c2]
	else
		let items = [a:c1]
	endif
	for item in items
		let lhs = substitute(item, '<', '<lt>', 'g')
		let rhs = substitute(string(item), '<', '<lt>', 'g')
		let cmd = printf(pat, lhs, rhs)
		if forced
			exe cmd
		else
			call jhv#mappings#ExtendMap(cmd)
		endif
	endfor
endfunction

function s:RegexEndsWith(c, ...)
	"Return a regex to check if a string ends with c enforcing escaped state.
	"optional arg:
	"  escaped=false: whether the char must be escaped or not.
	if a:0 ? a:1 : v:false
		return printf('\m\%%(^\|[^\\]\)\%%(\\\\\)*\(\\\V%s\m\)$', escape(a:c, '\/'))
	else
		return printf('\m\%%(^\|[^\\]\)\%%(\\\\\)*\(\V%s\m\)$', escape(a:c, '\/'))
	endif
endfunction

function jhv#autopair#Insert(c)
	if has_key(s:pairs[0], a:c)
		let opening = a:c
	else
		let opening = s:pairs[1][a:c]
	endif
	let [closing, flagd] = s:pairs[0][opening]
	let [bflag, rflag, Wflag, cflag] = get(flagd, &l:ft, flagd[''])

	let curtxt = getline('.')
	let curidx = col('.')-1
	let pre = strpart(curtxt, 0, curidx)
	let post = strpart(curtxt, curidx)

	if cflag
		let closepair = 1
	elseif opening == closing
		let closepair = post[:0] == closing
	else
		let closepair = a:c == closing
	endif

	if closepair
		if post[:0] == closing
			if bflag
				let bslash = match(pre, '\m\\*$')
				if bslash >= 0 && (len(pre) - bslash) % 2
					return closing
				endif
			endif
			return "\<C-G>U\<Right>"
		else
			return a:c
		endif
	else
		if Wflag
			if post[:0] =~ '\m\w'
				return opening
			endif
		endif
		let parts = [opening, closing]
		let extra = 0
		if rflag
			let bslash = match(pre, '\m\\*$')
			if bslash >= 0 && (len(pre) - bslash) % 2
				let parts = [opening, '\', closing]
				let extra = 1
			endif
		endif
		call add(parts, repeat("\<C-G>U\<Left>", len(closing) + extra))
		return join(parts, '')
	endif
endfunction


function jhv#autopair#PrepRemove()
	"Prep for removal to see what was deleted
	let b:jhv_autopair_removed = strpart(getline('.'), 0, col('.')-1)
endfunction
function jhv#autopair#RemoveLeft()
	let previous = b:jhv_autopair_removed
	let curline = getline('.')
	let curidx = col('.')-1
	let removed = strpart(previous, curidx, len(previous) - len(curline))
	let after = strpart(curline, curidx)
	let lidx = len(removed)
	let ridx = 0
	let extra = []
	while lidx
		lidx -= 1
		if has_key(s:pairs[0], removed[lidx])
			let [closing, flagd] = s:pairs[0][removed[lidx]]
			let [bflag, rflag, Wflag, cflag] = get(flagd, &l:ft, flagd[''])
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
			let [bflag, rflag, Wflag, cflag] = get(flagd, &l:ft, flagd[''])
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


