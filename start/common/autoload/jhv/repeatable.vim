"Create bindings for repeatable functions.
"
"==============
"Implementation
"==============
"A series of mappings are created to map LHS to RHS and allow repeating
"with a chosen sequence.  Ambiguous mappings are chosen to reduce cpu
"usage and let vim wait for a new keypress to determine whether or not
"to repeat the mapping.
"
"Given the arguments:
"	LHS: the left-hand side of the desired mapping.
"	RHS: the right-hand side of the desired mapping.
"	M: the mode of the mapping
"	<repeat>: The desired repeat key (sequence) to re-activate the mapping.
"
"The mappings created are:
"1. lhmap: map LHS to map 2 followed by prefix of map 3 and 4.
"2. rhmap: A mapping to activate rhs.
"3. wtmap.  This mapping detects whether to repeat the mapping.
"4. rpmap.  This mapping does the actual repeating.
"
"=======================
"repetition observations
"=======================
"To create a repeating mapping, there are 2 possibilities.
"1. Wait for a key to be pressed.  If the key matches <repeat>, then the rhs
"   must be called again.  Otherwise, the waiting step should produce a no-op.
"   In this case, the repeating step must explicitly handle the interpretation
"   of the following keys and match it against <repeat> and return <LHS> if
"   matching <repeat> or otherwise reproduce the consumed keys.
"2. Use ambiguous mappings to let vim handle whether to repeat or not.
"   However, vim uses a timeout for ambiguous mappings.  To continuously wait
"   until the next key to see whether a repeat should be done, the shorter
"   ambiguous mapping must call itself.  This leads to some problems.
"   Return ambiguous lhs:
"     This leads to a left-recursive mapping.  As a result, the repeated
"     lhs is NOT mapped again and so does not reactivate.
"     `:h recursive_mapping`
"   Return a <map to <Nop>> before a:prefix
"     This seems to break the left-recursive mapping behavior of being
"     unmapped.  However, this has some undocumented behavior where ?because
"     the lhs has been disambiguated and the mapping has not completed, there
"     is infinite recursion with no delay which hits the recursion limit,
"     causes an error, and then stops waiting for the next keypress.
"     This behavior is mentioned at
"     https://vi.stackexchange.com/questions/13862/using-a-no-op-key-in-insert-mode-cant-use-key-after-using-no-op-mapping
"   Return <Ignore> before.
"     This seems to work, but <Ignore> is not available on older vim.
"     `:h <Ignore>`
"   Return some kind of no-op sequence.
"     This method should work for all vim versions.  However, there doesn't
"     seem to be a universal no-op key sequence.  The current mode would need
"     to be determined somehow and the no-op determined accordingly
"     n: :exec ''
"     i: <C-r>=''<CR>
"     v: ??
"
if abs(len("\<Ignore>") - len('<Ignore>')) <= 1
	if abs(len("\<Cmd>") - len('<Cmd>')) > 1
		nnoremap <silent> <Plug>noprepeatable; <Cmd>exec ''<CR>
		vnoremap <silent> <Plug>noprepeatable; <Cmd>exec ''<CR>
		xnoremap <silent> <Plug>noprepeatable; <Cmd>exec ''<CR>
		snoremap <silent> <Plug>noprepeatable; <Cmd>exec ''<CR>
		onoremap <silent> <Plug>noprepeatable; <Cmd>exec ''<CR>
		inoremap <silent> <Plug>noprepeatable; <Cmd>exec ''<CR>
		lnoremap <silent> <Plug>noprepeatable; <Cmd>exec ''<CR>
		cnoremap <silent> <Plug>noprepeatable; <Cmd>exec ''<CR>
		tnoremap <silent> <Plug>noprepeatable; <Cmd>exec ''<CR>
	else
		nnoremap <silent> <Plug>noprepeatable; :exec ''<CR>
		inoremap <silent> <Plug>noprepeatable; <C-R>=''<CR>
		" Todo: the other modes?
	endif
	let s:noop = '"\<Plug>noprepeatable;"'
else
	let s:noop = '"\<Ignore>"'
endif


"Create a repeatable mapping.
"command: str, the map command for a non-repeatable vresion.  Use <> notation.
"(see :h key-notation)
"
"Additional arguments: strings of form 'name=value' where value is a
"json-encoded value.  NOTE: if json-decoding fails, then use the value as is
"So, for example, mode=asdf, asdf is an invalid json string, so the string
"'asdf' will be used instead.
"	name: str, name for the mapping, which should be unique.
"		Default to mode . '-mode-' . lhs
"	repeat: str, the key (sequence) to press to repeat the mapping
"	makemap: bool, create the map inside the function. Otherwise, return a
"		string that can be `exec`ed to create the desired mapping.  This is
"		mainly to handle the case where the mapping contains <SID> or s:.
"		If that kind of mapping was created inside this function, then
"		<SID>/s: would evaluate to repeatable.vim instead of wherever create()
"		is being called from.
"	mode: str, the mode after the intial mapping. For example, if mapping in
"		V mode and running some command, it might end in normal mode.
"		In that case, mode should be 'n'.  Otherwise, mode will be assumed to
"		match the map command in command
"	transition: str, key-sequence to transition from mode back into initial
"		mode.  Example: vmap ending in normal mode, transition might be something
"		like '[v'] to highlight the region in visual mode.  This way, when the
"		mapping is repeated, it is in the correct mode and rhs can be activated.
"		If omitted, then try making a best guess:
"		map mode    default
"		v   n       `<lt>v`>
"		n   v       <C-\><C-N>
"		i   n       a
"		n   i       <C-\><C-N>
function! jhv#repeatable#create(command, ...)
	let repeat = '.'
	let makemap = 1
	let mode = ''
	let verbose = v:false
	let transition = ''
	let name = ''
	for kp in a:000
		let parsed = matchlist(kp, '[[:blank:]]*\([^[:blank:]=]*\)[[:blank:]]*=[[:blank:]]*\(.*[^[:blank:]]\)')
		try
			let value = json_decode(parsed[2])
		catch
			let value = parsed[2]
		endtry
		exec printf('let %s = value', parsed[1])
	endfor
	if verbose
		echom printf("Parsing command %s\n  repeat: %s\n  makemap: %s\n  mode: %s",
			\ a:command, repeat, makemap, mode)
	endif

	if makemap && match(a:command, '\m[[:blank:]]\(s:\|<SID>\)[a-zA-Z0-9_]') >= 0
		echom 'WARNING, jhv#repeatable#create should not be used with mappings containing s: or <SID>'
	endif
	let parsed = matchlist(a:command, '\m^[[:blank:]]*\([a-z]\{-}map[[:blank:]]*\)\(\(<\(buffer\|nowait\|silent\|special\|script\|expr\|unique\)>[[:blank:]]*\)*\)\([^[:blank:]]*\)\(.*\)')
	let mapcmd = parsed[1]
	let mapargs = parsed[2]
	let lhs = parsed[5]
	let rhs = parsed[6]

	if empty(mode)
		let mode = mapcmd[0]
	endif
	if empty(name)
		let name = mapcmd[0] . '-mode-' . lhs
	endif

	let lhmap = printf(
		\ '%smap %s <Plug>repeatable%s;<Plug>rrepeatable%s;',
		\ mapcmd[0], lhs, name, name)
	let rhmap = printf('%s%s<Plug>repeatable%s;%s', mapcmd, mapargs, name, rhs)
	" Note, in old impl within Notes repo, I seem to have made some
	" kind of observation where detecting keypress, NOT consuming next
	" keypress, and returning empty string led to the next keypresses
	" NOT being mapped to any mappings.  However, I cannot seem to
	" reproduce this behavior.
	let wtmap = printf(
		\ '%smap <expr> <Plug>rrepeatable%s; getchar(1) == 0 ? (%s . "\<Plug>rrepeatable%s;") : ""',
		\ mode, name, s:noop, escape(name, '<"\'))

	if empty(transition)
		if mode != mapcmd[0]
			if mode == 'n'
				if mapcmd[0] == 'i'
					let transition = 'a'
				elseif mapcmd[0] == 'v'
					let transition = '`<lt>v`>'
				endif
			elseif mapcmd[0] == 'n'
				let transition = '<C-\><C-N>'
			endif
		endif
	endif

	let rpmap = printf(
		\ '%smap <Plug>rrepeatable%s;%s %s%s',
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
