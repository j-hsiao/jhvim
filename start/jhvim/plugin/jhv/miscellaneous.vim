" Break undo before large-ish deletion in insert mode
ExtendMap before=1 keep=1 inoremap <C-W> <C-G>u
ExtendMap before=1 keep=1 inoremap <C-U> <C-G>u

" Easier remove search highlighting.
nnoremap <C-[><C-[> :nohl<CR>
