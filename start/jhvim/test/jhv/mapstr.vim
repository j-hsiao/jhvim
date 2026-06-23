" lhs/rhs in a mapping can is parsed into different characters.
" It cannot simply be escaped or quoted since the <> gets replaced
" by certain characters.

let s:expect = ''
function s:MyFunction(arg)
	echom printf("called with arg %s via mapping", a:arg)
	call assert_true(a:arg == s:expect, printf('expect %s got %s', [s:expect], [a:arg]))
endfunction



call assert_true(jhv#mappings#Map2Estr('<C-x>') == '"\<C-X>"')
call assert_true(jhv#mappings#Map2Estr('"whatever"') == '"\"whatever\""')
call assert_true(jhv#mappings#Map2Estr('< whatever') == '"< whatever"')
call assert_true(jhv#mappings#Map2Estr('<Plug>') == '"\<Plug>"')


let s:pattern = 'nmap asdf :call <SID>MyFunction(%s)<CR>'

let s:expect = "\<Plug>"
exec printf(s:pattern, jhv#mappings#Str2Map('"\<Plug>"'))
normal asdf

let s:expect = "\<Plug>< \<C-x>"
exec printf(s:pattern, jhv#mappings#Str2Map(jhv#mappings#Map2Estr('<Plug><lt><Space><C-x>')))
normal asdf


nunmap asdf

if empty(v:errors)
	echom 'All Passed.'
else
	echom '!ERROR!'
	for item in v:errors
		echom item
	endfor
	let v:errors = []
endif
