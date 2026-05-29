" User command for extending mapping.

if exists('g:loaded_plugin_jhv_extendmap')
	finish
endif
let g:loaded_plugin_jhv_extendmap = 1

command -nargs=1 ExtendMap call jhv#extendmap#ExtendMap(<f-args>)
