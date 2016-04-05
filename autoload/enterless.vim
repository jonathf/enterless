let s:sep = (&shell =~? 'cmd.exe') ? '\' : '/'
let s:noswapfile = (2 == exists(':noswapfile')) ? 'noswapfile' : ''
let s:noau       = 'silent noautocmd keepjumps'

function! s:msg_error(msg) abort
  redraw | echohl ErrorMsg | echomsg 'enterless:' a:msg | echohl None
endfunction

" Normalize slashes for safe use of fnameescape(), isdirectory(). Vim bug #541.
function! s:sl(path) abort
  return tr(a:path, '\', '/')
endfunction

function! s:normalize_dir(dir) abort
  let dir = s:sl(a:dir)
  if !isdirectory(dir)
    "cygwin/MSYS fallback for paths that lack a drive letter.
    let dir = empty($SYSTEMDRIVE) ? dir : '/'.tolower($SYSTEMDRIVE[0]).(dir)
    if !isdirectory(dir)
      call s:msg_error("invalid directory: '".a:dir."'")
      return ''
    endif
  endif
  let dir = substitute(dir, '/\+', '/', 'g') "replace consecutive slashes
  " Always end with separator.
  return (dir[-1:] ==# '/') ? dir : dir.'/'
endfunction

function! s:parent_dir(dir) abort
  if !isdirectory(s:sl(a:dir))
    echoerr 'not a directory:' a:dir
    return
  endif
  return s:normalize_dir(fnamemodify(a:dir, ":p:h:h"))
endfunction

if v:version > 703
function! s:globlist(pat) abort
  return glob(a:pat, 1, 1)
endfunction
else "Vim 7.3 glob() cannot handle filenames containing newlines.
function! s:globlist(pat) abort
  return split(glob(a:pat, 1), "\n")
endfunction
endif

function! s:list_dir(dir) abort
  " Escape for glob().
  let dir_esc = substitute(a:dir,'\V[','[[]','g')
  let paths = s:globlist(dir_esc.'*')
  "Append dot-prefixed files. glob() cannot do both in 1 pass.
  let paths = paths + s:globlist(dir_esc.'.[^.]*')

  if get(g:, 'enterless_relative_paths', 0)
      \ && a:dir != s:parent_dir(getcwd()) "avoid blank CWD
    return sort(map(paths, "fnamemodify(v:val, ':p:.')"))
  else
    return sort(map(paths, "fnamemodify(v:val, ':p')"))
  endif
endfunction

function! s:shdo(l1, l2, cmd)
  let cmd = a:cmd =~# '\V{}' ? a:cmd : (empty(a:cmd)?'{}':(a:cmd.' {}')) "DWIM
  let dir = b:enterless._dir
  let lines = getline(a:l1, a:l2)
  let tmpfile = tempname().(&sh=~?'cmd.exe'?'.bat':(&sh=~'powershell'?'.ps1':'.sh'))

  augroup enterless_shcmd
    autocmd! * <buffer>
    " Refresh after executing the command.
    exe 'autocmd ShellCmdPost * autocmd enterless_shcmd BufEnter,WinEnter <buffer='.bufnr('%')
          \ .'> Enterless %|au! enterless_shcmd * <buffer='.bufnr('%').'>'
  augroup END

  for i in range(0, (a:l2-a:l1))
    let f = substitute(lines[i], escape(s:sep,'\').'$', '', 'g') "trim slash
    let f = 2==exists(':lcd') ? fnamemodify(f, ':t') : lines[i]  "relative
    let lines[i] = substitute(cmd, '\V{}', shellescape(f), 'g')
  endfor
  execute 'split' tmpfile '|' (2==exists(':lcd')?('lcd '.dir):'')
  setlocal nobuflisted
  silent keepmarks keepjumps call setline(1, lines)
  write
  if executable('chmod')
    call system('chmod u+x '.tmpfile)
  endif

  if exists(':terminal')
    nnoremap <buffer><silent> Z! :write<Bar>te %<CR>
  else
    nnoremap <buffer><silent> Z! :write<Bar>!%<CR>
  endif
endfunction

function! s:buf_init() abort
  augroup enterless_buflocal
    autocmd! * <buffer>
    autocmd BufEnter,WinEnter <buffer> call <SID>on_bufenter()

    " BufUnload is fired for :bwipeout/:bdelete/:bunload, _even_ if
    " 'nobuflisted'. BufDelete is _not_ fired if 'nobuflisted'.
    " NOTE: For 'nohidden' we cannot reliably handle :bdelete like this.
    if &hidden
      autocmd BufUnload <buffer> call s:on_bufclosed()
    endif
  augroup END

  setlocal buftype=nofile noswapfile
  setlocal ma

  command! -buffer -range -bar -nargs=* -complete=file Shdo call <SID>shdo(<line1>, <line2>, <q-args>)
endfunction

function! s:on_bufenter() abort
  " Ensure w:enterless for window splits, `:b <nr>`, etc.
  let w:enterless = extend(get(w:, 'enterless', {}), b:enterless, 'keep')

  if empty(getline(1)) && 1 == line('$')
    Enterless %
    return
  endif
  if 0 == &l:cole
    call <sid>win_init()
  endif
endfunction

function! s:save_state(d) abort
  " Remember previous ('original') buffer.
  let a:d.prevbuf = s:buf_isvalid(bufnr('%')) || !exists('w:enterless')
        \ ? 0+bufnr('%') : w:enterless.prevbuf
  if !s:buf_isvalid(a:d.prevbuf)
    "If reached via :edit/:buffer/etc. we cannot get the (former) altbuf.
    let a:d.prevbuf = exists('b:enterless') && s:buf_isvalid(b:enterless.prevbuf)
        \ ? b:enterless.prevbuf : bufnr('#')
  endif

  " Remember alternate buffer.
  let a:d.altbuf = s:buf_isvalid(bufnr('#')) || !exists('w:enterless')
        \ ? 0+bufnr('#') : w:enterless.altbuf
  if exists('b:enterless') && (a:d.altbuf == a:d.prevbuf || !s:buf_isvalid(a:d.altbuf))
    let a:d.altbuf = b:enterless.altbuf
  endif

  " Save window-local settings.
  let w:enterless = extend(get(w:, 'enterless', {}), a:d, 'force')
  let [w:enterless._w_wrap, w:enterless._w_cul] = [&l:wrap, &l:cul]
  if has('conceal') && !exists('b:enterless')
    let [w:enterless._w_cocu, w:enterless._w_cole] = [&l:concealcursor, &l:conceallevel]
  endif
endfunction

function! s:win_init() abort
  let w:enterless = get(w:, 'enterless', copy(b:enterless))
  setlocal nowrap cursorline

  if has('conceal')
    setlocal concealcursor=nvc conceallevel=3
  endif
endfunction

function! s:on_bufclosed() abort
  call s:restore_winlocal_settings()
endfunction

function! s:buf_close() abort
  let d = get(w:, 'enterless', {})
  if empty(d)
    return
  endif

  let [altbuf, prevbuf] = [get(d, 'altbuf', 0), get(d, 'prevbuf', 0)]
  let found_alt = s:try_visit(altbuf)
  if !s:try_visit(prevbuf) && !found_alt
      \ && prevbuf != bufnr('%') && altbuf != bufnr('%')
    bdelete
  endif
endfunction

function! s:restore_winlocal_settings() abort
  if !exists('w:enterless') " can happen during VimLeave, etc.
    return
  endif
  if has('conceal') && has_key(w:enterless, '_w_cocu')
    let [&l:cocu, &l:cole] = [w:enterless._w_cocu, w:enterless._w_cole]
  endif
endfunction

function! s:open_selected(split_cmd, bg, line1, line2) abort
  let curbuf = bufnr('%')
  let [curtab, curwin, wincount] = [tabpagenr(), winnr(), winnr('$')]
  let splitcmd = a:split_cmd

  let paths = getline(a:line1, a:line2)
  for path in paths
    let path = s:sl(path)
    if !isdirectory(path) && !filereadable(path)
      call s:msg_error("invalid (or access denied): ".path)
      continue
    endif

    try
      if isdirectory(path)
        exe (splitcmd ==# 'edit' ? '' : splitcmd.'|') 'Enterless' fnameescape(path)
      else
        exe splitcmd fnameescape(path)
      endif

      " return to previous window after _each_ split, otherwise we get lost.
      if a:bg && splitcmd =~# 'sp' && winnr('$') > wincount
        wincmd p
      endif
    catch /E37:/
      call s:msg_error("E37: No write since last change")
      return
    catch /E36:/
      call s:msg_error(v:exception)
      return
    catch /E325:/
      call s:msg_error("E325: swap file exists")
    endtry
  endfor

  if a:bg "return to enterless buffer
    if a:split_cmd ==# 'tabedit'
      exe 'tabnext' curtab '|' curwin.'wincmd w'
    elseif a:split_cmd ==# 'edit'
      execute 'silent keepalt keepjumps buffer' curbuf
    endif
  elseif !exists('b:enterless') && exists('w:enterless')
    call s:set_altbuf(w:enterless.prevbuf)
  endif
endfunction

function! s:set_altbuf(bnr) abort
  let curbuf = bufnr('%')
  call s:try_visit(a:bnr)
  let noau = bufloaded(curbuf) ? 'noau' : ''
  " Return to the current buffer.
  execute 'silent keepjumps' noau s:noswapfile 'buffer' curbuf
endfunction

function! s:try_visit(bnr) abort
  if a:bnr != bufnr('%') && bufexists(a:bnr)
        \ && empty(getbufvar(a:bnr, 'enterless'))
    " If _previous_ buffer is _not_ loaded (because of 'nohidden'), we must
    " allow autocmds (else no syntax highlighting; #13).
    let noau = bufloaded(a:bnr) ? 'noau' : ''
    execute 'silent keepjumps' noau s:noswapfile 'buffer' a:bnr
    return 1
  endif
  return 0
endfunction

function! s:tab_win_do(tnr, cmd, bname) abort
  exe s:noau 'tabnext' a:tnr
  for wnr in range(1, tabpagewinnr(a:tnr, '$'))
    if a:bname ==# bufname(winbufnr(wnr))
      exe s:noau wnr.'wincmd w'
      exe a:cmd
    endif
  endfor
endfunction

" Performs `cmd` in all windows showing `bname`.
function! s:bufwin_do(cmd, bname) abort
  let [curtab, curwin, curwinalt] = [tabpagenr(), winnr(), winnr('#')]
  for tnr in range(1, tabpagenr('$'))
    let [origwin, origwinalt] = [tabpagewinnr(tnr), tabpagewinnr(tnr, '#')]
    for bnr in tabpagebuflist(tnr)
      if a:bname ==# bufname(bnr) " tab has at least 1 matching window
        call s:tab_win_do(tnr, a:cmd, a:bname)
        exe s:noau origwinalt.'wincmd w|' s:noau origwin.'wincmd w'
        break
      endif
    endfor
  endfor
  exe s:noau 'tabnext '.curtab
  exe s:noau curwinalt.'wincmd w|' s:noau curwin.'wincmd w'
endfunction

function! s:buf_render(dir, lastpath) abort
  let bname = s:sl(bufname('%'))
  let isnew = empty(getline(1))

  if !isdirectory(bname)
    echoerr 'enterless: fatal: buffer name is not a directory:' bufname('%')
    return
  endif

  if !isnew
    call s:bufwin_do('let w:enterless["_view"] = winsaveview()', bname)
  endif

  if v:version > 704 || v:version == 704 && has("patch73")
    setlocal undolevels=-1
  endif
  silent keepmarks keepjumps %delete _
  silent keepmarks keepjumps call setline(1, s:list_dir(a:dir))
  if v:version > 704 || v:version == 704 && has("patch73")
    setlocal undolevels<
  endif

  if !isnew
    call s:bufwin_do('call winrestview(w:enterless["_view"])', bname)
  endif

  if 1 == line('.') && !empty(a:lastpath)
    keepjumps call search('\V\^'.escape(a:lastpath, '\').'\$', 'cw')
  endif
endfunction

function! s:do_open(d, reload) abort
  let d = a:d
  let bnr = bufnr('^' . d._dir . '$')

  let dirname_without_sep = substitute(d._dir, '[\\/]\+$', '', 'g')
  let bnr_nonnormalized = bufnr('^'.dirname_without_sep.'$')
   
  " Vim tends to name the buffer using its reduced path.
  " Examples (Win32 gvim 7.4.618):
  "     ~\AppData\Local\Temp\
  "     ~\AppData\Local\Temp
  "     AppData\Local\Temp\
  "     AppData\Local\Temp
  " Try to find an existing normalized-path name before creating a new one.
  for pat in [':~:.', ':~']
    if -1 != bnr
      break
    endif
    let modified_dirname = fnamemodify(d._dir, pat)
    let modified_dirname_without_sep = substitute(modified_dirname, '[\\/]\+$', '', 'g')
    let bnr = bufnr('^'.modified_dirname.'$')
    if -1 == bnr_nonnormalized
      let bnr_nonnormalized = bufnr('^'.modified_dirname_without_sep.'$')
    endif
  endfor

  try
    if -1 == bnr
      execute 'silent noau keepjumps' s:noswapfile 'edit' fnameescape(d._dir)
    else
      execute 'silent noau keepjumps' s:noswapfile 'buffer' bnr
    endif
  catch /E37:/
    call s:msg_error("E37: No write since last change")
    return
  endtry

  "If the directory is relative to CWD, :edit refuses to create a buffer
  "with the expanded name (it may be _relative_ instead); this will cause
  "problems when the user navigates. Use :file to force the expanded path.
  if bnr_nonnormalized == bufnr('#') || s:sl(bufname('%')) !=# d._dir
    if s:sl(bufname('%')) !=# d._dir
      execute 'silent noau keepjumps '.s:noswapfile.' file ' . fnameescape(d._dir)
    endif

    if bufnr('#') != bufnr('%') && isdirectory(s:sl(bufname('#'))) "Yes, (# == %) is possible.
      bwipeout # "Kill it with fire, it is useless.
    endif
  endif

  if s:sl(bufname('%')) !=# d._dir  "We have a bug or Vim has a regression.
    echoerr 'expected buffer name: "'.d._dir.'" (actual: "'.bufname('%').'")'
    return
  endif

  if &buflisted
    setlocal nobuflisted
  endif

  call s:set_altbuf(d.prevbuf) "in case of :bd, :read#, etc.

  let b:enterless = exists('b:enterless') ? extend(b:enterless, d, 'force') : d

  call s:buf_init()
  call s:win_init()
  if a:reload || (empty(getline(1)) && 1 == line('$'))
    call s:buf_render(b:enterless._dir, get(b:enterless, 'lastpath', ''))
  endif

  setlocal filetype=enterless
endfunction

function! s:buf_isvalid(bnr) abort
  return bufexists(a:bnr) && !isdirectory(s:sl(bufname(a:bnr)))
endfunction

let s:prevcountcache=[[], 0] 
function! s:getcount()
    let key=[@/, b:changedtick]
    if s:prevcountcache[0]==#key
        return s:prevcountcache[1]
    endif
    let s:prevcountcache[0]=key
    let s:prevcountcache[1]=0
    let pos=getpos('.')
    try
        redir => subscount
        silent %s///gne
        redir END
        let result=matchstr(subscount, '\d\+')
        let s:prevcountcache[1]=result
        return result
    finally
        call setpos('.', pos)
    endtry
endfunction

function! enterless#forward(char)

  if exists('g:enterless_hide_hidden') &&
        \g:enterless_hide_hidden

    if a:char == '.' && b:prevsearch == ''
      let g:_show_hidden = 1
      Enterless %
      let g:_show_hidden = 0
    endif
  endif

  let s:ignorecase = exists('g:enterless_ignorecase') &&
        \g:enterless_ignorecase ? '\c' : ''

  let s:n_path = len(expand("%"))+1
  let s:char = a:char == '.' ? '\.' : a:char
  let s:char = s:char == '/' ? '\/' : s:char

  call s:clear_search()
  exec 'syntax match EnterlessSearch "'.s:ignorecase.'\%'.s:n_path.'c'.b:prevsearch.s:char.'"'

  let b:prevsearch = b:prevsearch.s:char

  normal! G$
  setlocal shortmess+=s
  let s:path = substitute(expand("%"), '/', '\\/', 'g')
  let s:path = substitute(s:path, '\.', '\\.', 'g')
  try
    exec '/'.s:ignorecase.s:path.b:prevsearch
  catch
    echo "no such term"
    call enterless#clear()
  endtry

  let s:count = s:getcount()

  if s:count == 1 &&
        \(!exists('g:enterless_autoenter') ||
        \g:enterless_autoenter)
    call enterless#open("edit", 0)
    return
  endif

  normal! my0"yy$
  let s:baseline = exists('g:enterless_ignorecase') &&
        \g:enterless_ignorecase ? tolower(getreg("y")) : getreg("y")

  for s:row in range(line(".")+1, line(".")+s:count-1)

      normal! j0"yy$
      let s:proposal = tolower(getreg("y"))
      
      if len(s:baseline) < len(s:proposal)
          let s:proposal = s:proposal[:len(s:baseline)-1]
      endif

      while s:baseline[:len(s:proposal)-1] != s:proposal
          let s:proposal = s:proposal[:-2]
      endwhile
      let s:baseline = s:proposal
  endfor
  let s:baseline = substitute(s:baseline, '/', '\\/', 'g')

  if s:baseline != tolower(s:path.b:prevsearch)
      let b:prevsearch = s:baseline[len(s:path):]
      echo s:baseline[len(s:path):]
      return
  endif

endfunction



function! enterless#backwards()
  if b:prevsearch != ''
    Enterless %
  else
    Enterless %:p:h:h
  endif
endfunction

function! s:clear_search()
  syntax match EnterlessFolder "[^\/]*[\/]$"
  syntax match EnterlessFile "[^\/]*$"
endfunction

function! enterless#clear()

  if exists('g:enterless_hide_hidden') && g:enterless_hide_hidden &&
        \(!exists('g:_show_hidden') || (exists('g:_show_hidden') && !g:_show_hidden))
    silent! keeppatterns g@\v/\.[^\/]+/?$@d
  endif
  sort i
  let b:prevsearch=""
  call s:clear_search()
endfunction

function! enterless#open(...) range abort
  if &autochdir
    call s:msg_error("'autochdir' is not supported")
    return
  endif

  if a:0 > 1
    call s:open_selected(a:1, a:2, a:firstline, a:lastline)
    return
  endif

  let d = {}
  let d._dir = fnamemodify(s:sl(a:1), ':p')
  "                                       ^resolves to CWD if a:1 is empty

  if filereadable(d._dir) "chop off the filename
    let d._dir = fnamemodify(d._dir, ':p:h')
  endif

  let d._dir = s:normalize_dir(d._dir)
  if '' ==# d._dir " s:normalize_dir() already showed error.
    return
  endif

  let reloading = exists('b:enterless') && d._dir ==# s:normalize_dir(b:enterless._dir)

  " Save lastpath when navigating _up_.
  if exists('b:enterless') && d._dir ==# s:parent_dir(b:enterless._dir)
    let d.lastpath = b:enterless._dir
  endif

  call s:save_state(d)
  call s:do_open(d, reloading)
  call enterless#clear()
endfunction

nnoremap <silent> <Plug>(enterless_quit) :<C-U>call <SID>buf_close()<CR>
