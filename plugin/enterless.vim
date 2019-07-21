if exists('g:loaded_enterless') || &cp || version < 700 || &cpo =~# 'C'
  finish
endif
let g:loaded_enterless = 1

command! -bar -nargs=? -complete=dir Enterless call enterless#open(<q-args>)

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
    if exists('g:enterless_hide_hidden') && g:enterless_hide_hidden
        if a:char == '.' && b:prevsearch == ''
            let g:_show_hidden = 1
            Enterless %
            let g:_show_hidden = 0
        endif
    endif

    let s:ignorecase = exists('g:enterless_ignorecase') && g:enterless_ignorecase ? '\c' : ''

    let s:n_path = len(expand("%"))+1
    let s:prevsearch_stripped = b:prevsearch.a:char
    let s:char = a:char == '/' ? '\/' : a:char
    let s:char = s:char == '.' ? '\.' : s:char

    call s:clear_search()
    exec "syntax match EnterlessSearch '".s:ignorecase.'\%'.s:n_path.'c'.b:prevsearch.s:char."'"

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
        return
    endtry

    let s:count = s:getcount()

    if s:count == 1 && (!exists('g:enterless_autoenter') || g:enterless_autoenter)
        call enterless#open("edit", 0)
        return

    else
        let s:yank1 = getreg('"')
        try
            let s:yank2 = getreg('*')
        endtry
        normal! my0y$
        let s:baseline = exists('g:enterless_ignorecase') && g:enterless_ignorecase ? tolower(getreg('"')) : getreg('"')

        for s:row in range(line(".")+1, line(".")+s:count-1)

            normal! j0y$
            let s:proposal = tolower(getreg('"'))

            if len(s:baseline) < len(s:proposal)
                let s:proposal = s:proposal[:len(s:baseline)-1]
            endif

            while s:baseline[:len(s:proposal)-1] != s:proposal
                let s:proposal = s:proposal[:-2]
            endwhile
            let s:baseline = s:proposal
        endfor
        normal! 'y
        let s:baseline = substitute(s:baseline, '/', '\\/', 'g')

        if s:baseline != tolower(s:path.s:prevsearch_stripped)
            let b:prevsearch = s:baseline[len(s:path):]
            echo s:baseline[len(s:path):]
            exec 'syntax match EnterlessSearch "'.s:ignorecase.'\%'.s:n_path.'c'.b:prevsearch.'"'
        endif
        call setreg('"', s:yank1)
        try
            call setreg('*', s:yank2)
        endtry
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
  let b:prevsearch=""
  call s:clear_search()
endfunction

function! enterless#open(...) range abort
    if exists('g:enterless_hide_hidden') && g:enterless_hide_hidden &&
                \(!exists('g:_show_hidden') || (exists('g:_show_hidden') && !g:_show_hidden))
        autocmd! FileType dirvish silent! keeppatterns g@\v/\.[^\/]+/?$@d
    else
        autocmd! FileType dirvish
    endif
    let s:yank1 = getreg('"')
    try
        let s:yank2 = getreg('*')
    endtry
    let g:dirvish_mode=':sort i'
    if a:0 == 1
        call dirvish#open(a:1)
    elseif a:0 == 2
        call dirvish#open(a:1, a:2)
    endif
    if isdirectory(expand("%"))
        exec 'lcd '.expand("%")
        call enterless#clear()
    endif
    call setreg('"', s:yank1)
    try
        call setreg('*', s:yank2)
    endtry
endfunction

function! enterless#quit()
    exec "normal \<plug>(dirvish_quit)"
    if &filetype == "dirvish"
        enew
    endif
endfunction
