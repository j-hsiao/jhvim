function jhv#extendmap#ExtendMap(...)
	if match(&cpo, '.*<.*') >= 0
		set cpo-=<
		try
			return call('jhv#repeatable#create', a:000)
		finally
			set cpo+=<
		endtry
	endif
	let settingnames = ['before', ]
	let before = v:false

endfunction
