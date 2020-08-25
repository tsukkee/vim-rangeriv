scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let s:basedir = fnamemodify(expand('<sfile>'), ':p:h:h')

function! s:rangeriv_eval_conf(key) abort
    return 'eval print(''\033]51;["call","TapiRangeriv_handler",["' . a:key . '","'' + fm.thisfile.path + ''"]]\x07'')'
endfunction

function! rangeriv#start(startdir)
    " get configurations
    let s:rangeriv_map = get(g:, 'rangeriv_map', {})
    let s:rangeriv_opener = get(g:, 'rangeriv_opener', 'edit')
    let s:rangeriv_rows = get(g:, 'rangeriv_rows', 12)

    " use existing one
    if exists('t:ranger')
        let winnr = bufwinnr(t:ranger)
        if winnr > -1
            " focus to that
            execute "normal!" winnr "\<C-w>\<C-w>"
        else
            " show again
            execute "topleft" t:ranger "sbuffer"
            execute "resize" s:rangeriv_rows
            setlocal winfixheight
        endif
        return
    endif

    " create new one
    let configs = []
    let temp_conf = tempname()
    for [key, val] in items(s:rangeriv_map)
        call add(configs, 'map ' . key . ' ' . s:rangeriv_eval_conf(key))
    endfor
    call writefile(configs, temp_conf)

    let startdir = isdirectory(a:startdir) ? a:startdir : fnamemodify(a:startdir, ':h')

    let t:ranger = term_start(
    \   'ranger --cmd="source ' . temp_conf . '" ' . startdir,
    \   {
    \       'env': {'EDITOR': s:basedir . '/scripts/rangeriv.py'},
    \       'term_api': 'TapiRangeriv_',
    \       'term_name': '[rangeriv]',
    \       'term_finish': 'close',
    \       'exit_cb': { -> execute('unlet t:ranger') }
    \   }
    \)

    execute "normal! \<C-w>K"
    execute "resize" s:rangeriv_rows
    setlocal winfixheight
endfunction

function! TapiRangeriv_handler(bufnum, args) abort
    let [key, path] = a:args

    if empty(key)
        " called from $EDITOR
        let w = winnr('#')
        execute "normal!" w "\<C-w>\<C-w>"
        execute s:rangeriv_opener path
        return
    endif

    let dir = isdirectory(path) ? path : fnamemodify(path, ':h')

    let command = s:rangeriv_map[key]
    let command = substitute(command, '<<file>>', fnameescape(path), 'g')
    let command = substitute(command, '<<dir>>', fnameescape(dir), 'g')
    execute command
endfunction

let &cpo = s:save_cpo
