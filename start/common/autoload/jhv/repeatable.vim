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

function! jhv#repeatable#Create(...)
	if match(&cpo, '.*<.*') >= 0
		set cpo-=<
		try
			return call('jhv#repeatable#Create', a:000)
		finally
			set cpo+=<
		endtry
	endif
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
		throw printf('Invalid map command: %s', join(mapcmd, ' '))
	else
		let [mapline, mapcmd, mapmode, mapnore, mapargs, lhs, rhs; ignored] = mapmatch
	endif
	if verbose
		for k in split('makemap mode name repeat transition verbose SID')
			echom printf('%10s = "%s"', k, get(l:, k))
		endfor
	endif
	if empty(mapcmd)
		throw printf('Mapping command invalid: %s', subcommand[idx:])
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
		let name = mapcmd[0] . lhs
	endif

	let lhmap = printf(
		\ '%smap <silent> %s <Plug>repeatable_map:%s;<Plug>repeatable_wait:%s;',
		\ mapmode, lhs, name, name)
	let rhmap = printf('%s %s <Plug>repeatable_map:%s; %s', mapcmd, mapargs, name, rhs)
	" Note, in old impl within Notes repo, I seem to have made some
	" kind of observation where detecting keypress, NOT consuming next
	" keypress, and returning empty string led to the next keypresses
	" NOT being mapped to any mappings.  However, I cannot seem to
	" reproduce this behavior.
	let wtmap = printf(
		\ '%smap <silent> <expr> <Plug>repeatable_wait:%s; getchar(1) == 0 ? (%s . "<Bslash><lt>Plug>repeatable_wait:%s;") : ""',
		\ mode, name, s:noop, substitute(escape(substitute(name, '<', '<lt>', 'g'), '<\"'), '\', '<Bslash>', 'g'))
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
		\ '%smap <silent> <Plug>repeatable_wait:%s;%s %s%s',
		\ mode, name, repeat, transition, lhs)
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
