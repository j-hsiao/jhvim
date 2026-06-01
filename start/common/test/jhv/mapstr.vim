" lhs/rhs in a mapping can is parsed into different characters.
" It cannot simply be escaped or quoted since the <> gets replaced
" by certain characters.


call assert_true(eval(jhv#mappings#Map2eval('<C-x>')) == "\<C-X>")
call assert_true(eval(jhv#mappings#Map2eval('"whatever"')) == '"whatever"')

for item in v:errors
	echom item
endfor
let v:errors = []
