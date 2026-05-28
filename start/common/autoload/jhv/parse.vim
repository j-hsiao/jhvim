"Return [mapline, mapcmd, mapmode, nore, mapargs, lhs, rhs; ignored]
"0. mapline: the entire map command line
"1. mapcmd: the map ex command (ex: inoremap)
"2. mapmode: the map prefix letter ('i' if 'imap', blank if 'map')
"3. nore: 'nore' if nore was in the mapcmd
"4. mapargs: blankspace delimited <arg>, see :h map-arguments
"5. lhs: the lhs of the map command
"6. rhs: the rhs of the map command
"7. ignored, this parsing uses matchlist() which always has 10 args on success.
function jhv#parse#Mapping(commandline, ...)
	if a:0
		let extra = a:000
		if len(extra) < 2
			call add(extra, 1)
		endif
	else
		let extra = [0,1]
	endif

	return matchlist(
		\ a:commandline,
		\ '\m^\(\([nvxsoilct]\)\?\(nore\)\?map\)[[:blank:]]*\(\%([[:blank:]]*<\%(buffer\|nowait\|silent\|special\|script\|expr\|unique\)>\)*\)[[:blank:]]\+\(\%(\\[[:blank:]]\|[^[:blank:]]\)*\)[[:blank:]]\+\(.\+\)',
		\ extra[0], extra[1])
endfunction
