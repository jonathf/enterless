if exists("b:current_syntax")
  finish
endif

let s:sep = (&shell =~? 'cmd.exe') ? '\\' : '\/'

exe 'syntax match EnterlessPathHead ''\v.*'.s:sep.'\ze[^'.s:sep.']+'.s:sep.'?$'' conceal'
exe 'syntax match EnterlessPathTail ''\v[^'.s:sep.']+'.s:sep.'$'''

highlight EnterlessFolder ctermfg=12
highlight EnterlessFile ctermfg=7
highlight EnterlessSearch ctermfg=9

let b:current_syntax = "enterless"
