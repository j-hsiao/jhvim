function s:ScriptlocalFunction()
	echom "got called!" . join(reltime(), '.')
endfunction
nmap asdf :call <SID>ScriptlocalFunction()<CR>
