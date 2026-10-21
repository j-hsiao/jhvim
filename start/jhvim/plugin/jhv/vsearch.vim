TMap add=> name='search forward' vnoremap <expr> * jhv#vsearch#Search('/', v:true)
TMap add=> name='search backward' vnoremap <expr> # jhv#vsearch#Search('?', v:true)

TMap add=> name='search forward exact' vnoremap <expr> <Leader>* jhv#vsearch#Search('/', v:false)
TMap add=> name='search backward exact' vnoremap <expr> <Leader># jhv#vsearch#Search('?', v:false)

TMap add=> name='search note header' nnoremap <expr> <Leader><C-]> jhv#vsearch#NoteSearch()
