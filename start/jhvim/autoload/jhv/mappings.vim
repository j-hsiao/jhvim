"Create bindings for repeatable functions.

" Used in front of the wait map to break left-recursiveness
" However, it cannot be evaluated into nothing or it will just skip
" the ambiguous-mapping step and nearly instantly hit the recursion limit.
if match("\<Ignore>", '<Ignore>') >= 0
	if match("\<Cmd>", '<Cmd>') < 0
		" :h map-table
		noremap <silent> <Plug>jhv_mappings_nop; <Cmd>exec ''<CR>
		lnoremap <silent> <Plug>jhv_mappings_nop; <Cmd>exec ''<CR>
		tnoremap <silent> <Plug>jhv_mappings_nop; <Cmd>exec ''<CR>
	else
		nnoremap <silent> <Plug>jhv_mappings_nop; :exec ''<CR>
		inoremap <silent> <Plug>jhv_mappings_nop; <C-R>=''<CR>
		vnoremap <silent> <Plug>jhv_mappings_nop; g<C-G>
		" Todo: the other modes?
	endif
	let s:noop = '<Bslash><lt>Plug>jhv_mappings_nop;'
else
	let s:noop = '<Bslash><lt>Ignore>'
endif

function s:Map2Estr(mpcmd, ...)
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

function s:Str2Map(mpstr)
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

"for debugging...
function jhv#mappings#Map2Estr(...)
	return call('s:Map2Estr', a:000)
endfunction
function jhv#mappings#Str2Map(...)
	return call('s:Str2Map', a:000)
endfunction

function s:Name(lhs)
	" Convert a keyseq to a name-like string
	return substitute(a:lhs, '\m[[:blank:]:;]', '_', 'g')
endfunction

let s:autonum = 0
function s:Actionmap(treename, keyname)
	" Generate an actionmap LHS.
	let s:autonum += 1
	return printf('<Plug>jhvaction:%s:%s:%d;', a:treename, a:keyname, s:autonum)
endfunction

function s:Treemap(treename)
	"Return the LHS for a keymap"
	if empty(a:tree)
		return ''
	else
		return printf('<Plug>jhvtree:%s;', a:treename)
	endif
endfunction

function s:MakeTree(treemap, mode)
	" Create the base keymap for the tree.
	if empty(a:treemap)
		return ''
	endif
	if len(maparg(treemap, a:mode))
		return ''
	endif
	return printf(
		\ '%smap <special> <silent> <expr> %s getchar(1) ? "" : "%s%s"',
		\ a:mode, treemap, s:noop, jhv#mappings#Str2Map(jhv#mappings#Map2Estr(treemap, 0)))
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

function s:NormalizeKeymap(treename, mode, lhs, keep)
	"Return [lhs, rhs, target] for a normalized keymap.
	"If keep, then keep the action even if there is no mapping.
	let treemap = s:Treemap(a:treename)
	let lhs = treemap . a:lhs
	let mdict = maparg(lhs, a:mode, 0, 1)
	if empty(mdict)
		if a:keep
			let action = s:Actionmap(a:treename, s:Name(a:lhs))
			exec printf('%snoremap <special> %s %s', a:mode, action, a:lhs)
			return [lhs, action, treemap]
		else
			return [lhs, '', treemap]
		endif
	else
		let parsed = matchlist(mdict['rhs'], '\m^\(\%(<Plug>jhvaction:[^:;]*:[^:;]*:[^:;]*;\)*\)\(<Plug>jhvtree:[^:;]*;\)\?$' )
		if empty(parsed)
			let action = s:Actionmap(a:treename, s:Name(a:lhs))
			jhv#mappings#CopyMap(a:mode, lhs, action, mdict)
			return [lhs, action, treemap]
		else
			let [whole, actions, rep; ignored] = parsed
			return [lhs, actions, rep]
		endif
	endif
endfunction

function jhv#mappings#Tmap(...)
	let settingnames = [
		\ 'tree', '', 'enter', 'target', 'SID', 'verbose', 'keep', 'add']

	let [settings, mapcmd] = call('jhv#parse#Settings', extend([settingnames], a:000))
	let tree = get(settings, 'tree', get(settings, '', ''))
	let treename = s:Name(tree)
	if get(settings, 'verbose', v:false)
		echom printf('Managing tree "%s"', tree)
		for [item, value] in items(settings)
			echom printf('%s: %s', item, value)
		endfor
	endif

	let mapmatch = jhv#parse#Mapping(substitute(
		\ mapcmd, '<SID>', get(settings, 'SID', '<SID>'), 'g'))
	if empty(mapmatch)
		throw printf('Invalid map command: %s', mapcmd)
	endif
	let [mapline, mapcmd, mapmode, mapnore, mapargs, lhs, rhs; ignored] = mapmatch
	if match(rhs, '\m[[:blank:]]\(s:\|<SID>\)[a-zA-Z0-9_]') >= 0
		echohl WarningMsg | echom 'WARNING: Tmap <SID> was not replaced' | echohl None
	endif
	let maps = []
	let treemap = s:Treemap(treename)
	let keyname = s:Name(lhs)
	call add(maps, s:MakeTree(treemap, mapmode))
	if empty(rhs) || rhs == '<Nop>'
		let action = ''
	else
		let action = s:Actionmap(treename, keyname)
		call add(maps, printf('%s <special> %s %s %s', mapcmd, mapargs, action, rhs))
	endif
	let [keymap, keyactions, keytarget] = s:NormalizeKeymap(
		\ treename, mapmode, lhs, get(settings, 'keep', v:false))
	if has_key(settings, 'target')
		let target = settings['target']
		if empty(target)
			let target = keytarget
		else
			let target = s:Treemap(s:Name(target))
		endif
	else
		let target = ''
	endif
	let add = get(settings, 'add', '=')
	if add == '='
		call add(maps, printf('%smap <special> %s%s %s%s', mapmode, treemap, lhs, action, target))
	elseif add == '<'
		call add(maps, printf('%smap <special> %s%s %s%s%s', mapmode, treemap, lhs, action, keyactions, target))
	else
		call add(maps, printf('%smap <special> %s%s %s%s%s', mapmode, treemap, lhs, keyactions, action, target))
	endif

	let enter = get(settings, 'enter', ' ')
	if !empty(enter)
		let [whole, ecmd, elhs, erhs; ignored] = matchlist(text, '\m^\([^[:space:]]\?\%(nore\)\?map\)\?[[:blank:]]\?\([^[:blank:]]*\)[[:blank:]]*\(.*\)$')
		if empty(ecmd)
			let ecmd = mapcmd
		endif
		if empty(elhs)
			let elhs = lhs
		endif
		let [whole, emode, enore; ignored] = matchlist(ecmd, '\m^\([^[:space:]]\)\?\(nore\)\?map')
		if empty(erhs)
			let eaction = ''
		else
			let eaction = s:Actionmap(treename, keyname)
			call add(maps, printf('%s <special> %s %s%s', ecmd, elhs, erhs))
		endif
		call add(maps, printf('%smap <special> %s %s%s%s', emode, elhs, eaction, treemap, lhs))
	endif

	let verbose = get(settings, 'verbose', v:false)
	for item in maps
		if len(maps)
			if verbose
				echom printf('Creating map: %s', item)
			endif
			exec item
		endif
	endfor
endfunction


function s:Autoname(pat)
	" TODO remove this
	let s:autonum += 1
	return printf(a:pat, s:autonum)
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
		for k in settingnames
			echom printf('%10s = "%s"', k, get(l:, k))
		endfor
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
		\ '%smap <silent> <special> <expr> %s getchar(1) ? "" : ("%s%s")',
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
