" complete single quotes
" backslash does NOT escape in bash, vim, sh
call jhv#autopair#Add("'", "'", 'fWb', 'bash,vim,sh=W')
call jhv#autopair#Add('"', '"', 'fWb')
call jhv#autopair#Add('(', ')', 'fr')
call jhv#autopair#Add('[', ']', 'f')
call jhv#autopair#Add('{', '}', 'f')
