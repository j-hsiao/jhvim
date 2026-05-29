"Return [mapline, mapcmd, mapmode, nore, mapargs, lhs, rhs; ignored]
"0. mapline: the entire map command line
"1. mapcmd: the map ex command (ex: inoremap)
"2. mapmode: the map prefix letter ('i' if 'imap', blank if 'map')
"3. nore: 'nore' if nore was in the mapcmd
"4. mapargs: blankspace delimited <arg>, see :h map-arguments
"5. lhs: the lhs of the map command
"6. rhs: the rhs of the map command
"7. ignored, this parsing uses matchlist() which always has 10 args on success.
"
"Optional arguments: start, count (see `:h matchlist()`)
"Empty list if no match.
function jhv#parse#Mapping(commandline, ...)
	let start = get(a:000, 0, 0)
	let cnt = get(a:000, 1, 1)
	return matchlist(
		\ a:commandline,
		\ '\m^\(\([nvxsoilct]\)\?\(nore\)\?map\)[[:blank:]]*\(\%([[:blank:]]*<\%(buffer\|nowait\|silent\|special\|script\|expr\|unique\)>\)*\)[[:blank:]]\+\(\%(\\[[:blank:]]\|[^[:blank:]]\)*\)[[:blank:]]\+\(.\+\)',
		\ start, cnt)
endfunction

"Split arguments on unescaped blanks and extract name=value args.
"Return [args, idx] where args is a list of [name, value] pairs
"and idx is the index of the first argument not matching name=value.
"Additionally, any token matching '<SNR>[0-9]\+_' will be treated as
"a name=value pair with name as 'SID'
"optional arguments:
"	idx=0, starting index to start parsing name=value args.
"	json=v:true: bool, decode the value as json if possible.
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
