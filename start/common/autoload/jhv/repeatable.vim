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
"
"Given the arguments:
"	LHS: the left-hand side of the desired mapping.
"	RHS: the right-hand side of the desired mapping.
"	M: the mode of the mapping
"	<repeats>: (sequence of) key to repeat the mapping.
"
"The mappings created are:
"1. M(nore)map <map-args> <Plug>LHS; RHS
"	Insert <Plug> in front of the LHS.  The effect is that <Plug>LHS will
"	activate the desired mapping.
"
"2. Mmap <LHS> <Plug>LHS;<Plug><Plug>LHS;
"	This mapping activates the first mapping and then queues up keypresses
"	for the ambiguous mapping command.  LHS MUST be recursive or it would
"	not be able to activate the ambiguous mappings 3 and 4.
"
"3. Mmap <expr> <Plug><Plug>LHS; <SID>WaitRepeat(LHS)
"	WaitRepeat is a function that checks whether any keys have been pressed.
"	If pressed, then return an empty string.  Otherwise, return
"	<Plug><Plug>LHS;.  This way vim will continue waiting for a keypress.
"	Note that this mapping is ambiguous with mapping 4.
"
"4. Mmap <Plug><Plug>LHS;<repeats> LHS
"	This mapping maps the repeat key after activating to pressing LHS again
"	thus repeating the mapping.

function jhv#repeatable#WaitRepeat(lhs)
	if getchar(1) == 0
		echom 'no keypress...' . join(reltime(), ':')
		return "\<Plug>\<Plug>" . a:lhs . ';'
	else
		return ''
	endif
endfunction


"command is a map command. The LHS MUST use <> notation (see :h key-notation)
"optional arguments:
"	repeat: the key (sequence) to press to repeat the mapping
"	str: For the main rhs mapping, return a str for the caller to exec instead
"		of creating the mapping directly.  This is useful if the rhs contains
"		<SID> or s:.  If this kind of mapping was created within
"		jhv#repeatable#create, then the <SID> would point to the wrong file.
function jhv#repeatable#create(command, ...)
	if a:0
		let repeat = a:1
	else
		let repeat = '.'
	endif
	if a:0 >= 2
		let makemap = a:2
	else
		let makemap = 1
	endif
	if makemap && match(a:command, '\m[[:blank:]]\(s:\|<SID>\)[a-zA-Z0-9_]') >= 0
		echom 'WARNING, jhv#crepeat#create should not be used with mappings containing s: or <SID>'
	endif
	let parsed = matchlist(a:command, '\m^[[:blank:]]*\([a-z]\{-}map[[:blank:]]*\)\(\(<\(buffer\|nowait\|silent\|special\|script\|expr\|unique\)>[[:blank:]]*\)*\)\([^[:blank:]]*\)\(.*\)')
	let mapcmd = parsed[1]
	let mapargs = parsed[2]
	let lhs = parsed[5]
	let rhs = parsed[6]

	exec mapcmd[0] . 'map ' . lhs . ' <Plug>' . lhs . ';<Plug><Plug>' . lhs . ';'
	exec mapcmd[0] . 'map <expr> <Plug><Plug>' . lhs . '; jhv#repeatable#WaitRepeat("' . escape(lhs, '"<') . '")'
	"exec mapcmd[0] . 'map <expr> <Plug><Plug>' . lhs . '; <SID>WaitRepeat("' . escape(lhs, '"<') . '")'
	exec mapcmd[0] . 'map <Plug><Plug>' . lhs . ';' . repeat . ' ' . lhs

	let rawmap = mapcmd . mapargs . '<Plug>' . lhs . ';' . rhs
	if makemap
		exec rawmap
	else
		return rawmap
	endif
endfunction
