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
	let [settings, mapcmd] = call(jhv#parse#Settings, extend([settingnames], a:000))
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
	if empty(mapdict)
		
	else
		let idx = 0
		let plugname = printf('<Plug>ExtendMap%d_%s;', idx, name)
		while !empty(maparg(plugname))
			let plugname = printf('<Plug>ExtendMap%d_%s;', idx, name)
		endwhile
		let mapdict['lhs'] = plugname
		mapset(mapdict)
	endif
endfunction
