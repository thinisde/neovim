if exists("current_compiler")
	finish
endif
let current_compiler = "mmixal"

if exists(":CompilerSet") != 2
	command -nargs=* CompilerSet setlocal <args>
endif

" Assemble the current file: foo.mms -> foo.mmo (+ foo.lst listing).
CompilerSet makeprg=mmixal\ -l\ %:r.lst\ -o\ %:r.mmo\ %
" mmixal diagnostics look like:  "file.mms", line 3: unknown operation code `X'!
" followed by context lines (e.g. `undefined symbol: foo').
CompilerSet errorformat=%A\"%f\"\\,\ line\ %l:\ %m,%-G%.%#errors\ were\ found.%.%#,%C%m,%-G%.%#
