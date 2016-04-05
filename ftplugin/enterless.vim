let s:nowait = (v:version > 703 ? '<nowait>' : '')

let b:prevsearch = ""

nmap <nowait><buffer><silent> <plug>(enterless_open) 0"yy$:exec 'Enterless '.getreg("y")<cr>

nnoremap <nowait><buffer><silent> <plug>(enterless_open) :<C-U>.call enterless#open("edit", 0)<CR>

nmap <nowait><buffer><silent> q <Plug>(enterless_quit)
nmap <nowait><buffer><silent> <cr> <plug>(enterless_open)
