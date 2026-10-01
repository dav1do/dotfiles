" Readable diff colors for `git mergetool` (plain /usr/bin/vim).
" Vim's defaults paint fg and bg in the same hue, which hides the text.
" Palette matches the delta minus/plus styles in ~/.gitconfig.
set background=dark
if has('termguicolors')
  set termguicolors
endif

set diffopt+=iwhite
set nowrap
set scrollopt=ver,jump
set foldlevel=99

highlight clear DiffAdd
highlight clear DiffChange
highlight clear DiffDelete
highlight clear DiffText

" whole line added / present only here
highlight DiffAdd    guifg=NONE    guibg=#243a28 ctermfg=NONE ctermbg=22
" line exists on both sides but differs
highlight DiffChange guifg=NONE    guibg=#1f2c3c ctermfg=NONE ctermbg=17
" filler for lines missing on this side
highlight DiffDelete guifg=#4a3032 guibg=#2c2224 ctermfg=52   ctermbg=52
" the exact changed characters inside a DiffChange line
highlight DiffText   guifg=#f2e5c8 guibg=#7a5520 ctermfg=223  ctermbg=94 gui=bold cterm=bold

highlight StatusLine   guifg=#1d2021 guibg=#a89984 gui=bold
highlight StatusLineNC guifg=#1d2021 guibg=#665c54

" ── mappings ──────────────────────────────────────────────────────────
" Only `git mergetool` sources this file, so these never reach normal vim.
" h/l are pane positions, not words: LOCAL is the left pane, REMOTE the right.
let g:mapleader = ' '

nnoremap <leader>h :diffget LOCAL<CR>
nnoremap <leader>l :diffget REMOTE<CR>
xnoremap <leader>h :diffget LOCAL<CR>
xnoremap <leader>l :diffget REMOTE<CR>

nnoremap <leader>j ]czz
nnoremap <leader>k [czz
nnoremap <leader>u :diffupdate<CR>

nnoremap <leader>w :call <SID>MergeDone()<CR>
nnoremap <leader>q :cq<CR>

" git treats a clean exit as resolved without checking, so refuse to stage
" a file that still has markers in it. :wqa! forces.
function! s:MergeDone() abort
  if search('^\(<\{7}\|=\{7}\|>\{7}\||\{7}\)', 'nw')
    echohl WarningMsg | echo 'conflict markers still present — :wqa! to force' | echohl None
    return
  endif
  wqa
endfunction
