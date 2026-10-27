-- Unconditional `*.mms` -> `mmix` filetype.
-- (The stock runtime detection only fires when the first lines look like
-- MMIX comments, so a file starting with `LOC #100` would be missed.)
vim.filetype.add({
	extension = {
		mms = "mmix",
	},
})
