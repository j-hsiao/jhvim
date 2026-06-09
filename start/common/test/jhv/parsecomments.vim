function! s:TestParsing()

	" C/C++ comments str
	let [single, multi] = jhv#parse#ParseComments(
		\ 'sO:* -,mO:*  ,exO:*/,s1:/*,mb:*,ex:*/,://,:#')

	" python
	let [single, multi] = jhv#parse#ParseComments('b:#,fb:-')

	" html
	let [single, multi] = jhv#parse#ParseComments('s:<!--,m:    ,e:-->')

	" bash
	let [single, multi] = jhv#parse#ParseComments('b:#')

endfunction
