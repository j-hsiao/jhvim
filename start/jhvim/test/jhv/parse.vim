let [settings, cmd] = jhv#parse#Settings(['a', 'b', 'c'], expand('<SID>'), 'a=1', 'b="hello world" c="goodbye world\nokaydokay" b commanded', 'extra')

call assert_true(settings['SID'] == expand('<SID>'))
call assert_true(settings['a'] == 1)
call assert_true(settings['b'] == 'hello world')
call assert_true(settings['c'] == "goodbye world\nokaydokay")
call assert_true(cmd == 'b commanded extra')

let [settings, cmd] = jhv#parse#Settings(['a', 'b', 'c'], expand('<SID>'), 'a=1', "b='hello world' c=\"goodbye world\\\"\" b commanded", 'extra')

call assert_true(settings['SID'] == expand('<SID>'))
call assert_true(settings['a'] == 1)
call assert_true(settings['b'] == 'hello world')
call assert_true(settings['c'] == 'goodbye world"')
call assert_true(cmd == 'b commanded extra')


if empty(v:errors)
	echom 'All Passed.'
else
	echom '!ERROR!'
	for item in v:errors
		echom item
	endfor
	let v:errors = []
endif
