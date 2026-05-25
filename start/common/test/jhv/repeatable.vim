"set cpo+=<
function s:MyFunction()
	echom "script-local MyFunction was called!" . join(reltime(), ':')
endfunction

" Repeatable call a script-local function.
call jhv#repeatable#create(
	\ expand('<SID>'), 'nmap asdf :call <SID>MyFunction()<CR>')
"TODO: why does repeat print to :mes but status line gets blanked.
"but status line does NOT get blanked on the first one.
function s:RepeatableTestEchoRange() range
	echom printf('from line %s to %s: %s', a:firstline, a:lastline, join(reltime(), ':'))
endfunction

" Mapping that changes modes.

execute 'Repeatable ' . expand('<SID>') . ' mode=n repeat=k vnoremap asdf :call <SID>RepeatableTestEchoRange()<CR>'
