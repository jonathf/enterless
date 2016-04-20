let s:nowait = (v:version > 703 ? '<nowait>' : '')

let b:prevsearch = ""
let s:lower = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
            \"n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
let s:upper = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
            \"N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
let s:digits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
let s:special = ["_", "-", ".", "/"]


for s:char in s:lower+s:upper+s:digits+s:special
    exec 'nmap <nowait><buffer><silent> <plug>(enterless_'.s:char.') :<C-U>.call enterless#forward('."'".s:char."'".')<cr>'
endfor

nnoremap <nowait><buffer><silent> <Plug>(enterless_quit) :<C-U>.call enterless#quit()<cr>
nnoremap <nowait><buffer><silent> <plug>(enterless_back) :<C-U>.call enterless#backwards()<CR>
nnoremap <nowait><buffer><silent> <plug>(enterless_open) :<C-U>.call enterless#open("edit", 0)<CR>
nnoremap <nowait><buffer><silent> <plug>(enterless_reload) :Enterless %<CR>

nnoremap <nowait><buffer><silent> <plug>(enterless_deletefile) :<C-U>.call enterless#deletefile()<CR>
nnoremap <nowait><buffer><silent> <plug>(enterless_renamefile) :<C-U>.call enterless#renamefile()<CR>
nnoremap <nowait><buffer><silent> <plug>(enterless_executescript) :<C-U>.call enterless#executescript()<CR>
nnoremap <nowait><buffer><silent> <plug>(enterless_createfolder) :<C-U>.call enterless#createfolder()<CR>


let s:bind = []
if get(g:, 'enterless_bindn_lower', 1)
    let s:bind = s:bind+s:lower
endif
if get(g:, 'enterless_bindn_upper', 0)
    let s:bind = s:bind+s:upper
endif
if get(g:, 'enterless_bindn_digits', 0)
    let s:bind = s:bind+s:digits
endif
if get(g:, 'enterless_bindn_special', 1)
    let s:bind = s:bind+s:special
endif
for s:char in s:bind
    exec 'nmap <nowait><buffer><silent> '.s:char.' <plug>(enterless_'.s:char.')'
endfor

let s:bind = []
if get(g:, 'enterless_bindi_lower', 0)
    let s:bind = s:bind+s:lower
endif
if get(g:, 'enterless_bindi_upper', 0)
    let s:bind = s:bind+s:upper
endif
if get(g:, 'enterless_bindi_digits', 0)
    let s:bind = s:bind+s:digits
endif
if get(g:, 'enterless_bindi_special', 0)
    let s:bind = s:bind+s:special
endif
for s:char in s:bind
    exec 'imap <nowait><buffer><silent> '.s:char.' <esc><plug>(enterless_'.s:char.')'
endfor

if !get(g:, 'enterless_no_default_mapping', 0)

    nmap <nowait><buffer><silent> <f12> <Plug>(enterless_quit)
    nmap <nowait><buffer><silent> <cr> <plug>(enterless_open)
    nmap <nowait><buffer><silent> <bs> <plug>(enterless_back)
    nmap <nowait><buffer><silent> <f2> <plug>(enterless_reload)

    nmap <buffer><nowait><silent> <c-d> <plug>(enterless_deletefile)
    nmap <buffer><nowait><silent> <c-r> <plug>(enterless_renamefile)
    nmap <buffer><nowait><silent> <c-e> <plug>(enterless_executescript)
    nmap <buffer><nowait><silent> <c-f> <plug>(enterless_createfolder)
endif
