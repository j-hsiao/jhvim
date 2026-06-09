function jhv#parse#Mapping(commandline, ...)
	let start = get(a:000, 0, 0)
	let cnt = get(a:000, 1, 1)
	return matchlist(
		\ a:commandline,
		\ '\m^\(\([nvxsoilct]\)\?\(nore\)\?map\)[[:blank:]]*\(\%([[:blank:]]*<\%(buffer\|nowait\|silent\|special\|script\|expr\|unique\)>\)*\)[[:blank:]]\+\(\%(\\[[:blank:]]\|[^[:blank:]]\)*\)[[:blank:]]\+\(.\+\)',
		\ start, cnt)
endfunction

function jhv#parse#PreArgs(str, ...)
	let idx = get(a:000, 0, 0)
	let json = get(a:000, 1, 1)
	let settings = []
	while idx < len(a:str)
		let settingmatch = matchlist(a:str, '\m^[[:blank:]]*\([a-zA-Z_][a-zA-Z0-9_]*\)=\(\%(\\.\|[^[:blank:]]\)*\)\%([[:blank:]]\+\|$\)', idx)
		if empty(settingmatch)
			let settingmatch = matchlist(a:str, '\m^[[:blank:]]*\(<SNR>[0-9]\+_\)\%([[:blank:]]\+\|$\)', idx)
			if empty(settingmatch)
				break
			else
				call add(settings, ['SID', settingmatch[1]])
				let idx += len(settingmatch[0])
			endif
		else
			let value = substitute(settingmatch[2], '\m\\\(.\)', '\1', 'g')
			if json
				try
					let value = json_decode(value)
				catch
				endtry
			endif
			call add(settings, [settingmatch[1], value])
			let idx += len(settingmatch[0])
		endif
	endwhile
	return [settings, idx]
endfunction

function jhv#parse#Settings(settings, ...)
	let remainder = []
	if type(a:settings) == v:t_list
		let ret = {}
		let valid = a:settings
	else
		let ret = a:settings
		let valid = []
	endif
	for substr in a:000
		if type(substr) == v:t_list
			call extend(valid, substr)
		elseif type(substr) == v:t_dict
			call extend(ret, substr)
		elseif type(substr) == v:t_string
			if !empty(remainder)
				call add(remainder, substr)
				continue
			endif
			let idx = 0
			while idx < len(substr)
				let settingmatch = matchlist(substr, '\m^[[:blank:]]*\([a-zA-Z_][a-zA-Z0-9_]*\)=\(\%(\\.\|[^[:blank:]]\)*\)\%([[:blank:]]\+\|$\)', idx)
				if empty(settingmatch)
					let settingmatch = matchlist(substr, '\m^[[:blank:]]*\(<SNR>[0-9]\+_\)\%([[:blank:]]\+\|$\)', idx)
					if empty(settingmatch)
						call add(remainder, substr[idx:])
						break
					else
						let settingmatch = [settingmatch[0], 'SID', settingmatch[1]]
					endif
				endif
				if empty(valid) || has_key(ret, settingmatch[1]) || index(valid, settingmatch[1]) >= 0
					let value = substitute(settingmatch[2], '\m\\\(.\)', '\1', 'g')
					try
						let value = json_decode(value)
					catch
					endtry
					let ret[settingmatch[1]] = value
					let idx += len(settingmatch[0])
				else
					call add(remainder, substr[idx:])
					break
				endif
			endwhile
		else
			throw printf('Unexpected argument type: %s', substr)
		endif
	endfor
	return [ret, join(remainder, ' ')]
endfunction

"summary:
"h: format-comments
"comment types:
"1. beginning of each line
"2. first line only (like markdown list)
"3. 3-part comment (beg, med, end)
"
"format:
"flags:string,flags:string,...
"
"flags:
"n  nesting is allowed
"b  blank is required after string
"f  only first line has string. (like bullet, so this isn't actually a comment...)
"s  start of 3-piece
"m  middle of 3-piece
"e  end of 3-piece
"l  start and end are left-aligned
"r  right-aligned
"O  Don't consider this for O command (don't think these ones are actually
"   comments either...)
"x  short cut end 3-piece comment with last char of end after
"   auto-middle-insertion.
"[-]{digits}

function! jhv#parse#ParseComments(...)
	"comments and commentstring are unlikely to change while in the
	"same buffer, so try cache result
	let comparts = split(a:0 ? a:1 : &l:comments, ',')
	let pattern = ''
	let idx = 0
	let single = []
	let multi = []
	let parsepat = '\m\(\%([nbsmelrxfO]\|-\?[0-9]\+\)*\):\(.*\)'
	while idx < len(comparts)
		let [whole, flags, comment; ignored] = matchlist(comparts[idx], parsepat)
		if match(flags, 's') >= 0
			let [whole, mflags, mcomment; ignored] = matchlist(comparts[idx+1], parsepat)
			let [whole, eflags, ecomment; ignored] = matchlist(comparts[idx+2], parsepat)
			call add(multi, [flags, comment, mflags, mcomment, eflags, ecomment])
			let idx += 3
		else
			call add(single, [flags, comment])
			let idx += 1
		endif
	endwhile
	return [single, multi]
endfunction

function! jhv#parse#SingleCommentRegex(parsed)
	let [flags, comment] = a:parsed
	if match(flags, 'b') >= 0
		let spaced = '\+'
	else
		let spaced = '*'
	endif
	return printf(
		\ '\m^\([[:blank:]]*\)\V\(%s\)\m\([[:blank:]]%s\)\(.*\)$',
		\ escape(comment, '\/'),
		\ spaced
	\ )
endfunction

function! jhv#parse#MultiCommentRegex(parsed)
	let [sflag, scom, mflag, mcom, eflag, ecom] = a:parsed
	let ret = [
		\ jhv#parse#SingleCommentRegex([sflag, scom]),
		\ jhv#parse#SingleCommentRegex([mflag, mcom]),
		\ jhv#parse#SingleCommentRegex([eflag, ecom])
	\ ]

	let [startreg, midreg, endreg] = ret

	let startreg = substitute(startreg, '\m\\(', '\\%(', 'g')
	let startreg = substitute(startreg, '\m\$$', '', '')
	let startreg = substitute(startreg, '\m^\%(\\m\)\?\^', '', '')


	let midreg = substitute(midreg, '\m\\(', '\\%(', 'g')
	let midreg = substitute(midreg, '\m\$$', '', '')
	let midreg = substitute(midreg, '\m^\(\\m\)\?\^', '\1\\_$\\_.\\_^', '')

	let endreg = substitute(endreg, '\m\\(', '\\%(', 'g')
	let endreg = substitute(endreg, '\m^\%(\\m\)\?\^', '\\%(\\_$\\_.\\_^\\)\\?', '')

	call add(ret, printf('\m^\(%s\)\(\%%(%s\)*\)\(%s\)', startreg, midreg, endreg))
	return ret
endfunction
