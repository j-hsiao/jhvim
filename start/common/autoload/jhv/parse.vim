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

"Parse arguments with lists, dicts, and strs.
"
"list: add valid setting names.  No given names implies all names are valid.
"dict: Add settings.  If the first item is a dict, it is updated directly.
"strs: parsed for values.  Once an argument not matching a valid name=value
"      is encountered, all remaining strs are concatenated and returned as
"      remainingstr
"
"Return [settings, remainingstr]
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
