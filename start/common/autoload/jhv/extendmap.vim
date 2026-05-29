function s:ExtendName(base, mode)
	let pattern = printf('<Plug>ExtendMap%s_%%d_%s;', a:mode, a:base)
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
	else
		let [mapline, mapcmd, mapmode, mapnore, mapargs, lhs, rhs; ignored] = mapmatch
	endif
	let mapdict = maparg(lhs, mapmode, v:false, v:true)
	let plugname = s:ExtendName(name, mapmode)
	execute printf('%s%smap %s %s %s', mapmode, mapnore, mapargs, plugname, rhs)
	if empty(mapdict)
		execute printf('%smap %s %s', mapmode, lhs, plugname)
	elseif mapdict['noremap']
		let oname = s:ExtendName(name, mapmode)
		let mapdict['lhs'] = oname
		mapset(mapdict)
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
