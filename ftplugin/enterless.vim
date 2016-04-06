let s:nowait = (v:version > 703 ? '<nowait>' : '')

let b:prevsearch = ""
let s:lower = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
            \"n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
let s:upper = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
            \"N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
let s:alpha = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
let s:special = ["_", "-", ".", "/"]


for s:char in s:lower+s:upper+s:alpha+s:special
    exec 'nmap <nowait><buffer><silent> <plug>(enterless_'.s:char.') :<C-U>.call enterless#forward("'.s:char.'")<cr>'
endfor

let s:bindn = ["c"]
" if get(g:, 'enterless_bindn_lower', 1)
"     let s:bindn = s:bindn+s:lower
" endif
" if get(g:, 'enterless_bindn_upper', 0)
"     let s:bindn = s:bindn+s:upper
" endif
" if get(g:, 'enterless_bindn_special', 1)
"     let s:bindn = s:bindn+s:upper
" endif
for s:char in s:bindn
    exec 'nmap <nowait><buffer><silent> '.s:char.'<plug>(enterless_'.s:char.')'
endfor
"
" let s:bindi = []
" if get(g:, 'enterless_bindi_lower', 1)
"     let s:bindi = s:bindi+s:lower
" endif
" if get(g:, 'enterless_bindi_upper', 1)
"     let s:bindi = s:bindi+s:upper
" endif
" if get(g:, 'enterless_bindi_special', 1)
"     let s:bindi = s:bindi+s:upper
" endif
" for s:char in s:bindi
"     exec 'imap <nowait><buffer><silent> '.s:char.'<esc><plug>(enterless_'.s:char.')'
" endfor

nmap <nowait><buffer><silent> <plug>(enterless_open) 0"yy$:exec 'Enterless '.getreg("y")<cr>

nnoremap <nowait><buffer><silent> <plug>(enterless_open) :<C-U>.call enterless#open("edit", 0)<CR>

nmap <nowait><buffer><silent> q <Plug>(enterless_quit)
nmap <nowait><buffer><silent> <cr> <plug>(enterless_open)
