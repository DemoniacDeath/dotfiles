set notimeout
set ttimeout
set hidden
set sw=4 ts=4 et si

call plug#begin()

  Plug 'tpope/vim-sensible'

  Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
  Plug 'junegunn/fzf.vim'

  Plug 'terryma/vim-multiple-cursors'

  Plug 'tpope/vim-fugitive'

  Plug 'airblade/vim-rooter'

  Plug 'scrooloose/nerdtree'

  Plug '~/.config/nvim/plugins/confirmQuit'

call plug#end()

nnoremap <silent> <Leader>q :bd<CR>
nnoremap <silent> <Leader>QQ :bd!<CR>
nnoremap <silent> <Leader>w :w<CR>
nnoremap <silent> <Leader>l :Buffers<CR>
nnoremap <silent> <Leader>p :Tags<CR>
nnoremap <silent> <Leader>P :Tags <C-R><C-W><CR>
nnoremap <silent> <Leader>r :BTags<CR>
nnoremap <silent> <Leader>R :BTags <C-R><C-W><CR>
nnoremap <silent> <Leader>f :Ag <CR>
nnoremap <silent> <Leader>F :Ag <C-R><C-W><CR>
nnoremap <silent> <Leader>c :source ~/.config/nvim/init.vim<CR>
nnoremap <silent> <Leader>z :FZF<CR>
nnoremap <silent> <Leader>] :NERDTreeToggle<CR>
nnoremap <silent> <Leader>t :tabnew<CR>

command! -bang -nargs=* BTags call 
  \ fzf#vim#buffer_tags(<q-args>, 
  \ printf('ctags -f - --sort=no --excmd=number --php-kinds=-dv  %s 2> /dev/null', 
  \ fzf#shellescape(expand('%'))), {}, <bang>0)

" vim: ts=2:sw=2:et:si
