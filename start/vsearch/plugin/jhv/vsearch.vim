vnoremap <expr> <Plug>JHV_Vsearch;Search_forward; jhv#vsearch#Search('/', v:true)
vnoremap <expr> <Plug>JHV_Vsearch;Search_forward_exact; jhv#vsearch#Search('/', v:false)
vnoremap <expr> <Plug>JHV_Vsearch;Search_backward; jhv#vsearch#Search('?', v:true)
vnoremap <expr> <Plug>JHV_Vsearch;Search_backward_exact; jhv#vsearch#Search('?', v:false)
nnoremap <expr> <Plug>JHV_Vsearch;Search_note_header; jhv#vsearch#NoteSearch()

if maparg("*", 'v') == ''
	vmap * <Plug>JHV_Vsearch;Search_forward;
endif
if maparg("#", 'v') == ''
	vmap # <Plug>JHV_Vsearch;Search_backward;
endif

if maparg("<Leader>*", 'v') == ''
	vmap <Leader>* <Plug>JHV_Vsearch;Search_forward_exact;
endif
if maparg("<Leader>#", 'v') == ''
	vmap <Leader># <Plug>JHV_Vsearch;Search_backward_exact;
endif


if maparg("<Leader><C-]>", 'n') == ''
	nmap <Leader><C-]> <Plug>JHV_Vsearch;Search_note_header;
endif
