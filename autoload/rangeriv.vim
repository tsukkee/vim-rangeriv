scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let s:basedir = fnamemodify(expand('<sfile>'), ':p:h:h')

function! s:map_cmd(key) abort
    return printf(
    \   'map %s eval -q print(''\033]51;["call","TapiRangeriv_handler",["%s","'' + fm.thisfile.path + ''"]]\x07'')',
    \   a:key, a:key)
endfunction

function! rangeriv#start(startdir) abort
    " get configurations
    let s:rangeriv_map = get(g:, 'rangeriv_map', {})
    let s:rangeriv_opener = get(g:, 'rangeriv_opener', 'edit')
    let s:rangeriv_rows = get(g:, 'rangeriv_rows', 12)
    let s:rangeriv_close_on_vimexit = get(g:, 'rangeriv_close_on_vimexit', v:false)

    " use existing one
    if exists('t:rangeriv_buffer')
        let winnr = bufwinnr(t:rangeriv_buffer)
        if winnr > -1
            " focus to that
            execute "normal!" winnr "\<C-w>\<C-w>"
        else
            " show again
            execute "topleft" t:rangeriv_buffer "sbuffer"
            execute "resize" s:rangeriv_rows
            setlocal winfixheight
        endif
        return
    endif

    " create new one
    let cmds = join(map(items(s:rangeriv_map),
    \   {_, item -> '--cmd="' . escape(s:map_cmd(item[0]), '\\"') . '"'}),
    \   ' ')

    let startdir = isdirectory(a:startdir) ? a:startdir : fnamemodify(a:startdir, ':h')

    let t:rangeriv_buffer = term_start(
    \   'ranger ' . cmds . ' ' . startdir,
    \   {
    \       'env': {'EDITOR': s:basedir . '/scripts/rangeriv.py'},
    \       'term_api': 'TapiRangeriv_',
    \       'term_name': '[rangeriv]',
    \       'term_finish': 'close',
    \       'term_kill': s:rangeriv_close_on_vimexit ? 'term': '',
    \       'norestore': v:true,
    \       'exit_cb': { -> execute('unlet t:rangeriv_buffer') }
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
