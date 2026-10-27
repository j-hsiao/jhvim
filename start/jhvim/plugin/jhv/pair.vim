" complete single quotes
" backslash does NOT escape in bash, vim, sh

let jhv#pair#defaults = get(g:, 'jhv#pair#defaults', 1)

inoremap <expr> <Plug>jhv_pair_remove_left; jhv#pair#RemoveLeft()
inoremap <expr> <Plug>jhv_pair_prep_remove; jhv#pair#PrepRemove()

if jhv#pair#defaults
	call jhv#pair#Add('`', '`', 'markdown=bWt')
	call jhv#pair#Add("'", "'", 'bW', 'bash,vim,sh=W', 'python=bWpt')
	call jhv#pair#Add('"', '"', 'bW', 'python=bWpt')
	call jhv#pair#Add('(', ')', 'r')
	call jhv#pair#Add('[', ']')
	call jhv#pair#Add('{', '}')

	" <BS>, <C-U>, <C-W> will activate pair-aware removal.
	TMap keep=1 name='pre pair removal' add=< imap <BS> <Plug>jhv_pair_prep_remove;
	exec 'TMap keep=1 add=< imap <C-W>' jhv#mappings#Action('', 'pre pair removal')
	exec 'TMap keep=1 add=< imap <C-U>' jhv#mappings#Action('', 'pre pair removal')

	TMap name='post pair removal' add=> imap <BS> <Plug>jhv_pair_remove_left;
	exec 'TMap add=> imap <C-W>' jhv#mappings#Action('', 'post pair removal')
	exec 'TMap add=> imap <C-U>' jhv#mappings#Action('', 'post pair removal')


	" Allow easier rightward deletion to remove the auto-inserted pair.
	inoremap <C-L> <Del>
endif
