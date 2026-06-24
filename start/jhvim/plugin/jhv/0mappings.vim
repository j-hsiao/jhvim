" User command for repeatable mapping.

if exists('g:loaded_plugin_jhv_mappings')
	finish
endif
let g:loaded_plugin_jhv_mappings = 1

command -nargs=1 Repeatable call jhv#mappings#Repeatable(<f-args>)
command -nargs=1 ExtendMap call jhv#mappings#ExtendMap(<f-args>)
command -nargs=1 Tmap call jhv#mappings#Tmap(<f-args>)
command -nargs=* CopyMap call jhv#mappings#CopyMap(<f-args>)
