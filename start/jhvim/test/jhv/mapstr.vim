" lhs/rhs in a mapping can is parsed into different characters.
" It cannot simply be escaped or quoted since the <> gets replaced
" by certain characters.

let s:expect = ''
function s:MyFunction(arg)
	echom printf("called with arg %s via mapping", a:arg)
	call assert_true(a:arg == s:expect, printf('expect %s got %s', [s:expect], [a:arg]))
endfunction



call assert_true(jhv#mappings#AsEval('<C-x>') == '"\<C-X>"')
call assert_true(jhv#mappings#AsEval('"whatever"') == '"\"whatever\""')
call assert_true(jhv#mappings#AsEval('< whatever') == '"< whatever"')
call assert_true(jhv#mappings#AsEval('<Plug>') == '"\<Plug>"')


let s:pattern = 'nmap asdf :call <SID>MyFunction(%s)<CR>'

let s:expect = "\<Plug>"
exec printf(s:pattern, jhv#mappings#AsKeyNotation('"\<Plug>"'))
normal asdf

let s:expect = "\<Plug>< \<C-x>"
exec printf(s:pattern, jhv#mappings#AsKeyNotation(jhv#mappings#AsEval('<Plug><lt><Space><C-x>')))
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

"call jhv#mappings#Tmap('t1', 'verbose=1 name=printa enter=["n","aaa"] nnoremap a :echom "a" . join(reltime(), ":")<CR>')
"call jhv#mappings#Tmap('t1', 'verbose=1 name=printb nnoremap b :echom "b" . join(reltime(), ":")<CR>')
"nmap bbb <Plug>Tmap_do:printb;<Plug>Tmap:t1;
