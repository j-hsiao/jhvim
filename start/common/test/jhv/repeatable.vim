"set cpo+=<
function s:MyFunction()
	redraw | echo "script-local MyFunction was called!" . join(reltime(), ':')
endfunction

" Repeatable call a script-local function.
call jhv#repeatable#create(
	\ expand('<SID>'), 'nmap asdf :call <SID>MyFunction()<CR>')

function s:RepeatableTestEchoRange() range
	redraw | echo printf('from line %s to %s: %s', a:firstline, a:lastline, join(reltime(), ':'))
endfunction

" Mapping that changes modes.

execute 'Repeatable ' . expand('<SID>') . ' mode=n repeat=k vnoremap asdf :call <SID>RepeatableTestEchoRange()<CR>'
