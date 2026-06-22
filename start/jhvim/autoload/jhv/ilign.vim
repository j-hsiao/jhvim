"indent/align
"Experiment with idea 'tabs for indentation, spaces for alignment'
"
"principals:
"1. indentation/alignment are always added/removed from the right.
"2. Alignment always prefers softtabstop if not a calculated alignment.
"3. Indentation prefers shiftwidth unless noexpandtab, in which case it uses
"   tabstop.
"4. Indentation/alignment can be before or after a comment marker.
"
"Note 1: Experimented with 'normalized indetation/alignment' where all tabs
"are grouped together before spaces.  However, this does not work because
"a logical indentation might be required after an alignment.

se preserveindent copyindent

function s:STS()
	if &l:sts < 0
		return shiftwidth()
	elseif &l:sts == 0
		return &l:ts
	else
		return &l:sts
	endif
endfunction

" Explicitly intering a tab allows pressing tab only to enter more tabs.
Repeatable repeat=<Tab> inoremap <C-V><Tab> <C-V><Tab>
