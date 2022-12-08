" VIM configuration file by Vadim Fint <mocksoul@gmail.com>
" vim: fdm=marker

" Tune runtimepath {{{
let &runtimepath = '~/.config/vim' . ',' . &runtimepath
" }}}

" Basic options {{{
filetype plugin indent on
set nocompatible                 " git rid of awful vi-compat mode
set autoread
set autowrite
set backspace=indent,eol,start
set encoding=utf-8
set hidden                       " allow buffers to have changes and be hidden
set history=10000
set laststatus=2
set linebreak
set list
set listchars=tab:»\ ,trail:·,nbsp:·,extends:#,precedes:#
set matchtime=3
set modeline
set modelines=3
set nobackup                     " dont want backups anymore
set nolazyredraw                   " do not redraw while running macros (much faster)
set nostartofline                " try to preserve cursor pos during PgUp/PgDn
set noswapfile                   " swap file is not needed as well
set nowritebackup                " dont want backups anymore
set number relativenumber        " show line numbers by default
set pastetoggle=<F6>
set ruler                        " always show
set shiftround
set showbreak=~
set showcmd
set showmode
set signcolumn=number            " always show sign col
set foldcolumn=auto:3            " up to 3 folds
set splitbelow
set splitright
set timeoutlen=1000
set title
set ttimeoutlen=10
set ttyfast
set undofile                     " persistent undo is better than backups!
set undoreload=10000             " save undo then reloading file (so we can undo reload), only if <10000 chars
set visualbell
set viewoptions=cursor,folds
set mouse=                       " disable mouse completely
"set mousemodel=extend            " extend selection by right mouse
" Make and set undo, backup and swap directories {{{
let s:mdirs = ['~/.cache/vim/undo', '~/.cache/vim/backup', '~/.cache/vim/swap']
for dir in s:mdirs
    if !isdirectory(expand(dir))
        call mkdir(expand(dir), 'p')
    endif
endfor
exec 'set undodir=' . s:mdirs[0]
exec 'set backupdir=' . s:mdirs[1]
exec 'set directory=' . s:mdirs[2]
" Make and set undo, backup and swap directories }}}

" ! - store global vars
" ' - maxnumber of previously edited files
" < - max lines saved in each register
" f - how much marks to save for each file (marks 0-9 and A-Z)
" s - elims more than this in kb not saved
" h - disable effect of hlsearch upon loading
set shada=!,'500,<100,f0,s10,h
set complete=.,w,b,u,t
set completeopt=longest,menuone,preview

set synmaxcol=400                " dont try to highlight lines longer than 400 chars

au VimResized * :wincmd =        " resize panes if window was resized

" Ensure we return to prev line then opening
" even if it could be folded
augroup line_return
    au!
    au BufReadPost *
        \ if line("'\"") > 0 && line("'\"") < line("$") |
        \    execute 'normal! g`"zvzz' |
        \ endif
augroup END

augroup number_toggle
    au!
    au BufEnter,FocusGained,InsertLeave,WinEnter * if &nu && mode() != "i" | set nu rnu   | endif
    au BufLeave,FocusLost,InsertEnter,WinLeave   * if &nu                  | set nu nornu | endif
augroup END

augroup filetypedetect
    au BufNewFile,BufRead *.tjp,*.tji               setf tjp
augroup END
au! Syntax tjp          so ~/.vim/syntax/tjp.vim

" Allow to suspend VIM in insert mode
imap <c-z> <c-o><c-z>

" NetRW settings
let g:netrw_list_hide = '\.py[co]$'

let g:python3_host_prog = '/usr/bin/python3'
" Basic options }}}

" Wildmenu completion {{{
set wildmenu
set wildmode=list:longest,full

set wildignore+=.hg,.git,.svn                    " version control
set wildignore+=*.aux,*.out,*.toc                " latex intermediate files
set wildignore+=*.jpg,*.bmp,*.gif,*.png,*.jpeg   " binary images
set wildignore+=*.o,*.obj,*.exe,*.dll,*.manifest " compiled object files
set wildignore+=*.spl                            " compiled spelling word lists
set wildignore+=*.sw?                            " vim swap files
set wildignore+=*.DS_Store                       " OSX bullshit

set wildignore+=*.luac                           " lua byte code

set wildignore+=migrations                       " django migrations
set wildignore+=*.pyc                            " python byte code

set wildignore+=*.orig                           " merge resolution files
" Wildmenu completion }}}

" Tabs, spaces, wrapping, indent {{{
set tabstop=8
set shiftwidth=4
set softtabstop=4
set expandtab
set smarttab
set nowrap
set textwidth=120
set formatoptions=rqln
set colorcolumn=+1
set autoindent
set smartindent
set copyindent
set scrolloff=7                     " keep 7 lines (top/bottom) for scope
set sidescrolloff=10                " keep 10 lines at the size
set virtualedit=block,onemore       " allow to past EOL in Visual block mode
" Tabs, spaces, wrapping, indent }}}

" Leader keys and other mappings {{{
let mapleader = "\\"
let maplocalleader = "`"


" Sort lines
nnoremap <leader>s vip:!sort<cr>
vnoremap <leader>s :!sort<cr>

" Toggle line numbers and switching to relative
nnoremap <leader>n :setlocal number!<cr>
nnoremap <leader>N :setlocal relativenumber<cr>

" Easier sudo write
function! SudoWrite()
    exec "w !sudo tee %>/dev/null"
endfunction
command! -nargs=0 SudoWrite :call SudoWrite()
"cnoremap w!! w !sudo tee % >/dev/null

" Unfuck my screen
nnoremap <leader>rd :syntax sync fromstart<cr>:redraw!<cr>

" Dont search whole word instantly
"xnoremap # y?\V<C-R>"<CR>
"nnoremap <silent> # :let @/ = '\<' . expand('<cword>') . '\>' <bar> set hls <cr>:call histadd('/', @/)<cr>wb

lua <<EOF
function smartqsearch()
    local search = '\\<' .. vim.fn.expand('<cword>') .. '\\>'
    if vim.fn.getreg('/') ~= search then
        vim.fn.setreg('/', search)
        vim.api.nvim_call_function('histadd', { '/', search })
        local ret = vim.api.nvim_call_function('winsaveview', {})
        local cnt = vim.api.nvim_call_function('searchcount', { { recompute = 1 } }).total

        if cnt > 1 then
            vim.cmd('normal nN')
        elseif cnt == 1 then
            vim.cmd('normal n')
        end

        -- we want to put cursor to start of search word
        -- thus we dont want to restore col here
        ret.col = nil
        vim.api.nvim_call_function('winrestview', { ret })
    else
        local cnt = vim.api.nvim_call_function('searchcount', { { recompute = 1 } }).total
        -- if we are already on search word -- center it on screen
        if cnt > 1 then
            vim.cmd('normal nN')
        elseif cnt == 1 then
            vim.cmd('normal n')
        end
    end

    vim.opt.hlsearch = true
    vim.api.nvim_call_function('HighlightMatchUnderCursor#matchadd', {})
end
vim.keymap.set('n', '#', smartqsearch, { noremap = true, silent = true })
EOF

" y?\V<C-R>"<CR>
" y/\V<C-R>"<CR>

" Stop highlighting
noremap <silent> <leader><space> :noh<cr>:call clearmatches()<cr>

" Search always in the middle of screen
cnoremap <expr> <CR> getcmdtype() =~ '[/?]' ? '<CR>zvzz' : '<CR>'
noremap n nzvzz
noremap N Nzvzz

" < or > will let you indent/dedent selected lines
vnoremap < <gv
vnoremap > >gv

" <c-s> to write current buffer
noremap <C-s> :w<CR>
imap <C-s> <C-o><C-s>

" big Q to macros
map      q      <nop>
noremap  Q      q

" Q to quit
map      <C-q>  :q<CR>
map      <A-q>  :qa<CR>
imap     <C-q>  <C-o><C-q>
imap     <A-q>  <C-o><A-q>

" Window splitting
noremap  <C-x>         :sp<cr>
noremap  <C-y>         :vs<cr>
imap     <C-x>         <C-o><C-x>
imap     <C-y>         <C-o><C-y>
map      <A-PageDown>  :bnext<CR>
map      <A-PageUp>    :bprev<CR>
map      <A-Left>      <C-w><Left>
map      <A-Right>     <C-w><Right>
map      <A-Down>      <C-w><Down>
map      <A-Up>        <C-w><Up>
imap     <A-PageDown>  <C-o><A-PageDown>
imap     <A-PageUp>    <C-o><A-PageUp>
imap     <A-Left>      <C-o><A-Left>
imap     <A-Right>     <C-o><A-Right>
imap     <A-Down>      <C-o><A-Down>
imap     <A-Up>        <C-o><A-Up>

" Scroll up/down by 4 line using Ctrl-Up/Down (Ctrl-Shift-Up/Down)


"map      mod           key                     mapping
noremap   <silent>  <C-S-A-Up>    <C-y>
noremap   <silent>  <C-S-Up>      3<C-y>
map       <silent>  <C-Up>        <C-S-Up>3<Up>
inoremap  <silent>  <C-S-Up>      <C-o>3<C-y>
imap      <silent>  <C-Up>        <C-S-Up><C-o>3<Up>
noremap   <silent>  <C-S-A-Down>  <C-e>
noremap   <silent>  <C-S-Down>    3<C-e>
map       <silent>  <C-Down>      <C-S-Down>3<Down>
inoremap  <silent>  <C-S-Down>    <C-o>3<C-e>
imap      <silent>  <C-Down>      <C-S-Down><C-o>3<Down>
noremap             <Backspace>   <Nop>
noremap             <Enter>       <Nop>
noremap             <Space>       <Nop>

au FileType qf noremap <buffer> <Enter> <Enter>


" Make vim to scroll by visible lines, not by physical (while wrapping)
noremap j gj
noremap k gk

" Page up/dn half of page instead of full
noremap <PageUp> 15<C-u>
noremap <PageDown> 15<C-d>
imap <PageUp> <c-o><PageUp>
imap <PageDown> <c-o><PageDown>

" SuperTab
lua <<EOF
function supertab()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local pline = vim.api.nvim_buf_get_lines(0, row - 2, row - 1, true)[1]

    -- if pline:len() > col then
    --     leading =
    print(pline:len())
    return ''
end
vim.keymap.set({ 'i' }, '<S-Tab>', supertab, { expr = true })
EOF
" Leader keys and other mappings }}}

" Color scheme and appearence{{{
set background=dark
set t_Co=256
set numberwidth=5                " we have files with 9999 lines? Yes! )
set cmdheight=1                  " commandbar height
"set statusline=%f%m%r%w\ %y\ [POS=%04l,%04v][%p%%]\ [lines=%L]
set showmatch
set matchtime=5
set cursorline
set fillchars=eob:\ ,diff:\ ,fold:\ ,foldclose:+,foldopen:-
syntax on
color gentooish

" Note for colors:
" 232 (near-black) has more priority than just "black", thus we are
" using it here to force colors (or syntax highlight will override sometimes)

"           Generic
highlight   Normal                    cterm=none     ctermfg=249        ctermbg=none
highlight   LineNr                    cterm=none     ctermfg=242        ctermbg=234
highlight   CursorLine                cterm=none                        ctermbg=black
highlight   CursorLineNr              cterm=none     ctermfg=242        ctermbg=black
highlight   ColorColumn               cterm=none     ctermfg=red        ctermbg=234
highlight   VertSplit                 cterm=none     ctermfg=232        ctermbg=none
highlight   Folded                    cterm=none     ctermfg=136        ctermbg=none
highlight   SignColumn                cterm=none     ctermbg=none
highlight   Search                    cterm=none     ctermfg=232        ctermbg=131
highlight   IncSearch                 cterm=none     ctermfg=232        ctermbg=226

highlight   FoldColumn                cterm=none     ctermbg=233        ctermfg=238
"           Regular-patches
highlight   diffAdded                 cterm=none     ctermbg=none       ctermfg=darkgreen
highlight   diffRemoved               cterm=none     ctermbg=none       ctermfg=darkred

"           diff-mode
highlight   DiffText                  cterm=none     ctermbg=219        ctermfg=232
"highlight  DiffText                  cterm=reverse  ctermbg=none       ctermfg=none
highlight   DiffAdd                   cterm=none     ctermbg=22
highlight   DiffDelete                cterm=none     ctermbg=124
highlight   DiffChange                cterm=none     ctermbg=53

"           NvimTree
highlight   NvimTreeFolderName        cterm=none     ctermfg=blue
highlight   NvimTreeOpenedFolderName  cterm=none     ctermfg=blue
highlight   NvimTreeSymlink           cterm=none     ctermfg=cyan
highlight   NvimTreeExecFile          cterm=none     ctermfg=green
highlight   NvimTreeOpenedFile        cterm=none     ctermfg=yellow

" if &diff

" if has('nvim')
"     highlight ActiveWindow ctermbg=none
"     highlight InactiveWindow ctermbg=232
"     set winhighlight=Normal:ActiveWindow,NormalNC:InactiveWindow
" endif

" Highlight VCS merge conflict markers
match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'

" Highlight current line only in active pane
augroup cline
au!
au WinLeave * set nocursorline
au WinEnter * if !&diff | set cursorline | endif
augroup END

augroup fastescape
au!
au InsertEnter * set timeoutlen=0
au InsertLeave * set timeoutlen=1000
augroup END

highlight ScrollView ctermbg=232
" Color scheme }}}

" Searching {{{
set ignorecase
set smartcase
set hlsearch
set incsearch
" Searching }}}

" Language conf {{{
set keymap=russian-jcukenwin
set iminsert=0
set imsearch=0
"set imcmdline=0  # not supported in vim >= 8.1 ?
map <C-S-F11> i<C-^><Esc>
imap <C-S-F11> <C-^>

set langmap=ёйцукенгшщзхъфывапролджэячсмитьбю;`qwertyuiop[]asdfghjkl;'zxcvbnm\\,\.
" Language config }}}

" Copy/Paste {{{

" yank from curpos to eol
map Y y$

" Clipboard tricks {{{
" Basically we want:
" 1. Selected in VIM == selected in any x11 app (goes to X11 selection buffer)
" 2. Copied in VIM == copied in any x11 app (goes to X11 clipboard)
" 3. Paste by default from x11 clipboard
" 4. Paste from x11 selection by <leader>[p|P]
set clipboard=
if has('unnamedplus')
    " if something selected -- put into X selection buffer
    if ! has('nvim')
        set clipboard+=autoselect
    endif

    " if we can, use '+' register (X clipboard) by default
    set clipboard+=unnamedplus
elseif has('unnamed')
    " if we can, use '*' register (X primary selection) by default
    set clipboard+=unnamed
endif

" free tilda
map ~ <nop>

" Allow to paste from x11 selection
noremap <leader>p "*p
noremap <leader>P "*P
" Clipboard tricks }}}

if ! has('nvim')
    set clipboard+=html
    set clipboard+=exclude:cons\\\\|linux
endif

" Delete key copies to blackhole register
noremap <Del> "_d
" Copy/Paste }}}

" Plug installation {{{
call plug#begin('~/.local/share/nvim/plugged')

" newstyle plugs {{{
Plug 'junegunn/fzf.vim'
Plug 'nvim-lualine/lualine.nvim'
Plug 'j-hui/fidget.nvim'   " LSP progress bar botright
Plug 'antoinemadec/FixCursorHold.nvim'
let g:cursorhold_updatetime = 500
Plug 'kosayoda/nvim-lightbulb'
Plug 'weilbith/nvim-code-action-menu'
Plug 'williamboman/mason.nvim'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'm-demare/hlargs.nvim'
Plug 'lewis6991/satellite.nvim'
Plug 'nvim-lua/lsp-status.nvim'
Plug 'folke/trouble.nvim'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'                       " complete from buffer words
"Plug 'hrsh7th/cmp-nvim-lsp-signature-help'      " func signatures help
Plug 'ray-x/lsp_signature.nvim'
Plug 'hrsh7th/cmp-path'                         " complete for fs paths
Plug 'hrsh7th/nvim-cmp'                         " main plugin
Plug 'rafamadriz/friendly-snippets'
Plug 'L3MON4D3/LuaSnip'
Plug 'saadparwaiz1/cmp_luasnip'
Plug 'simrat39/symbols-outline.nvim'
Plug 'windwp/nvim-autopairs'
Plug 'folke/lsp-colors.nvim'
Plug 'nvim-lua/plenary.nvim'  " telescope dep
Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.0' }
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }
Plug 'kyazdani42/nvim-tree.lua'
Plug 'kylechui/nvim-surround'
"Plug 'stevearc/qf_helper.nvim'
Plug 'https://gitlab.com/yorickpeterse/nvim-pqf.git'
"Plug 'kevinhwang91/nvim-bqf'
"Plug 'onsails/diaglist.nvim'
"Plug 'wiliamks/nice-reference.nvim'
Plug 'lvimuser/lsp-inlayhints.nvim'

" rust
Plug 'simrat39/rust-tools.nvim'

" }}}
" * symbols outline (aka new tagbar) symbols outline {{{
lua <<EOF
vim.g.symbols_outline = {
highlight_hovered_item = true,
relative_width = false,
width = 40,
show_guides = false,
show_numbers = true,
show_symbol_detail = false,
auto_preview = false,
keymaps = {
    close = {},
},
symbols = {
    Method = {icon='m', hl='TSMethod'},
    Function = {icon='f', hl='TSFunction'},
    Struct = {icon='S', hl='TSType'},
    Interface = {icon='I', hl='TSType'},
    Field = {icon='-', hl='TSField'},
}
}
EOF
hi FocusedSymbol ctermbg=black ctermfg=green

autocmd Filetype Outline set nowrap

" }}}
" * nerd commenter {{{
Plug 'preservim/nerdcommenter'
let g:NERDCreateDefaultMappings = 1

" Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1

" Use compact syntax for prettified multi-line comments
let g:NERDCompactSexyComs = 0

" Align line-wise comment delimiters flush left instead of following code indentation
let g:NERDDefaultAlign = 'left'

" Set a language to use its alternate delimiters by default
let g:NERDAltDelims_java = 1

" Add your own custom formats or override the defaults
let g:NERDCustomDelimiters = { 'c': { 'left': '/**','right': '*/' } }

" Allow commenting and inverting empty lines (useful when commenting a region)
let g:NERDCommentEmptyLines = 1

" Enable trimming of trailing whitespace when uncommenting
let g:NERDTrimTrailingWhitespace = 1

" Enable NERDCommenterToggle to check all selected lines is commented or not
let g:NERDToggleCheckAllLines = 1

nnoremap <silent> <F3> :call nerdcommenter#Comment('n', 'Toggle')<CR>
inoremap <silent> <F3> <C-o>:call nerdcommenter#Comment('n', 'Toggle')<CR>
vnoremap <silent> <F3> :call nerdcommenter#Comment('x', 'Toggle')<CR>

autocmd FileType python let g:NERDSpaceDelims = 0
" }}}
" * python indent, python-syntax, semshi {{{
Plug 'Vimjas/vim-python-pep8-indent'
let g:python_pep8_indent_multiline_string = -2  " indent like regular, -1: use current ind
let g:python_pep8_indent_hang_closing = 0       " do not hang closing brakets for lists, tuples, dicts, etc.

Plug 'vim-python/python-syntax'
let g:python_highlight_all = 1
" let g:python_highlight_string_formatting = 0
" let g:python_highlight_string_format = 0
let g:python_highlight_file_headers_as_comments = 1
let g:python_slow_sync = 1
let g:python_highlight_indent_errors = 1
let g:python_highlight_space_errors = 0
let g:python_highlight_func_calls = 1

Plug 'numirias/semshi'
let g:semshi#mark_selected_nodes = 1
let g:semshi#simplify_markup = v:false
let g:semshi#always_update_all_highlights = v:true
let g:semshi#excluded_hl_groups = []
let g:semshi#no_default_builtin_highlight = v:true
let g:semshi#self_to_attribute = v:true
let g:semshi#error_sign = v:false

augroup ft_python
au!
au FileType python noremap <silent> <Tab> :Semshi goto name next<CR>
au FileType python noremap <silent> <S-Tab> :Semshi goto name prev<CR>
au FileType python noremap <silent> <S-Right> :Semshi goto name next<CR>
au FileType python noremap <silent> <S-Left> :Semshi goto name prev<CR>
au FileType python noremap <silent> <S-Down> :Semshi goto function next<CR>
au FileType python noremap <silent> <S-Up> :Semshi goto function prev<CR>
augroup END

function TuneSemshiHL()
hi SemshiSelected   ctermfg=none ctermbg=236
hi SemshiAttribute  ctermfg=37
hi SemshiSelf       ctermfg=31
"hi SemshiSelf       ctermfg=246
hi SemshiUnresolved ctermfg=227 cterm=none
hi SemshiFree       ctermfg=38 cterm=underline
hi SemshiLocal      ctermfg=74
hi SemshiGlobal     ctermfg=38
hi SemshiImported   ctermfg=214 cterm=none
hi SemshiBuiltin    ctermfg=38
hi Error            ctermbg=none
endfunction

function Rename()
:Semshi rename
endfunction

noremap <silent> <leader>re :Semshi rename<CR>

autocmd FileType python call TuneSemshiHL()
" }}}
" * nvim-lspconfig {{{
Plug 'neovim/nvim-lspconfig'
" }}}
" * vimwiki {{{
Plug 'vimwiki/vimwiki'
nmap <Leader>wtl <Plug>VimwikiTableMoveColumnLeft
nmap <Leader>wtr <Plug>VimwikiTableMoveColumnRight
let g:vimwiki_folding = 'expr'
let g:vimwiki_fold_lists = 1
let g:vimwiki_hl_headers = 0
let g:vimwiki_hl_cb_checked = 1
let g:vimwiki_auto_checkbox = 1
let g:vimwiki_table_mappings = 0
let g:vimwiki_table_auto_fmt = 0
let g:vimwiki_list = [{
\'path': '~/vimwiki/', 'syntax': 'markdown', 'ext': '.md'
\}]
au FileType vimwiki set shiftwidth=2 tabstop=2 softtabstop=2
" }}}
" - taskwiki {{{
"Plug 'tbabej/taskwiki'
"Plug 'powerman/vim-plugin-AnsiEsc'
"Plug 'blindFS/vim-taskwarrior'
"let g:taskwiki_maplocalleader="t"
"let g:taskwiki_disable_concealcursor="yes"
"let g:taskwiki_source_tw_colors=""
"let g:taskwiki_dont_preserve_folds="yes"
" }}}
" * vim-session {{{
Plug 'xolox/vim-misc'
Plug 'xolox/vim-session'
set sessionoptions-=help
set sessionoptions-=blank
set sessionoptions-=options
let g:session_directory = '~/.cache/vim/sessions'
let g:session_persist_globals = []
let g:session_autoload = 0
let g:session_autosave = 0
" call add(g:session_persist_globals, 'g:syntastic_python_checker_prog')
" }}}
" " * vim-diminactive {{{
" Plug 'blueyed/vim-diminactive'
" let g:diminactive_use_colorcolumn = 1
" let g:diminactive_use_syntax = 0
" let g:diminactive_enable_focus = 1
" " }}}
" * vim-airline {{{
"Plug 'vim-airline/vim-airline'
"set noshowmode  " not needed anymore
"let g:airline_powerline_fonts = 0
"let g:airline_symbols_ascii = 0
"let g:airline#parts#ffenc#skip_expected_string='utf-8[unix]'
"let g:airline#extensions#keymap#enabled = 0
"let g:airline_detect_spell = 0
"let g:airline_detect_spelllang = 0
""let g:airline_section_a = '(mode)'
""let g:airline_section_a = '%#__accent_bold#%{airline#util#wrap(airline#parts#mode(),0)}%#__restore__#%{airline#util#append(airline#parts#crypt(),0)}%{airline#util#append(airline#parts#paste(),0)}%{airline#util#append("",0)}%{airline#util#append(airline#parts#spell(),0)}%{airline#util#append("",0)}%{airline#util#append(airline#extensions#xkblayout#status(),0)}%{airline#util#append(airline#parts#iminsert(),0)}'
"" }}}
" * bufexplorer {{{
Plug 'jlanzarotta/bufexplorer'
let g:bufExplorerShowRelativePath = 1
let g:bufExplorerSortBy = "fullpath"
let g:bufExplorerSplitOutPathName = 0
let g:bufExplorerFindActive = 0
noremap <F1> :BufExplorer<cr>
imap <F1> <c-o><F1>
nnoremap <S-F1> <cmd>CodeActionMenu<CR>
inoremap <S-F1> <cmd>CodeActionMenu<CR>

" }}}
" * syntastic {{{
Plug 'vim-syntastic/syntastic'
"let g:syntastic_quiet_messages = {"regex": 'unlambdaxxx' }
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_aggregate_errors = 1  " aggregate errors from all checkers
let g:syntastic_enable_signs = 1
let g:syntastic_auto_loc_list = 2     " close auto, open manually
let g:syntastic_loc_list_height = 10
let g:syntastic_enable_ballons = 0
"let g:syntastic_full_redraws = 0
let g:syntastic_python_checkers = ['flake8', 'python']  " off: py3kwarn pylama pep257 pep8
let g:syntastic_python_python_exec = 'python3'
let g:syntastic_python_flake8_exec = 'flake8'
"let g:syntastic_go_checkers = ['golangci_lint']
"let g:syntastic_go_golangci_lint_fname = shellescape(expand('%:h:p', 1))
""let g:syntastic_go_golangci_lint_fname = '.'
"let g:syntastic_go_golangci_lint_args = "--max-issues-per-linter=0 --max-same-issues=0"
"let g:syntastic_c_include_dirs = ['/home/mocksoul/.platformio/packages/framework-arduinoespressif32/cores/esp32']
let g:syntastic_cpp_include_dirs = ['/home/mocksoul/.platformio/packages/framework-arduinoespressif32/cores/esp32']
highlight Error term=reverse ctermfg=White ctermbg=124 guifg=White guibg=Red
highlight SpellBad term=reverse cterm=bold ctermfg=White ctermbg=88 gui=undercurl guisp=Red
highlight SpellCap term=reverse cterm=undercurl ctermfg=White ctermbg=88 gui=undercurl guisp=Red

" F4 to open Shift-F4 to close
nnoremap <silent> <F4> :TroubleToggle workspace_diagnostics<CR><C-w>=<CR>
inoremap <silent> <F4> <C-o>:TroubleToggle workspace_diagnostics<CR><C-o><C-w>=<CR>
vnoremap <silent> <F4> :TroubleToggle workspace_diagnostics<CR><C-w>=<CR>
"nnoremap <silent> <F4> :Errors<CR><cmd>lua if vim.diagnostic.get(0) ~= nil then vim.diagnostic.setloclist() end<CR>
"inoremap <silent> <F4> <C-o>:Errors<CR>
"vnoremap <silent> <F4> :Errors<CR>
nnoremap <silent> <S-F4> :lclose<CR>:cclose<CR>
inoremap <silent> <S-F4> <C-o>:lclose<CR><C-o>:cclose<CR>
vnoremap <silent> <S-F4> :lclose<CR>:cclose<CR>
" }}}
" * pudb.vim {{{
"Plug 'SkyLeach/pudb.vim'
Plug 'KangOl/vim-pudb'
autocmd filetype python nnoremap <F8> :TogglePudbBreakPoint<CR>
autocmd filetype python inoremap <F8> <ESC>:TogglePudbBreakPoint<CR>a
" }}}
" * klen/nvim-config-local {{{
Plug 'klen/nvim-config-local'
" }}}
" * gundo {{{
Plug 'sjl/gundo.vim'
let g:gundo_prefer_python3 = 1
nnoremap <F5> :GundoToggle<CR>
" }}}
" * NERD Tree {{{
Plug 'preservim/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
let g:NERDChristmasTree = 1
let g:NERDTreeDirArrows = 0
let g:NERDTreeGitStatusShowIgnored = 1 " can have huge performance cost
let g:NERDTreeGitStatusIndicatorMapCustom = {
\ "Modified"  : "mod",
\ "Staged"    : "stg",
\ "Untracked" : "unt",
\ "Renamed"   : "rnm",
\ "Unmerged"  : "unm",
\ "Deleted"   : "del",
\ "Dirty"     : "unt",
\ "Clean"     : "cln",
\ 'Ignored'   : 'ign',
\ "Unknown"   : "unk"
\ }
let g:NERDTreeDirArrowExpandable = '+'
let g:NERDTreeDirArrowCollapsible = '-'
"noremap <F2> :NERDTreeToggle<cr>
noremap <F2> :NvimTreeToggle<CR>

imap <F2> <c-o><F2>
" }}}
" * TagBar {{{
Plug 'majutsushi/tagbar'
"let g:tagbar_ctags_bin = "/opt/local/bin/ctags"
let g:tagbar_autoopen = 0
let g:tagbar_autofocus = 1
let g:tagbar_compact = 0
let g:tagbar_width = 30
let g:tagbar_sort = 0 " order in file
let g:tagbar_autoshowtag = 0
let g:tagbar_iconchars = ['+', '-']
let g:tagbar_left = 0

fun! ActivateWindow(name)
let l:bufid = bufnr(a:name)
let l:winids = win_findbuf(l:bufid)
if len(l:winids) > 0
    " return l:winids[0]
    call win_gotoid(l:winids[0])
endif
return -1
endfun

fun! OutlineWin()
let l:cwin = win_findbuf(bufnr())[0]
let l:outwin = ActivateWindow('OUTLINE')

:SymbolsOutlineOpen

" call win_gotoid(l:outwin)

" if l:outwin != -1
"     " echo l:outwin
"     " call win_gotoid(l:outwin)
" else
"     call win_gotoid(l:cwin)
" endif
endfun

"map <F9> :TagbarOpen -fj<cr>
"map <S-F9> :TagbarClose<cr>
map <F9> :SymbolsOutlineOpen<CR><CMD>call ActivateWindow('OUTLINE')<CR>
"map <F9> <CMD>call OutlineWin()<CR>
map <S-F9> :SymbolsOutlineClose<CR><C-w>=<CR>
imap <F9> <C-o><F9><Esc>
imap <S-F9> <C-o><S-F9>

map == <C-w>=<CR>
" }}}
" * terminus {{{
Plug 'wincent/terminus'
" }}}
" * wakatime {{{
Plug 'wakatime/vim-wakatime'
" }}}
" * vim-go {{{
"Plug 'fatih/vim-go'

""let g:go_fmt_command = 'goimports'
"let g:go_fmt_command = 'yoimports'
""let g:go_fmt_command = 'gopls'
"let g:go_fmt_fail_silently = 1
"
"let g:go_fmt_autosave = 1
"let g:go_imports_autosave = 0
"
"let g:go_highlight_types = 1
"let g:go_highlight_fields = 1
"let g:go_highlight_functions = 1
"let g:go_highlight_function_calls = 1
"let g:go_highlight_function_parameters = 1
"let g:go_highlight_operators = 1
"let g:go_highlight_extra_types = 1
"let g:go_highlight_build_constraints = 1
"let g:go_highlight_array_whitespace_error = 1
"let g:go_highlight_chan_whitespace_error = 1
"let g:go_highlight_space_tab_error = 1
"let g:go_highlight_trailing_whitespace_error = 1
"let g:go_highlight_generate_tags = 1
"let g:go_highlight_string_spellcheck = 1
"let g:go_highlight_format_strings = 1
"let g:go_highlight_variable_declarations = 1
"let g:go_highlight_variable_assignments = 1
"let g:go_highlight_diagnostic_errors = 1
"let g:go_highlight_diagnostic_warnings = 1
"
"let g:go_metalinter_autosave = 0
"let g:go_metalinter_command = 'golangci-lint'
""let g:go_metalinter_command = 'go vet -vettool /home/mocksoul/.local/bin/yolint'
"" disabled: revive
"let g:go_metalinter_enabled = ['deadcode', 'errcheck', 'gosimple', 'govet', 'ineffassign', 'staticcheck', 'typecheck', 'unused', 'varcheck', 'revive']
""let g:go_metalinter_enabled = ['deadcode', 'errcheck', 'gosimple', 'govet', 'ineffassign', 'staticcheck', 'typecheck', 'unused', 'varcheck']
""let g:go_metalinter_enabled = ['staticcheck']
""let g:go_metalinter_autosave_enabled = ['deadcode', 'errcheck', 'gosimple', 'govet', 'ineffassign', 'staticcheck', 'typecheck', 'unused', 'varcheck']
"let g:go_metalinter_autosave_enabled = g:go_metalinter_enabled
"
"let g:go_highlight_debug = 0
"let g:go_debug_log_output = 'debugger'
"let g:go_debug_address = '127.0.0.1:8181'
"let g:go_debug_windows = {
"            \ 'vars': 'rightbelow 60vnew',
"            \ 'stack': 'botright 20new',
"            \ 'goroutines': 'botright 10new',
"            \ }
"            " \ 'out': 'botright 5new'
"let g:go_debug_substitute_paths = [['/home/mocksoul/workspace/noc/arc/arcadia/', '/home/mocksoul/workspace/arcnoc/arcadia/']]
""let g:go_debug = ['shell-commands', 'lsp']
"let g:go_gopls_enabled = v:false
"let g:go_gopls_local = 'a.yandex-team.ru'
"
""let g:go_gopls_settings = { 'directoryFilters': [ '-', '+/home/mocksoul/golib', '-library', '+library/go' ], 'expandWorkspaceToModule': v:false }
""let g:go_gopls_settings = { 'directoryFilters': [ '-', '+/home/mocksoul/golib', '-library', '-library/go' ], 'expandWorkspaceToModule': v:false }
"let g:go_gopls_settings = {
"            \ 'directoryFilters': [ '-', '+library/go' ],
"            \ 'build.importCacheFilters' : [ '-', '+vendor', '+library/go', '+junk/mocksoul' ],
"            \ 'expandWorkspaceToModule': v:false
"            \ }
"
"let g:go_list_type_commands = {
"            \ 'GoMetaLinter': 'locationlist',
"            \ 'GoMetaLinterAutoSave': 'locationlist'
"            \ }

" }}}
" * vim-highlight-match-under-cursor {{{
Plug 'https://github.com/adamheins/vim-highlight-match-under-cursor'
"let g:HighlightMatchUnderCursor_highlight_args = 'cterm=none ctermbg=yellow ctermfg=none'
let g:HighlightMatchUnderCursor_highlight_link_group = 'IncSearch'
" }}}

call plug#end() " }}}

" Folding {{{
set foldlevelstart=99
set foldmethod=marker
set foldlevel=99

lua <<EOF
function custom_fold_text()
    local foldm = '{' .. '{' .. '{'

    local line = vim.fn.getline(vim.v.foldstart)
    local line = line:gsub('\t', '    ')
    local line = line:gsub(foldm, '')
    local line = line:gsub('^(.-)[{#:%s]*$', '%1')
    -- local line = line:gsub('^(.-)[{:]$', 'R%1R')

    local foldcount = vim.v.foldend - vim.v.foldstart

    local rtext = '(' .. foldcount .. ' lines)'
    local target = 80
    local left = target - line:len() - rtext:len()

    if left > 0 then
        line = line .. string.rep(' ', left) .. rtext
        return line
    end


    -- str:rep('what', 123)

    return line .. ' +++ (' .. foldcount .. ' lines' .. ')'
end
vim.opt.foldtext='v:lua.custom_fold_text()'
EOF

nnoremap <silent> zj :call NextClosedFold('j')<cr>
nnoremap <silent> zk :call NextClosedFold('k')<cr>
nnoremap <silent> <C-PageDown> :call NextClosedFold('j')<cr>
nnoremap <silent> <C-PageUp> :call NextClosedFold('k')<cr>

function! NextClosedFold(dir)
    let cmd = 'norm!z'..a:dir
    let view = winsaveview()
    let [l0, l, open] = [0, view.lnum, 1]
    while l != l0 && open
        exe cmd
        let [l0, l] = [l, line('.')]
        let open = foldclosed(l) < 0
    endwhile
    if open
        call winrestview(view)
    endif
endfunction
" }}}

" TreeSitter config
set foldmethod=expr
set foldexpr=nvim_treesitter#foldexpr()

" Tune diff mode {{{
if &diff
    set nocursorline
    set foldlevel=99
    set foldlevelstart=99
    set nofoldenable

    map  <A-PageUp>    [c
    map  <A-PageDown>  ]c
    map  <S-Up>        [c
    map  <S-Down>      ]c
    map  <S-Left>      dozv]c
    map  <S-Right>     dpzv]c

    augroup diffconf
        au!
        au WinEnter * if &diff |
                    \   call feedkeys('zRgg]c', 't') |
                    \ endif
    augroup END
endif
" }}}

" Tune specific file types {{{
" ReST {{{
augroup ft_rest
    au!
    au FileType rst set textwidth=78 tabstop=3 shiftwidth=3 softtabstop=3
augroup END
" ReST }}}
" Go (golang) {{{
fun! GoFumpt()
    :silent !gofumpt -w %
    :edit
endfun

augroup ft_go
    au!
    au FileType go set tabstop=4 shiftwidth=4 noexpandtab
    au FileType go noremap <C-s> :wa<CR>
    autocmd BufWritePre *.go lua GoOrgImports(1000)
    "autocmd BufWritePost *.go call GoFumpt()
    autocmd BufWritePre *.go lua vim.lsp.buf.format()
augroup END

" Go }}}
" All {{{
autocmd BufWritePre * :%s/\s\+$//e

let g:skipview_files = [
            \ '[BufExplorer]',
            \ 'NERD_tree_1'
            \ ]

function! MakeViewCheck()
    if has('quickfix') && &buftype =~ 'nofile'
        " Buffer is marked as not a file
        return 0
    endif
    if empty(glob(expand('%:p')))
        " File does not exist on disk
        return 0
    endif
    if len($TEMP) && expand('%:p:h') == $TEMP
        " We're in a temp dir
        return 0
    endif
    if len($TMP) && expand('%:p:h') == $TMP
        " Also in temp dir
        return 0
    endif
    if index(g:skipview_files, expand('%')) >= 0
        " File is in skip list
        return 0
    endif
    return 1
endfunction
augroup vimrcAutoView
    autocmd!
    " Autosave & Load Views.
    autocmd BufWritePost,BufLeave,WinLeave ?* if MakeViewCheck() | mkview | endif
    autocmd BufWinEnter ?* if MakeViewCheck() | silent! loadview | endif
augroup end
augroup vimrcUnfuckSyntaxOnSave
    autocmd!
    autocmd BufWritePost ?* :syntax sync fromstart
augroup end

autocmd BufEnter Trouble :stopinsert

augroup vimrcYaml
    " autocmd FileType yaml setl indentkeys-=<:>
    autocmd!
    " autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab indentkeys-=0# indentkeys-=<:>
    autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab indentkeys-=0#
augroup end

au FileType php set sw=4 ts=4 sts=4 noet smarttab autoindent

""" SmartHome (to first char in line)
" function ExtendedHome()
"     let column = col('.')
"     normal! ^
"     " if column == col('.')
"     "     normal! 0
"     " endif
" endfunction
" noremap <silent> <Home> :call ExtendedHome()<CR>
" inoremap <silent> <Home> <C-O>:call ExtendedHome()<CR>
noremap <silent> <Home> ^
inoremap <silent> <Home> <C-o>^

" Tune specific file types }}}
" Fix tmux/xterm keys {{{
if &term =~ '^screen'
    " tmux will send xterm-style keys when xterm-keys is on
    execute "set <xUp>=\e[1;*A"
    execute "set <xDown>=\e[1;*B"
    execute "set <xRight>=\e[1;*C"
    execute "set <xLeft>=\e[1;*D"
    execute "set <PageUp>=\e[5;*~"
    execute "set <PageDown>=\e[6;*~"
endif
" Fix tmux/xterm keys }}}

" backspace conf
" XXX: WTF is this
set whichwrap+=<,>,[,],h,l

lua require('main') -- from .config/vim/lua/main.lua

hi LspInlayHint ctermfg=238

" }}}
