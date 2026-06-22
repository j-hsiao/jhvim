if get(g:, 'jhv_loaded_miscellaneous', 0)
	finish
endif
let g:jhv_loaded_miscellaneous = 1

"Keep a mapping to the original
if maparg('<Leader><Leader>', 'i') == ''
	call jhv#mappings#CopyMap('i', '<Leader>', '<Leader><Leader>')
endif

" Break undo before large-ish deletion in insert mode
ExtendMap before=1 keep=1 inoremap <C-W> <C-G>u
ExtendMap before=1 keep=1 inoremap <C-U> <C-G>u

" Easier remove search highlighting.
if maparg('<C-[><C-[>') == ''
	nnoremap <C-[><C-[> :nohl<CR>
endif

"scratch buffer
if maparg('<Leader>b', 'n') == ''
	nnoremap <Leader>b :enew<CR>:setlocal buftype=nofile bufhidden=hide noswapfile<CR>
endif

" Formatting width.
function s:FitWidth(...)
	if a:0 < 1
		if v:count != v:count1
			if &l:textwidth
				let width = &l:textwidth
			else
				let width = 79
			endif
		else
			let width = v:count
		endif
		let &opfunc = function('s:FitWidth', [width])
		return "\<C-\>\<C-N>g@"
	else
		" echom printf('Called with count %s and type %s, line %s to %s', a:1, a:2,
		" line("'["), line("']"))
		let orig = &l:textwidth
		let &l:textwidth = a:1
		normal! '[gq']
		let &l:textwidth = orig
	endif
endfunction
nnoremap <expr> gq <SID>FitWidth()

nnoremap :u<CR> :up<CR>

"Treat prefixed jk as a jump.
nnoremap <expr> j v:count == v:count1 ? printf("m'%sj", v:count) : 'j'
nnoremap <expr> k v:count == v:count1 ? printf("m'%sk", v:count) : 'k'


" TODO comments, but that probably goes to a different file
" TODO surround
" TODO formatting header
"
"
"On windows, wt, (but not while in tmux) in insert mode,
"<C-[>O followed by some keys leads to odd behavior.  However, adding inoremap
"seems to avoid the behavior.  vim -u NONE seems to not have this behavior
"either.  vim in cygwin wt and standalone window seems to not have this
"behavior either.
"<C-[>O
" q: 1$
" w: 7$
" r: 2$
" t: 4$
" u: 5$
" o: /$
" p: 0$
" Q: <F2>
" R: <F3>

inoremap <C-[>O <C-[>O
