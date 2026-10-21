call jhv#mappings#TMap('t1 map <expr> asdf '':echom '' . ''"hello"<CR>''')
call jhv#mappings#TMap('t1 add=> map asdf :echom "goodbye"<CR>')
call jhv#mappings#TMap('t1 add=<', 'map asdf :echom join(reltime(), ".")<CR>')

TMap t1 add=> nnoremap asdf :echom "Footer"<CR>
TMap t1 add=< nnoremap asdf :echom "Header"<CR>

" Expect:
"   Header
"   timestamp
"   hello
"   goodbye
"   Footer

TMap f1 enter=f1 nnoremap . :echom printf('rep! %s', join(reltime(), '.'))<CR>
TMap f1 add=> nnoremap . :echom 'extended at the end.'<CR>

TMap f2 enter=f2 nnoremap . :echom printf('rep! %s', join(reltime(), '.'))<CR>
TMap f2 add=< nnoremap . :echom 'Extend at beginning repeats with command.'<CR>

