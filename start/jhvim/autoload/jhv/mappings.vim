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

" Convert a string as would be typed in a vim script specifying an map
" command into an appropriate string that could be eval()ed inside
" double quotes.
" from :h key-notation
let s:keynotation = printf('\m\(\\\|"\|<\%%(%s\)>\)',
	\ join([
		\ 'Nul', 'BS', 'Tab', 'NL', 'CR', 'Return', 'Enter',
		\ 'Esc', 'Space', 'lt', 'Bslash', 'Bar', 'Del', 'CSI',
		\ 'xCSI', 'EOL', 'Up', 'Down', 'Left', 'Right', 'S-Up',
		\ 'S-Down', 'S-Left', 'S-Right', 'C-Left', 'C-Right',
		\ '\%(S-\)\?F[1-9][0-2]\?', 'Help', 'Undo', 'Insert', 'Home',
		\ 'End', 'PageUp', 'PageDown', 'kHome', 'kEnd', 'kPageUp',
		\ 'kPageDown', 'kPlus', 'kMinus', 'kMultiply', 'kDivide',
		\ 'kEnter', 'kPoint', 'k[0-9]', 'S-[^>]\+', 'C-[^>]\+', 'M-[^>]\+',
		\ 'A-[^>]\+', 'D-[^>]\+', 't_[^>]\+', 'Plug', 'Cmd', 'Ignore'
	\], '\|'))
function s:AsEval(mpcmd, ...)
	let ret = substitute(a:mpcmd, s:keynotation, '\\\1', 'g')
	if !a:0 || a:1
		return printf('"%s"', ret)
	endif
	return ret
endfunction

"Convert some literal characters into <> notation.
function s:AsKeyNotation(mpstr)
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
function jhv#mappings#AsEval(...)
	return call('s:AsEval', a:000)
endfunction
function jhv#mappings#AsKeyNotation(...)
	return call('s:AsKeyNotation', a:000)
endfunction

function s:Name(lhs)
	" Convert a keyseq to a name-like string
	return substitute(a:lhs, '\m[[:blank:]:;\\]', '_', 'g')
endfunction

let s:autonum = 0
function s:Action(treename, actionname, ...)
	" Generate an actionmap LHS.
	if a:0 && a:1
		let s:autonum += 1
		return printf('<Plug>jhvaction:%s:%s:%d;', a:treename, a:actionname, s:autonum)
	else
		return printf('<Plug>jhvaction:%s:%s;', a:treename, a:actionname)
	endif
endfunction
function jhv#mappings#Action(tree, action)
	return s:Action(s:Name(a:tree), s:Name(a:action))
endfunction

function s:TreeLHS(treename)
	"Return the base tree map LHS
	if empty(a:treename)
		return ''
	else
		return printf('<Plug>jhvtree:%s;', a:treename)
	endif
endfunction

function s:MakeTree(lhs, mode)
	" Create the an exec string to create a base tree map.
	" It should repeatedly call itself until a key is pressed.
	if empty(a:lhs) || len(maparg(a:lhs, a:mode))
		return ''
	endif
	return printf(
		\ '%smap <special> <silent> <expr> %s getchar(1) ? "" : "%s%s"',
		\ a:mode, a:lhs, s:noop, s:AsKeyNotation(s:AsEval(a:lhs, 0)))
endfunction

function s:MapSet(dct)
	" Set a mapping from a dict (like from maparg(...))
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
		call s:MapSet(dct)
	endif
endfunction

function s:NormalizeKeymap(treename, mode, lhs, keep)
	"Return [lhs, actions, rep] for a normalized key mapping.
	"Create an action map if necessary for the keymap to be normalized.
	let treemap = s:TreeLHS(a:treename)
	let lhs = treemap . a:lhs
	let mdict = maparg(lhs, a:mode, 0, 1)
	if empty(mdict)
		if a:keep
			let action = s:Action(a:treename, s:Name('raw_' . a:lhs), 1)
			exec printf('%snoremap <special> %s %s', a:mode, action, a:lhs)
			return [lhs, action, treemap]
		else
			return [lhs, '', treemap]
		endif
	else
		let parsed = matchlist(mdict['rhs'], '\m^\(\%(<Plug>jhvaction:[^:;]*:[^:;]*:[^:;]*;\)*\)\(<Plug>jhvtree:[^:;]*;\)\?$' )
		if empty(parsed)
			let action = s:Action(a:treename, s:Name('pre_' . a:lhs), 1)
			jhv#mappings#CopyMap(a:mode, lhs, action, mdict)
			return [lhs, action, treemap]
		else
			let [whole, actions, rep; ignored] = parsed
			return [lhs, actions, rep]
		endif
	endif
endfunction


let s:entrypat = join([
	\ '\m^',
	\ '\%(\([^[:blank:]]\?\%(nore\)\?map\)[[:blank:]]\?\)\?',
	\ '\([^[:blank:]]*\)',
	\ '\%([[:blank:]]\+\(.*\)\)\?$',
	\ ], '')
function jhv#mappings#TMap(...)
	let settingnames = [
		\ 'tree', '', 'enter', 'target', 'SID',
		\ 'verbose', 'keep', 'add', 'name'
	\ ]
	let [settings, mapcmd] = call('jhv#parse#Settings', extend([settingnames], a:000))
	if empty(settings)
		let rawtree = extend([settingnames], a:000)
		let rawtree[1] = substitute(rawtree[1], '\m^[[:space:]]*\(.*\)', 'tree=\1', '')
		let [settings, mapcmd] = call('jhv#parse#Settings', rawtree)
	endif

	let tree = get(settings, 'tree', get(settings, '', ''))
	let treename = s:Name(tree)
	let verbose = get(settings, 'verbose', v:false)
	if verbose
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
		echohl WarningMsg | echom 'WARNING: TMap <SID> was not replaced' | echohl None
	endif

	let maps = []
	let treemap = s:TreeLHS(treename)
	let actionname = s:Name(get(settings, 'name', lhs))
	"----------
	"action map
	"----------
	if empty(rhs) || rhs == '<Nop>'
		let action = ''
	elseif match(rhs, printf('\m^<Plug>jhvaction:\V%s\m:[^:;]*;$', treename)) >= 0
		let nactionname = substitute(rhs,  '\m^<Plug>jhvaction:[^:;]*:\([^:;]*\);$', '\1', '')
		if !empty(get(settings, 'name', '')) && nactionname != actionname
			echohl WarningMsg
				\ | echom 'WARNING: rhs is a single action.'
				\ | echohl None
		endif
		let action = rhs
		let actionname = nactionname
	else
		let action = s:Action(treename, actionname, !has_key(settings, 'name'))
		if empty(maparg(action, mapmode))
			call add(maps, printf('%s <special> %s %s %s', mapcmd, mapargs, action, rhs))
		else
			throw printf('Action name already taken: %s', actionname)
		endif
	endif
	"-------
	"key map
	"-------
	let [keymap, keyactions, keytarget] = s:NormalizeKeymap(
		\ treename, mapmode, lhs, get(settings, 'keep', v:false))
	if has_key(settings, 'target')
		let target = s:TreeLHS(s:Name(settings['target']))
	else
		let target = keytarget
	endif
	"--------
	"tree map
	"--------
	if target == treemap
		call add(maps, s:MakeTree(treemap, mapmode))
	endif
	let add = get(settings, 'add', '=')
	if add == '>'
		call add(maps, printf('%smap <special> %s%s %s%s%s', mapmode, treemap, lhs, keyactions, action, target))
	elseif add == '<'
		call add(maps, printf('%smap <special> %s%s %s%s%s', mapmode, treemap, lhs, action, keyactions, target))
	else
		call add(maps, printf('%smap <special> %s%s %s%s', mapmode, treemap, lhs, action, target))
	endif

	"---------
	"enter map
	"---------
	let enter = get(settings, 'enter', ' ')
	if !empty(enter)
		let [whole, ecmd, elhs, erhs; ignored] = matchlist(enter, s:entrypat)
		if empty(ecmd)
			let ecmd = mapcmd
		endif
		if empty(elhs)
			let elhs = lhs
		endif
		let [whole, emode, enore; ignored] = matchlist(ecmd, '\m^\([^[:space:]]\)\?\(nore\)\?map')
		if empty(erhs) || erhs == '<Nop>'
			let eaction = ''
		else
			let eaction = s:Action(treename, printf('enter_%s', actionname), 1)
			call add(maps, printf('%s <special> %s %s', ecmd, eaction, erhs))
		endif
		if emode != mapmode || !empty(treemap) || elhs != lhs
			call add(maps, printf('%smap <special> %s %s%s%s', emode, elhs, eaction, treemap, lhs))
		endif
	endif

	for item in maps
		if len(item)
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
			let plugname = s:AsKeyNotation(s:AsEval(plugname))
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
