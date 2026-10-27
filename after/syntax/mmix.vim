" Extensions to the stock mmix syntax (runtime/syntax/mmix.vim).
" Adds MMIXAL pseudo-ops present in mmixal but missing from the 2012
" stock file (PREFIX, BSPEC, ESPEC -- verified against the mmixal
" binary), plus TODO-style markers inside comments.
if !exists('b:current_syntax') || b:current_syntax !=# 'mmix'
	finish
endif

syn keyword mmixPseudo	PREFIX BSPEC ESPEC

syn keyword mmixTodo	TODO FIXME NOTE XXX contained
hi def link mmixTodo	Todo

" Redefine comments to also highlight the markers above.
" (hi def link keeps the existing Comment highlighting.)
syn clear mmixComment
syn match mmixComment	"%.*" contains=@Spell,mmixTodo
syn match mmixComment	"//.*" contains=@Spell,mmixTodo
syn match mmixComment	"^\*.*" contains=@Spell,mmixTodo
