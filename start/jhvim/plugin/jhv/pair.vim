" complete single quotes
" backslash does NOT escape in bash, vim, sh
call jhv#pair#Add("'", "'", 'fb', 'bash,vim,sh=')
call jhv#pair#Add('"', '"', 'fb')
call jhv#pair#Add('(', ')', 'fr')
call jhv#pair#Add('[', ']', 'f')
call jhv#pair#Add('{', '}', 'f')
