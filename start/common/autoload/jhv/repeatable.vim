"Create bindings for repeatable functions.
"
"Each set of bindings has:
"1. <rhs>: the action to run.
"2. <key>(sequence)
"3. <repeat>(sequence)
"
"NOTE: if action uses s:FuncName, then exec must be used
"or the <SID> will be for the wrong file.
"
"==============
"Implementation
"==============
"Repeatable bindings are acehived with this mechanism:
"1. map <key> <rhs><Plug>name;
"2. map <expr> <Plug>name; getchar(1) == 0 ? <Plug>name; : ''
"3. map <Plug>name;<repeat> -> <lhs>
"
"===========
"Explanation
"===========
"Mapping 1:
"	Run the action, activate mapping 2.
"Mapping 2:
"	map to itself until a key is pressed.
"Mapping 3:
"	This MUST be ambiguous with mapping 2 to reduce cpu usage.
"	If the <repeat> key is pressed, then use <lhs> to reactivate and thus
"	repeat the action.  If it is NOT pressed, then <Plug>name resolves to an
"	empty str and operation proceeds as normal.

" Create the mapping.
" name: a name to be used to represent the mapping
" command: the raw mapping command
function jhv#repeatable#create(name, command, ...)
	if match(a:command, '\m[[:blank:]]\(s:\|<SID>\)[a-zA-Z0-9_]') >= 0
		echom 'WARNING, jhv#crepeat#create should not be used with mappings containing s: or <SID>'
	endif
	# parse for lhs
	let parsed = matchlist(a:command, '\m[a-zA-Z]*map \(<[a-zA-Z]*>\)*\([^[:blank:]]*\)')
endfunction
