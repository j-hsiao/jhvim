call jhv#extendmap#ExtendMap('map <expr> asdf '':echom '' . ''"hello"<CR>''')
call jhv#extendmap#ExtendMap('map asdf :echom "goodbye"<CR>')
call jhv#extendmap#ExtendMap('before=1', 'map asdf :echom join(reltime(), ".")<CR>')

ExtendMap nnoremap asdf :echom "Footer"<CR>
ExtendMap before=1 nnoremap asdf :echom "Header"<CR>

Repeatable nnoremap f1 :echom printf('Repeatable! %s', join(reltime(), '.'))<CR>
ExtendMap nnoremap f1 :echom 'cancelled due to extend at end.'<CR>

Repeatable nnoremap f2 :echom printf('Repeatable! %s', join(reltime(), '.'))<CR>
ExtendMap before=1 nnoremap f2 :echom 'Extend at beginning repeats with command.'<CR>

Repeatable nnoremap f3 :echom printf('Repeatable! %s', join(reltime(), '.'))<CR>
ExtendMap name=f3 nnoremap <Plug>repeatable_map:n:f3; :echom 'Extend plug allows repeat at end.'<CR>
