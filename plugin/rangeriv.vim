scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

command! -complete=dir -nargs=? Rangeriv call rangeriv#start(<q-args>)
" command! -complete=dir -nargs=? RangerivPopup ...

command! RangerivClose
\   if exists('t:rangeriv_buffer')
\|      execute "normal!" bufwinnr(t:rangeriv_buffer) . "\<C-w>c"
\|  endif

let &cpo = s:save_cpo
