call plug#begin()

  Plug 'tpope/vim-sensible'

  Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
  Plug 'junegunn/fzf.vim'

  Plug 'terryma/vim-multiple-cursors'

  Plug 'tpope/vim-fugitive'

call plug#end()

set notimeout
set ttimeout

nnoremap <silent> <Leader>t :Tags <CR>
nnoremap <silent> <Leader>T :Tags <C-R><C-W><CR>
nnoremap <silent> <Leader>s :BTags <CR>

command! -bang -nargs=* BTags call 
  \ fzf#vim#buffer_tags(<q-args>, 
  \ printf('ctags -f - --sort=no --excmd=number --php-kinds=-v  %s 2> /dev/null', 
  \ fzf#shellescape(expand('%'))), {}, <bang>0)

set viminfo+=!

if !exists('g:PROJECTS')
  let g:PROJECTS = {}
endif

augroup project_discovery
  autocmd!
  autocmd User Fugitive let g:PROJECTS[fnamemodify(fugitive#repo().dir(), ':h')] = 1
augroup END

command! -complete=customlist,s:project_complete -nargs=1 Project cd <args>

function! s:project_complete(lead, cmdline, _) abort
  let results = keys(get(g:, 'PROJECTS', {}))

  " use projectionist if available
  if exists('*projectionist#completion_filter')
    return projectionist#completion_filter(results, a:lead, '/')
  endif

  " fallback to cheap fuzzy matching
  let regex = substitute(a:lead, '.', '[&].*', 'g')
  return filter(results, 'v:val =~ regex')
endfunction

" vim: ts=2:sw=2:et
