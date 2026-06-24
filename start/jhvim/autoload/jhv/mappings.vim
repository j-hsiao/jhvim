"Create bindings for repeatable functions.

" Used in front of the wait map to break left-recursiveness
" However, it cannot be evaluated into nothing or it will just skip
" the ambiguous-mapping step and nearly instantly hit the recursion limit.
if match("\<Ignore>", '<Ignore>') >= 0
	if match("\<Cmd>", '<Cmd>') < 0
		" :h map-table
		noremap <silent> <Plug>repeatable_nop; <Cmd>exec ''<CR>
		lnoremap <silent> <Plug>repeatable_nop; <Cmd>exec ''<CR>
		tnoremap <silent> <Plug>repeatable_nop; <Cmd>exec ''<CR>
	else
		nnoremap <silent> <Plug>repeatable_nop; :exec ''<CR>
		inoremap <silent> <Plug>repeatable_nop; <C-R>=''<CR>
		vnoremap <silent> <Plug>repeatable_nop; g<C-G>
		" Todo: the other modes?
	endif
	let s:noop = '"<Bslash><lt>Plug>repeatable_nop;"'
else
	let s:noop = '"<Bslash><lt>Ignore>"'
endif

function jhv#mappings#Map2Estr(mpcmd, ...)
	if a:0
		let quoteit = a:1
	else
		let quoteit = 1
	endif
	" from :h key-notation
	let subs = [
		\ '<Nul>', '<BS>', '<Tab>', '<NL>', '<CR>', '<Return>', '<Enter>',
		\ '<Esc>', '<Space>', '<lt>', '<Bslash>', '<Bar>', '<Del>', '<CSI>',
		\ '<xCSI>', '<EOL>', '<Up>', '<Down>', '<Left>', '<Right>', '<S-Up>',
		\ '<S-Down>', '<S-Left>', '<S-Right>', '<C-Left>', '<C-Right>',
		\ '<\%(S-\)\?F[1-9][0-2]\?>', '<Help>', '<Undo>', '<Insert>', '<Home>',
		\ '<End>', '<PageUp>', '<PageDown>', '<kHome>', '<kEnd>', '<kPageUp>',
		\ '<kPageDown>', '<kPlus>', '<kMinus>', '<kMultiply>', '<kDivide>',
		\ '<kEnter>', '<kPoint>', '<k[0-9]>', '<S-[^>]\+>', '<C-[^>]\+>', '<M-[^>]\+>',
		\ '<A-[^>]\+>', '<D-[^>]\+>', '<t_[^>]\+>', '<Plug>', '<Cmd>', '<Ignore>'
	\ ]
	let ret = substitute(escape(a:mpcmd, '\"'), printf('\m\(%s\)', join(subs, '\|')), '\\\1', 'g')
	if quoteit
		return printf('"%s"', ret)
	endif
	return ret
endfunction

function jhv#mappings#Str2Map(mpstr)
	let ret = a:mpstr
	for [seq, replace] in [
		\ ['<', '<lt>'],
		\ ['\', '<Bslash>'],
		\ ["\r", '<CR>'],
		\ [' ', '<Space>'],
		\ ["\t", '<Tab>'],
		\ ['|', '<Bar>']
	\ ]
		let ret = substitute(ret, seq, replace, 'g')
	endfor
	return ret
endfunction

let s:autonum = 0
function s:Autoname(pat)
	let ret = printf(a:pat, s:autonum)
	let s:autonum += 1
	return ret
endfunction

function jhv#mappings#Tmap(tree, ...)
	let settingnames = [
		\ 'name', 'enter', 'emode', 'stop', 'exit', 'SID', 'verbose',
		\ 'pre', 'post', 'rpre', 'rpost', 'erhs']
	if a:0
		let [settings, mapcmd] = call('jhv#parse#Settings', extend([settingnames], a:000))
		let tree = a:tree
	else
		let [ignore, tree, mp; ignore] = matchlist(a:tree, '\m^\([^[:blank:]]*\)[[:blank:]]*\(.*\)')
		let [settings, mapcmd] = call('jhv#parse#Settings', extend([settingnames], [mp]))
	endif

	let mapmatch = jhv#parse#Mapping(substitute(
		\ mapcmd, '<SID>', get(settings, 'SID', '<SID>'), 'g'))
	if empty(mapmatch)
		throw printf('Invalid map command: %s', mapcmd)
	endif
	let [mapline, mapcmd, mapmode, mapnore, mapargs, lhs, rhs; ignored] = mapmatch

	let treename = printf('<Plug>Tmap:%s;', tree)
	let maps = []
	if maparg(treename, mapmode) == ''
		call add(maps, printf(
			\ '%smap <silent> <special> <expr> %s getchar(1) ? "" : (%s . %s)',
			\ mapmode, treename, s:noop, jhv#mappings#Str2Map(jhv#mappings#Map2Estr(treename))))

	endif
	if !empty(get(settings, 'exit', ''))
		call add(maps, printf('%smap <silent> <special> <expr> %s%s ""',
			\ mapmode, treename, get(settings, 'exit')))
	endif
	let name = get(settings, 'name', '')
	if empty(name)
		let name = s:Autoname('TmapAction%d')
	endif
	let name = printf('<Plug>Tmap_do:%s:%s;', tree, name)
	call add(maps, printf('%s %s %s %s', mapcmd, mapargs, name, rhs))
	let enter = get(settings, 'enter', v:true)
	if !empty(enter)
		let pre = get(settings, 'pre', '')
		let rpre = get(settings, 'rpre', '')
		let post = get(settings, 'post', '')
		let rpost = get(settings, 'rpost', '')
		let erhs = get(settings, 'erhs', '')
		if type(enter) != v:t_string
			let enter = lhs
		endif
		let emode = get(settings, 'emode', mapmode)
		if empty(erhs)
			if !empty(rpre) || !empty(rpost)
				let epat = printf(
					\ '\m^\V%s\m\(.*\)\V%s\m$', escape(rpre, '\/'), escape(rpost, '\/'))
				let erhs = matchlist(rhs, epat)[1]
			endif
			if !empty(pre) || !empty(post)
				if empty(rhs)
					let rhs = name
				endif
				let erhs = printf('%s%s%s', pre, erhs, post)
			endif
		endif
		if empty(erhs)
			let erhs = name . treename
		else
			let ename = substitute(name, 'Tmap_do', 'Tmap_enter', '')
			call add(maps, printf('%smap %s %s %s', emode, mapargs, ename, erhs))
			let erhs = ename . treename
		endif
		let emode = emode[:0]
		call add(maps, printf('%smap <special> %s %s', emode, enter, erhs))
	endif
	call add(maps, printf('%smap <special> %s%s %s%s', mapmode, treename, lhs,
	                      \ name, get(settings, 'stop', v:false) ? '' : treename))
	let verbose = get(settings, 'verbose', v:false)
	for item in maps
		if verbose
			echom printf('Creating map: %s', item)
		endif
		exec item
	endfor
endfunction


function jhv#mappings#Repeatable(...)
	let settingnames = ['makemap', 'mode', 'name', 'repeat', 'transition', 'verbose', 'SID']
	let [settings, mapcmd] = call('jhv#parse#Settings', extend([settingnames], a:000))
	let makemap = get(settings, 'makemap', 1)
	let mode = get(settings, 'mode', '')
	let name = get(settings, 'name', '')
	let repeat = get(settings, 'repeat', '.')
	let transition = get(settings, 'transition', '')
	let verbose = get(settings, 'verbose', v:false)
	let SID = get(settings, 'SID', '<SID>')

	let mapmatch = jhv#parse#Mapping(substitute(mapcmd, '<SID>', SID, 'g'))
	if empty(mapmatch)
		throw printf('Invalid map command: %s', mapcmd)
	endif
	let [mapline, mapcmd, mapmode, mapnore, mapargs, lhs, rhs; ignored] = mapmatch
	if verbose
		for k in split('makemap mode name repeat transition verbose SID')
			echom printf('%10s = "%s"', k, get(l:, k))
		endfor
	endif
	if verbose
		for k in split('mapline mapcmd mapmode mapargs lhs rhs')
			echom printf('%7s: "%s"', k, get(l:, k))
		endfor
	endif

	if makemap && match(rhs, '\m[[:blank:]]\(s:\|<SID>\)[a-zA-Z0-9_]') >= 0
		echohl WarningMsg | echom 'WARNING: rhs contains <SID> or s:but makemap is true.' | echohl None
	endif
	if empty(mode)
		let mode = mapmode
	endif
	if empty(name)
		let name = lhs
	endif
	let mapname = printf('<Plug>repeatable_map:%s:%s;', mapmode, name)
	let waitname = printf('<Plug>repeatable_wait:%s:%s;', mapmode, name)

	let lhmap = printf(
		\ '%smap <special> <silent> %s %s%s', mapmode, lhs, mapname, waitname)
	if match(mapargs, '<special>') < 0
		let mapargs .= ' <special>'
	endif
	let rhmap = printf('%s %s %s %s', mapcmd, mapargs, mapname, rhs)
	" Note, in old impl within Notes repo, I seem to have made some
	" kind of observation where detecting keypress, NOT consuming next
	" keypress, and returning empty string led to the next keypresses
	" NOT being mapped to any mappings.  However, I cannot seem to
	" reproduce this behavior.
	let wtmap = printf(
		\ '%smap <silent> <special> <expr> %s getchar(1) == 0 ? (%s . "%s") : ""',
		\ mode, waitname, s:noop, jhv#mappings#Str2Map(jhv#mappings#Map2Estr(waitname, 0)))
	if empty(transition)
		if mode != mapmode
			if mode == 'n'
				if mapmode == 'i'
					let transition = 'a'
				elseif mapmode == 'v'
					let transition = '`<lt>v`>'
				endif
			elseif mapmode == 'n'
				let transition = '<C-\><C-N>'
			endif
		endif
	endif

	let rpmap = printf(
		\ '%smap <special> <silent> %s%s %s%s',
		\ mode, waitname, repeat, transition, lhs)
	if verbose
		echom 'lhmap: ' . lhmap
		echom 'rhmap: ' . rhmap
		echom 'wtmap: ' . wtmap
		echom 'rpmap: ' . rpmap
	endif

	exec lhmap
	exec wtmap
	exec rpmap
	if makemap
		exec rhmap
		return ''
	else
		return rhmap
	endif
endfunction

function s:ExtendName(name, mode)
	return s:Autoname(printf('<Plug>ExtendMap:%s:%s:<Plug>%%d;', a:mode, a:name))
endfunction

function s:MapSet(dct)
	" NOTE It seems like nmap ...
	" to search for mappings uses the 'lhsraw' entry to the dict.
	" However, if I just use "\<C-K>" as the lhsraw, then nmap will not find
	" that mapping.  Only if lhsraw is "\x80\xfc\<C-D>K" can it be found.
	" But how to calculate lhsraw? Removing lhsraw and calling mapset does not
	" recalculate the value of lhsraw.  It just errors out saying missing
	" entries.
	" Searching, apparently ?maybe? newer vim versions have a keytrans() and
	" keycode() that could be used to convert '<...>' to the ?appropriate?
	" lhsraw, but not sure...
	" Probably prefer to have a proper lhsraw over the correct 'sid'
	" since the 'sid' can be replaced anyways but *incorrect* lhsraw means
	" that the mapping cannot be properly searched for with the *map commands.
	" 8.2 has neither.
	" 9.1 seems to have a keytrans() (lhsraw to lhs) but no keycode()
	if exists('*keycode') && exists('*mapset')
		let a:dct['lhsraw'] = keycode(a:dct['lhs'])
		call mapset(a:dct['mode'], v:false, a:dct)
	else
		let mpcmd = [printf('%s%smap', a:dct['mode'], (a:dct['noremap'] ? 'nore' : ''))]
		for mapargu in ['buffer', 'nowait', 'silent', 'script', 'expr']
			if get(a:dct, mapargu, v:false)
				call add(mpcmd, printf('<%s>', mapargu))
			endif
		endfor
		call add(mpcmd, a:dct['lhs'])
		call add(mpcmd, substitute(a:dct['rhs'], '<SID>', printf('<SNR>%s_', a:dct['sid']), 'g'))
		execute join(mpcmd, ' ')
	endif
endfunction

function jhv#mappings#CopyMap(mode, lhs, newlhs, ...)
	let dct = a:0 > 0 ? a:1 : maparg(a:lhs, a:mode, v:false, v:true)
	if empty(dct)
		execute printf('%snoremap %s %s', a:mode, a:newlhs, a:lhs)
	else
		let dct['lhs'] = a:newlhs
		let dct['lhsraw'] = eval(jhv#mappings#Map2Estr(a:newlhs))
		call s:MapSet(dct)
	endif
endfunction

function jhv#mappings#ExtendMap(...)
	let settingnames = ['before', 'keep', 'name', 'SID', 'verbose', 'rep']
	let [settings, mapcmd] = call('jhv#parse#Settings', extend([settingnames], a:000))
	let before = get(settings, 'before', v:false)
	let keep = get(settings, 'keep', v:false)
	let name = get(settings, 'name', '')
	let SID = get(settings, 'SID', '<SID>')
	let verbose = get(settings, 'verbose', v:false)
	let rep = get(settings, 'rep', v:true)

	let mapmatch = jhv#parse#Mapping(substitute(mapcmd, '<SID>', SID, 'g'))
	if empty(mapmatch)
		throw printf('Invalid map command: %s', mapcmd)
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
	if rep && !empty(mapdict)
		let repmatch = matchlist(
			\ mapdict['rhs'],
			\ '\m^<Plug>repeatable_map:\([a-z]\?:.*\);<Plug>repeatable_wait:\1;$')
		if !empty(repmatch)
			if verbose
				echom printf('Extending repetable map: changing lhs from %s to <Plug>repeatable_map:%s;', lhs, repmatch[1])
			endif
			let lhs = printf('<Plug>repeatable_map:%s;', repmatch[1])
			let mapdict = maparg(lhs, mapmode, v:false, v:true)
		endif
	endif
	let plugname = s:ExtendName(name, mapmode)
	if verbose
		echom printf('Extend map with intermediate lhs %s', plugname)
	endif
	execute printf('%s%smap %s %s %s', mapmode, mapnore, mapargs, plugname, rhs)
	if empty(mapdict)
		if keep
			let oname = s:ExtendName(name, mapmode)
			execute printf('%snoremap <special> %s %s', mapmode, oname, lhs)
			if before
				execute printf('%smap <special> %s %s%s', mapmode, lhs, plugname, oname)
			else
				execute printf('%smap <special> %s %s%s', mapmode, lhs, oname, plugname)
			endif
		else
			execute printf('%smap <special> %s %s', mapmode, lhs, plugname)
		endif
	elseif mapdict['noremap']
		let oname = s:ExtendName(name, mapmode)
		if verbose
			echom printf('Original map to intermediate lhs %s', oname)
		endif
		call jhv#mappings#CopyMap(mapmode, lhs, oname, mapdict)
		if before
			execute printf('%smap <special> %s %s%s', mapmode, lhs, plugname, oname)
		else
			execute printf('%smap <special> %s %s%s', mapmode, lhs, oname, plugname)
		endif
	else
		if mapdict['expr']
			let sep = ' . '
			let plugname = jhv#mappings#Str2Map(jhv#mappings#Map2Estr(plugname))
		else
			let sep = ''
		endif
		if before
			let mapdict['rhs'] = printf('%s%s%s', plugname, sep, mapdict['rhs'])
		else
			let mapdict['rhs'] = printf('%s%s%s', mapdict['rhs'], sep, plugname)
		endif
		call s:MapSet(mapdict)
	endif
endfunction
