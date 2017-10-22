" Section: Plugin header {{{1
" If we have already loaded this file, don't load it again.
if exists("loaded_spacehi")
    finish
endif
let loaded_spacehi=1

" Section: Default Global Vars {{{1
if !exists("g:spacehi_tabcolor")
    " highlight tabs with red underline
    let g:spacehi_tabcolor="ctermfg=1 cterm=underline"
    let g:spacehi_tabcolor=g:spacehi_tabcolor . " guifg=red gui=underline"
endif
if !exists("g:spacehi_spacecolor")
    " highlight trailing spaces in blue underline
    let g:spacehi_spacecolor="ctermfg=4 cterm=underline"
    let g:spacehi_spacecolor=g:spacehi_spacecolor . " guifg=blue gui=underline"
endif

" Section: Functions {{{1
" Function: s:SpaceHi() {{{2
" Turn on highlighting of spaces and tabs
function! s:SpaceHi()
    " highlight tabs
    syntax match spacehiTab /\t/ containedin=ALL
    execute("highlight spacehiTab " . g:spacehi_tabcolor)

    " highlight trailing spaces
    syntax match spacehiTrailingSpace /\s\+$/ containedin=ALL
    execute("highlight spacehiTrailingSpace " . g:spacehi_spacecolor)

    let b:spacehi = 1
endfunction

" Function: s:NoSpaceHi() {{{2
" Turn off highlighting of spaces and tabs
function! s:NoSpaceHi()
    syntax clear spacehiTab
    syntax clear spacehiTrailingSpace
    let b:spacehi = 0
endfunction

" Function: s:ToggleSpaceHi() {{{2
" Toggle highlighting of spaces and tabs
function! s:ToggleSpaceHi()
    if exists("b:spacehi") && b:spacehi
        call s:NoSpaceHi()
        echo "spacehi off"
    else
        call s:SpaceHi()
        echo "spacehi on"
    endif
endfunction

" Section: Commands {{{1
com! SpaceHi call s:SpaceHi()
com! NoSpaceHi call s:NoSpaceHi()
com! ToggleSpaceHi call s:ToggleSpaceHi()

" Section: Default mappings {{{1
" Only insert a map to ToggleSpaceHi if they don't already have a map to
" the function and don't have something bound to F3
if !hasmapto('ToggleSpaceHi') && maparg("<F3>") == ""
  map <silent> <unique> <F3> :ToggleSpaceHi<CR>
endif

""" End of SpaceHi

:filetype indent on
:set bg=dark
:set ai
:set et
:set ts=4
:set sw=4

:set nu

:map gr gT

:set sr fo=roqm1 tw=74
:im <C-B> <C-O>:setl sr! fo<C-R>=strpart("-+",&sr,1)<CR>=tc<CR>

autocmd BufNewFile,BufReadPost,FilterReadPost,FileReadPost,Syntax * SpaceHi

set modeline

highlight OverLength ctermbg=black ctermfg=white guibg=#FFD9D9
match OverLength /\%81v.*/

" Protect large files from sourcing and other overhead.
" Files become read only
if !exists("my_auto_commands_loaded")
  let my_auto_commands_loaded = 1
  " Large files are > 10M
  " Set options:
  " eventignore+=FileType (no syntax highlighting etc
  " assumes FileType always on)
  " noswapfile (save copy of file)
  " bufhidden=unload (save memory when other file is viewed)
  " buftype=nowritefile (is read-only)
  " undolevels=-1 (no undo possible)
  let g:LargeFile = 1024 * 1024 * 10
  augroup LargeFile
    autocmd BufReadPre * let f=expand("<afile>") | if getfsize(f) > g:LargeFile | set eventignore+=FileType | setlocal noswapfile bufhidden=unload buftype=nowrite undolevels=-1 | else | set eventignore-=FileType | endif
    augroup END
endif

set hlsearch
"change word to uppercase, I love this very much
inoremap <C-u> <esc>gUiwea

au BufNewFile,BufRead *.cu set ft=cuda
au BufNewFile,BufRead *.cuh set ft=cuda
