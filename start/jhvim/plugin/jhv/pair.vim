" complete single quotes
" backslash does NOT escape in bash, vim, sh

let jhv#pair#defaults = get(g:, 'jhv#pair#defaults', 1)

inoremap <expr> <Plug>jhv_pair_remove_left; jhv#pair#RemoveLeft()
inoremap <expr> <Plug>jhv_pair_prep_remove; jhv#pair#PrepRemove()

if jhv#pair#defaults
	call jhv#pair#Add('`', '`', 'markdown=bWt')
	call jhv#pair#Add("'", "'", 'bW', 'bash,vim,sh=W', 'python=bWt')
	call jhv#pair#Add('"', '"', 'bW', 'python=bWt')
	call jhv#pair#Add('(', ')', 'r')
	call jhv#pair#Add('[', ']')
	call jhv#pair#Add('{', '}')

	ExtendMap before=1 keep=1 imap <BS> <Plug>jhv_pair_prep_remove;
	ExtendMap imap <BS> <Plug>jhv_pair_remove_left;

	ExtendMap before=1 keep=1 imap <C-W> <Plug>jhv_pair_prep_remove;
	ExtendMap imap <C-W> <Plug>jhv_pair_remove_left;

	ExtendMap before=1 keep=1 imap <C-U> <Plug>jhv_pair_prep_remove;
	ExtendMap imap <C-U> <Plug>jhv_pair_remove_left;
endif
