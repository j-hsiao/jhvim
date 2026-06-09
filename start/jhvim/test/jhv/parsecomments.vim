function! s:TestParsing()

	" C/C++ comments str
	let [single, multi] = jhv#parse#ParseComments(
		\ 'sO:* -,mO:*  ,exO:*/,s1:/*,mb:*,ex:*/,://,:#')

	echom single == [['', '//'], ['', '#']]
	echom multi == [['sO', '* -', 'mO', '*  ', 'exO', '*/'], ['s1', '/*', 'mb', '*', 'ex', '*/']]

	echom matchlist('  // comment', jhv#parse#SingleCommentRegex(single[0]))[:4]
		\ == ['  // comment', '  ', '//', ' ', 'comment']
	echom matchlist('  #define macro arg', jhv#parse#SingleCommentRegex(single[1]))[:4]
		\ == ['  #define macro arg', '  ', '#', '', 'define macro arg']

	echom matchlist('  /* this is a comment*/', jhv#parse#MultiCommentRegex(multi[1])[3])[:3]
		\ == ['  /* this is a comment*/', '  /* this is a comment', '', '*/']

	" python
	let [single, multi] = jhv#parse#ParseComments('b:#,fb:-')
	echom single == [['b', '#'], ['fb', '-']]
	echom multi == []

	echom matchlist('  # comment', jhv#parse#SingleCommentRegex(single[0]))[:4]
		\ == ['  # comment', '  ', '#', ' ', 'comment']
	echom matchlist('  #comment', jhv#parse#SingleCommentRegex(single[0]))[:4]
		\ == []

	" html
	let [single, multi] = jhv#parse#ParseComments('s:<!--,m:    ,e:-->')
	echom single == []
	echom multi == [['s', '<!--', 'm', '    ', 'e', '-->']]

	echom matchlist(' <!--this is an html comment -->', jhv#parse#MultiCommentRegex(multi[0])[3])[:3]
		\ == [' <!--this is an html comment -->', ' <!--this is an html comment ', '', '-->']

	" bash
	let [single, multi] = jhv#parse#ParseComments('b:#')
	echom single == [['b', '#']]
	echom multi == []

	echom matchlist('  # comment', jhv#parse#SingleCommentRegex(single[0]))[:4]
		\ == ['  # comment', '  ', '#', ' ', 'comment']

endfunction

call <SID>TestParsing()
function! s:SearchComment()
	let [single, multi] = jhv#parse#ParseComments()
	for item in single
		echo printf('%s: %s', item[1], searchpos(jhv#parse#SingleCommentRegex(item), 'nc'))
		echo printf('%s: %s', item[1], searchpos(jhv#parse#SingleCommentRegex(item), 'ncb', 1))
	endfor

	for item in multi
		let reg = jhv#parse#MultiCommentRegex(item)
		echo printf('%s: %s', item[1], searchpos(reg[3], 'nc'))
		echo printf('%s: %s', item[1], searchpos(reg[3], 'ncb', 1))
	endfor

	echo jhv#parse#IsSingleCommentRegex(single)
	let result = search(
		\ jhv#parse#IsSingleCommentRegex(single),
		\ 'ncpb', line('.'))
	if result
		echo printf('is a single comment: %s', single[result-1])
	else
		echo 'not a comment'
	endif
endfunction


nmap asdfdsa :call <SID>SearchComment()<CR>
