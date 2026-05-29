function s:ExtendName(name, mode)
	let pattern = printf('<Plug>ExtendMap:%s:%%d:%s;', a:mode, a:name)
	let i = 0
	while !empty(maparg(printf(pattern, i), a:mode))
		let i += 1
	endwhile
	return printf(pattern, i)
endfunction

function jhv#extendmap#ExtendMap(...)
	if match(&cpo, '.*<.*') >= 0
		set cpo-=<
		try
			return call('jhv#extendmap#ExtendMap', a:000)
		finally
			set cpo+=<
		endtry
	endif
	let settingnames = ['before', 'name', 'SID', 'verbose']
	let [settings, mapcmd] = call('jhv#parse#Settings', extend([settingnames], a:000))
	let before = get(settings, 'before', v:false)
	let name = get(settings, 'name', '')
	let SID = get(settings, 'SID', '<SID>')
	let verbose = get(settings, 'verbose', v:false)

	let mapmatch = jhv#parse#Mapping(substitute(mapcmd, '<SID>', SID, 'g'))
	if empty(mapmatch)
		throw printf('Invalid map command: %s', join(mapcmd, ' '))
	endif
	let [mapline, mapcmd, mapmode, mapnore, mapargs, lhs, rhs; ignored] = mapmatch
	if empty(name)
		let name = lhs
	endif
	if verbose
		for [name, value] in items(settings)
			echom printf('%s: %s', name, value)
		endfor
	endif

	let mapdict = maparg(lhs, mapmode, v:false, v:true)
	let plugname = s:ExtendName(name, mapmode)
	if verbose
		echom printf('Extend map with intermediate lhs %s', plugname)
	endif
	execute printf('%s%smap %s %s %s', mapmode, mapnore, mapargs, plugname, rhs)
	if empty(mapdict)
		execute printf('%smap %s %s', mapmode, lhs, plugname)
	elseif mapdict['noremap']
		let oname = s:ExtendName(name, mapmode)
		if verbose
			echom printf('Original map to intermediate lhs %s', oname)
		endif
		let mapdict['lhs'] = oname
		let mapdict['lhsraw'] = substitute(oname, '<Plug>', "\<Plug>", 'g')
		call mapset(mapdict['mode'], v:false, mapdict)
		if before
			execute printf('%smap %s %s%s', mapmode, lhs, plugname, oname)
		else
			execute printf('%smap %s %s%s', mapmode, lhs, oname, plugname)
		endif
	else
		if mapdict['expr']
			let sep = ' . '
			let plugname = printf('"%s"',
				\ substitute(substitute(escape(plugname, '<"\'), '<', '<lt>'), '\', '<Bslash>'))
		else
			let sep = ''
		endif
		if before
			let mapdict['rhs'] = printf('%s%s%s', plugname, sep, mapdict['rhs'])
		else
			let mapdict['rhs'] = printf('%s%s%s', mapdict['rhs'], sep, plugname)
		endif
		call mapset(mapdict['mode'], v:false, mapdict)
	endif
endfunction
