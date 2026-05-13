" -------------------------
" General sanity
" -------------------------
set nocompatible
set encoding=utf-8
syntax on
filetype plugin indent on
set number
set relativenumber
set showmatch
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set smartindent
set autoindent
" -------------------------
" Plugins via vim-plug
" -------------------------
call plug#begin('~/.vim/plugged')

Plug 'neoclide/coc.nvim', {'branch': 'release'}

call plug#end()

" -------------------------
" CoC basics
" -------------------------
set nobackup
set nowritebackup
set updatetime=300
set signcolumn=yes

" Completion menu behavior
set completeopt=menuone,noinsert,noselect

" Trigger completion
if has('nvim')
  inoremap <silent><expr> <C-Space> coc#refresh()
else
  inoremap <silent><expr> <C-@> coc#refresh()
endif

" Tab / Shift-Tab in popup
inoremap <silent><expr> <TAB> pumvisible() ? "\<C-n>" : "\<TAB>"
inoremap <silent><expr> <S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

" Confirm selection
inoremap <silent><expr> <CR> pumvisible() ? coc#_select_confirm() : "\<CR>"

" Navigation
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gr <Plug>(coc-references)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gy <Plug>(coc-type-definition)

" Rename
nmap <leader>rn <Plug>(coc-rename)

" Hover docs
nnoremap <silent> K :call CocActionAsync('doHover')<CR>
