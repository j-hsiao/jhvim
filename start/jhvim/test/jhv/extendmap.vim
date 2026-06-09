call jhv#mappings#ExtendMap('map <expr> asdf '':echom '' . ''"hello"<CR>''')
call jhv#mappings#ExtendMap('map asdf :echom "goodbye"<CR>')
call jhv#mappings#ExtendMap('before=1', 'map asdf :echom join(reltime(), ".")<CR>')

ExtendMap nnoremap asdf :echom "Footer"<CR>
ExtendMap before=1 nnoremap asdf :echom "Header"<CR>

Repeatable nnoremap f1 :echom printf('Repeatable! %s', join(reltime(), '.'))<CR>
ExtendMap rep=0 nnoremap f1 :echom 'cancelled due to direct extend at end.'<CR>

Repeatable nnoremap f2 :echom printf('Repeatable! %s', join(reltime(), '.'))<CR>
ExtendMap before=1 nnoremap f2 :echom 'Extend at beginning repeats with command.'<CR>

Repeatable nnoremap f3 :echom printf('Repeatable! %s', join(reltime(), '.'))<CR>
ExtendMap nnoremap f3 :echom 'With rep, repeats and at end.'<CR>
