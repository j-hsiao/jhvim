source _copymap.vim

let orig = maparg('asdf', 'n', 0, 1)

call jhv#mappings#CopyMap('n', 'asdf', '<C-A><C-S><C-D>')

let copied1 = maparg('<C-A><C-S><C-D>', 'n', 0, 1)


CopyMap n asdf fds<C-A>
let copied2 = maparg('fds<C-A>', 'n', 0, 1)


call assert_true(copied1['rhs'] == substitute( orig['rhs'], '<SID>', printf('<SNR>%d_', orig['sid']), 'g'), 'rhs did not match')
call assert_true(copied2['rhs'] == substitute( orig['rhs'], '<SID>', printf('<SNR>%d_', orig['sid']), 'g'), 'rhs did not match')
call assert_true(copied1['rhs'] == copied2['rhs'])




if empty(v:errors)
	echom 'all pass'
else
	for item in v:errors
		echom item
	endfor
endif
