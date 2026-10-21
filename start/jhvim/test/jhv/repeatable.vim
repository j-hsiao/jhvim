set cpo+=<
function s:MyFunction()
	redraw | echo 'script-local MyFunction was called!' . join(reltime(), ':')
endfunction

" Repeatably call a script-local function.
call jhv#mappings#TMap(
	\ 't1', 'enter="nmap asdf"', expand('<SID>'), 'nmap . :call <SID>MyFunction()<CR>')

function s:TestEchoRange() range
	redraw | echo printf('from line %s to %s: %s', a:firstline, a:lastline, join(reltime(), ':'))
endfunction

" Mapping that changes modes.

execute 'TMap t2 ' . expand('<SID>') . ' enter=''vnoremap asdf :<CR>'''
	\ . ' nnoremap k ''<lt>V''>:call <SID>TestEchoRange()<CR>'
