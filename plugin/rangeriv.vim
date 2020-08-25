scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

command! -complete=dir -nargs=? Rangeriv call rangeriv#start(<q-args>)
" command! -complete=dir -nargs=? RangerivPopup ...

let &cpo = s:save_cpo
