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

if abs(len("\<Ignore>") - len('<Ignore>')) <= 1
	if abs(len("\<Cmd>") - len('<Cmd>')) > 1
		nnoremap <silent> <Plug>repeatable_nop; <Cmd>exec ''<CR>
		vnoremap <silent> <Plug>repeatable_nop; <Cmd>exec ''<CR>
		xnoremap <silent> <Plug>repeatable_nop; <Cmd>exec ''<CR>
		snoremap <silent> <Plug>repeatable_nop; <Cmd>exec ''<CR>
		onoremap <silent> <Plug>repeatable_nop; <Cmd>exec ''<CR>
		inoremap <silent> <Plug>repeatable_nop; <Cmd>exec ''<CR>
		lnoremap <silent> <Plug>repeatable_nop; <Cmd>exec ''<CR>
		cnoremap <silent> <Plug>repeatable_nop; <Cmd>exec ''<CR>
		tnoremap <silent> <Plug>repeatable_nop; <Cmd>exec ''<CR>
	else
		nnoremap <silent> <Plug>repeatable_nop; :exec ''<CR>
		inoremap <silent> <Plug>repeatable_nop; <C-R>=''<CR>
		" Todo: the other modes?
	endif
	let s:noop = '"\<Plug>repeatable_nop;"'
else
	let s:noop = '"\<Ignore>"'
endif


"Create a repeatable mapping.
"command: str, '[setting=value]... [M][nore]map [<map-args>] {lhs} {rhs}'
"
"`[M][nore]map ...` is a normal mapping command to make repeatable.
"[setting=value]: Extra arguments to control mappings (no spaces around the =)
"The value will be `json_decode()`ed or as is if failed.
"
"parsing:
"	Each argument is treated as a unescaped-space-separated sequence of
"	characters.  
function! jhv#repeatable#create(command)
	let makemap = 1
	let mode = ''
	let name = ''
	let repeat = '.'
	let transition = ''
	let verbose = v:false

	let idx = 0
	let end = len(a:command)
	let lhs = ''
	let mapcmd = []
	while idx < end
		let token = matchlist(a:command, '\m\(\(\\[[:blank:]]\|[^[:blank:]]\)*\)[[:blank:]]*', idx)
		if match(token[1], '^[nvxsoilct]\?\(nore\)\?map$') >= 0
			"1: *(nore)map
			"3: list of <map-arguments>
			"6: lhs
			"8: rhs
			let mapcmd = matchlist(
				\ a:command[idx:],
				\ '\m^\([nvxsoilct]\?\(nore\)\?map\)[[:blank:]]*\(\(<\(buffer\|nowait\|silent\|special\|script\|expr\|unique\)>[[:blank:]]*\)*\)\(\(\\[[:blank:]]\|[^[:blank:]]\)*\)[[:blank:]]*\(.\+\)')
			break
		else
			let extra = matchlist(
				\ substitute(token[1], '\\\(.\)', '\1', 'g'),
				\ '\m^\(makemap\|mode\|name\|repeat\|transition\|verbose\)=\(.*\)')
			call assert_true(!empty(extra))
			if empty(extra)
				throw printf('Bad settings token for jhv#repeatable#create: "%s"', token[1])
			else
				try
					let value = json_decode(extra[2])
				catch
					let value = extra[2]
				endtry
				exec printf('let %s = value', extra[1])
			endif
		endif
		let idx += len(token[0])
	endwhile

	if verbose
		for k in split('makemap mode name repeat transition verbose')
			echom printf('%s = "%s"', k, get(l:, k))
		endfor
	endif
	if empty(mapcmd)
		throw printf('Mapping command invalid: %s', a:command[idx:])
	endif
	if verbose
		echom printf('map cmd: "%s"', mapcmd[1])
		echom printf('map-arg: "%s"', mapcmd[3])
		echom printf('map lhs: "%s"', mapcmd[6])
		echom printf('map rhs: "%s"', mapcmd[8])
	endif

	if makemap && match(mapcmd[8], '\m[[:blank:]]\(s:\|<SID>\)[a-zA-Z0-9_]') >= 0
		echohl WarningMsg | echom 'WARNING: rhs contains <SID> or s:but makemap is true.'
	endif
	let mapargs = mapcmd[3]
	let lhs = mapcmd[6]
	let rhs = mapcmd[8]
	let mapcmd = mapcmd[1]

	if empty(mode)
		let mode = mapcmd[0]
	endif
	if empty(name)
		let name = mapcmd[0] . '-mode-' . lhs
	endif

	let lhmap = printf(
		\ '%smap %s <Plug>repeatable_map:%s;<Plug>repeatable_wait:%s;',
		\ mapcmd[0], lhs, name, name)
	let rhmap = printf('%s %s<Plug>repeatable_map:%s; %s', mapcmd, mapargs, name, rhs)
	" Note, in old impl within Notes repo, I seem to have made some
	" kind of observation where detecting keypress, NOT consuming next
	" keypress, and returning empty string led to the next keypresses
	" NOT being mapped to any mappings.  However, I cannot seem to
	" reproduce this behavior.
	let wtmap = printf(
		\ '%smap <expr> <Plug>repeatable_wait:%s; getchar(1) == 0 ? (%s . "\<Plug>repeatable_wait:%s;") : ""',
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
		\ '%smap <Plug>repeatable_wait:%s;%s %s%s',
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
