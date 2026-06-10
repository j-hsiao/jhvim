vnoremap <expr> <Plug>JHV_Vsearch;Search_forward; jhv#vsearch#Search('/', v:true)
vnoremap <expr> <Plug>JHV_Vsearch;Search_forward_exact; jhv#vsearch#Search('/', v:false)
vnoremap <expr> <Plug>JHV_Vsearch;Search_backward; jhv#vsearch#Search('?', v:true)
vnoremap <expr> <Plug>JHV_Vsearch;Search_backward_exact; jhv#vsearch#Search('?', v:false)
nnoremap <expr> <Plug>JHV_Vsearch;Search_note_header; jhv#vsearch#NoteSearch()



ExtendMap vmap * <Plug>JHV_Vsearch;Search_forward;
ExtendMap vmap # <Plug>JHV_Vsearch;Search_backward;
ExtendMap vmap <Leader>* <Plug>JHV_Vsearch;Search_forward_exact;
ExtendMap vmap <Leader># <Plug>JHV_Vsearch;Search_backward_exact;
ExtendMap nmap <Leader><C-]> <Plug>JHV_Vsearch;Search_note_header;
