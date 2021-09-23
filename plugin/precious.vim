scriptencoding utf-8
if exists('g:loaded_precious')
  finish
endif
let g:loaded_precious = 1

let s:save_cpo = &cpo
set cpo&vim


let g:precious_enable_switchers = get(g:, "precious_enable_switchers", {})


let g:precious_enable_switch_CursorMoved
\	= get(g:, "precious_enable_switch_CursorMoved", {})

let g:precious_enable_switch_CursorMoved_i
\	= get(g:, "precious_enable_switch_CursorMoved_i", {})

let g:precious_enable_switch_CursorHold
\	= get(g:, "precious_enable_switch_CursorHold", {})

let g:precious_use_timer = get(g:, "precious_use_timer", 0)


function! s:is_enable_switch_CursorMoved(filetype)
  return precious#switch_def(g:precious_enable_switch_CursorMoved, a:filetype, 1)
endfunction


function! s:is_enable_switch_CursorMoved_i(filetype)
	return precious#switch_def(g:precious_enable_switch_CursorMoved_i, a:filetype, 1)
endfunction


function! s:is_enable_switch_CursorHold(filetype)
	return precious#switch_def(g:precious_enable_switch_CursorHold, a:filetype, 1)
endfunction

let s:timer_id = -1
let s:saved_pos = getpos('.')[1:2]

function! s:callback(timer_id) abort
  let cur_pos = getpos('.')[1:2]
  let saved_pos = s:saved_pos
  let s:saved_pos = cur_pos

  if saved_pos != cur_pos
    return
  else
    call precious#autocmd_switch(precious#context_filetype())
  endif
endfunction

function! s:set_timer() abort
  if s:timer_id != -1
    call s:stop_timer()
  endif
  let s:timer_id =
        \ timer_start(1000,
        \             function('s:callback'),
        \             {'repeat':-1}
        \ )
endfunction

function! s:stop_timer() abort
  call timer_stop(s:timer_id)
  let s:timer_id = -1
endfunction

if g:precious_use_timer == 0
augroup precious-augroup
	autocmd!
	autocmd FileType * call precious#set_base_filetype(&filetype)

	autocmd CursorMoved *
\		if s:is_enable_switch_CursorMoved(precious#base_filetype())
\		&& get(b:, "precious_switch_lock", 0) == 0
\|			PreciousSwitchAutcmd
\|		endif

	autocmd CursorMovedI *
\		if s:is_enable_switch_CursorMoved_i(precious#base_filetype())
\		&& get(b:, "precious_switch_lock", 0) == 0
\|			PreciousSwitchAutcmd
\|		endif

	autocmd CursorHold *
\		if s:is_enable_switch_CursorHold(precious#base_filetype())
\		&& get(b:, "precious_switch_lock", 0) == 0
\|			PreciousSwitchAutcmd
\|		endif

	autocmd BufEnter * PreciousSwitchAutcmd
augroup END
else
augroup precious-timer-augroup
	autocmd!
	autocmd FileType * call precious#set_base_filetype(&filetype)

	autocmd BufEnter,BufWinEnter * call <SID>set_timer()
	autocmd BufLeave,BufWinLeave * call <SID>stop_timer()
augroup END
endif


command! -bar -nargs=? -complete=filetype
\	PreciousSwitch
\	call precious#switch(empty(<q-args>) ? precious#context_filetype() : <q-args>)

command! -bar
\	PreciousReset
\	call precious#switch(precious#base_filetype())


command! -nargs=1 PreciousSetContextLocal
\	call precious#contextlocal(<q-args>)


command! -bar -nargs=? -complete=filetype
\	PreciousSwitchAutcmd
\	call precious#autocmd_switch(empty(<q-args>) ? precious#context_filetype() : <q-args>)


command! -bar PreciousSwitchLock
\	let b:precious_switch_lock = 1
\|	PreciousReset

command! -bar PreciousSwitchUnlock
\	let b:precious_switch_lock = 0
\|	PreciousSwitch


" textobj
try
	call textobj#user#plugin('precious', {
\     '-': {
\       'select-i': 'icx',
\     '*select-i-function*': 'textobj#precious#select_i_forward',
\     },
\   })
catch
endtry


" quickrun.vim operator
nnoremap <silent> <Plug>(precious-quickrun-op)
\	:<C-u>set operatorfunc=precious#quickrun_operator<CR>g@


let &cpo = s:save_cpo
unlet s:save_cpo
