" Add command for better repeatable mapping interface.

if exists('g:loaded_plugin_jhv_repeatable')
	finish
endif
let g:loaded_plugin_jhv_repeatable = 1

command -nargs=1 Repeatable call jhv#repeatable#create(<f-args>)
