" VIM Config

set nocompatible

set autoindent
set backspace=indent,eol,start
set browsedir=current
set directory=$HOME/.vim/swap//
set encoding=utf-8
set expandtab
set exrc
set fileencoding=utf-8
set fileencodings=ucs-bom,utf-8,latin1
set fileformat=unix
set fileformats=unix,mac,dos
set hidden
set history=100
set hlsearch
set laststatus=2
set modeline
set modelines=1
set number
set report=0
set ruler
set scrolloff=999
set shiftround
set shiftwidth=4
set smartindent
set softtabstop=4
set tabstop=4

let g:netrw_liststyle=3
let g:netrw_banner = 0
let g:netrw_browse_split = 3
let g:netrw_list_hide= '.*\.sw\a$'

syntax enable

filetype on
filetype plugin on
filetype indent on

command! S :%s/\s*$// | nohl

nmap <C-H> :tabprevious<CR>
nmap <C-L> :tabnext<CR>

autocmd BufNewFile,BufRead *.go set filetype=go
autocmd BufNewFile,BufRead *.js set filetype=javascript
autocmd BufNewFile,BufRead *.json set filetype=javascript
autocmd BufNewFile,BufRead *.md set filetype=markdown
autocmd BufNewFile,BufRead *.scss set filetype=scss
autocmd BufNewFile,BufRead *.vue set filetype=vue

autocmd FileType yaml setlocal noexpandtab softtabstop=2 shiftwidth=2 tabstop=2
autocmd FileType yml setlocal noexpandtab softtabstop=2 shiftwidth=2 tabstop=2

"" Uncomment for Tmux
"function! WrapForTmux(s)
"    if !exists('$TMUX')
"        return a:s
"    endif
"    let tmux_start = "\<Esc>Ptmux;"
"    let tmux_end = "\<Esc>\\"
"    return tmux_start . substitute(a:s, "\<Esc>", "\<Esc>\<Esc>", 'g') . tmux_end
"endfunction
"
"let &t_SI .= WrapForTmux("\<Esc>[?2004h")
"let &t_EI .= WrapForTmux("\<Esc>[?2004l")

" Auto Paste Mode
let &t_SI .= "\<Esc>[?2004h"
let &t_EI .= "\<Esc>[?2004l"

function! XTermPasteBegin()
    set pastetoggle=<Esc>[201~
    set paste
    return ""
endfunction

inoremap <special> <expr> <Esc>[200~ XTermPasteBegin()
