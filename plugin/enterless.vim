if exists('g:loaded_enterless') || &cp || version < 700 || &cpo =~# 'C'
  finish
endif
let g:loaded_enterless = 1

command! -bar -nargs=? -complete=dir Enterless call enterless#open(<q-args>)

function! s:isdir(dir)
  return !empty(a:dir) && (isdirectory(a:dir) ||
    \ (!empty($SYSTEMDRIVE) && isdirectory('/'.tolower($SYSTEMDRIVE[0]).a:dir)))
endfunction

if get(g:, 'enterless_hijack_netrw', 1)
  augroup enterless_netrw
    autocmd!
    " nuke netrw brain damage
    autocmd VimEnter * silent! au! FileExplorer *
    autocmd BufEnter * if !exists('b:enterless') && <SID>isdir(expand('%'))
      \ | redraw | echo ''
      \ | exe 'Enterless %' | endif
  augroup END
endif

highlight! link EnterlessPathTail Directory
