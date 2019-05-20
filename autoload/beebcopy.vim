" I can't remember the format of the list returned by getcurpos()
let s:line = 1
let s:column = 2

function! beebcopy#copy()
  if !exists('b:position')
    echohl WarningMsg
    echom 'Not in Beeb Copy Mode'
    echohl None
    execute "normal! \<Esc>"
  endif

  let copy_char = getline(b:position[s:line])[b:position[s:column] - 1]
  call beebcopy#move('right')
  return copy_char
endfunction

function! beebcopy#exit_copy_mode()
  if exists('b:position')
    unlet b:position
    iunmap <buffer> <CR>
  endif
  if exists('b:matchid')
    call matchdelete(b:matchid)
    unlet b:matchid
  endif
  return ''
endfunction

function! beebcopy#move(dir) abort
  " FIXME: Fix multibyte chars like in café.
  if !exists('b:position')
    let b:position = getcurpos()
    inoremap <buffer> <silent> <expr> <CR> beebcopy#exit_copy_mode()
  endif
  
  if a:dir ==# 'left'
    let b:position[s:column] -= 1
  elseif a:dir ==# 'right'
    let b:position[s:column] += 1
  elseif a:dir ==# 'up'
    let b:position[s:line] -= 1
  elseif a:dir ==# 'down'
    let b:position[s:line] += 1
  endif

  if exists('b:matchid')
    call matchdelete(b:matchid)
  endif

  execute 'let b:matchid = matchadd("BeebCopy",  "\\%'.b:position[s:line].'l\\%'.b:position[s:column].'c")'
  
  return ''
endfunction

hi link BeebCopy Visual
