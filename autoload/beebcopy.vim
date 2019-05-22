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

  let end_position = copy(b:position)
  while 1
    let end_position[s:column] += 1
    if s:first_character_byte(end_position)
      break
    endif
  endwhile

  " Now end_position points to the first byte of the character after the copy
  " cursor. We want it to point to the last byte of the character under the
  " copy cursor
  let end_position[s:column] -= 1

  let copy_char = getline(b:position[s:line])[b:position[s:column] - 1: end_position[s:column] - 1]
  call beebcopy#move('right')
  return copy_char
endfunction

function! beebcopy#exit_copy_mode()
  if exists('b:position')
    unlet b:position
    if b:mapped_cr
      iunmap <buffer> <CR>
    endif
  endif
  if exists('b:matchid')
    call matchdelete(b:matchid)
    unlet b:matchid
  endif
  autocmd! beebcopy
  return ''
endfunction

function! s:bytes_for_char() abort
  " If the beeb cursor is on a multibyte character and we're moving
  " horizontally, we need to alter s:column by more than one in order to move
  " the cursor. We could do this by checking the `virtcol` of the cursor, but
  " that requires us to mess about with either the real cursor position or
  " marks, so instead we're going to inspect the bytes. This will only work if
  " your 'encoding' is UTF-8, but surely most people use that these days? If
  " we get a lot of complaints, we can implement the other version.
  let copy_char = getline(b:position[s:line])[b:position[s:column] - 1]
  let byte = char2nr(copy_char)

  " Find size by inspecting char
  if and(byte, 0b10000000) == 0
    let bytes = 1
  elseif and(byte, 0b11100000) == 0b11000000
    let bytes = 2
  elseif and(byte, 0b11110000) == 0b11100000
    let bytes = 3
  elseif and(byte, 0b11111000) == 0b11110000
    let bytes = 4
  else
    echoerr("BAD CHARACTER")
  endif
endfunction

function! s:first_character_byte(position) abort
  " If the beeb cursor is on a multibyte character and we're moving
  " horizontally, we need to alter s:column by more than one in order to move
  " the cursor. We could do this by checking the `virtcol` of the cursor, but
  " that requires us to mess about with either the real cursor position or
  " marks, so instead we're going to inspect the bytes. This will only work if
  " your 'encoding' is UTF-8, but surely most people use that these days? If
  " we get a lot of complaints, we can implement the other version.
  let copy_char = getline(a:position[s:line])[a:position[s:column] - 1]
  let byte = char2nr(copy_char)
  return and(byte, 0b11000000) != 0b10000000
endfunction

function! beebcopy#move(dir) abort
  if !exists('b:position')
    let b:position = getcurpos()
    " Leave when pressing Enter (for "backwards compatibility" with actual
    " BBC Micros).
    let b:mapped_cr = empty(maparg('<CR>', 'i'))
    if b:mapped_cr
      " Don't overwrite existing mappings. Technically we could use maparg
      " to save and restore the original mapping, but its complicated.
      inoremap <buffer> <silent> <expr> <CR> beebcopy#exit_copy_mode()
    endif
    " Leave when exiting insert mode (for actual usefulness).
    augroup beebcopy
      autocmd!
      autocmd InsertLeave <buffer> call beebcopy#exit_copy_mode()
  endif

  if a:dir ==# 'left'
    while 1
      let b:position[s:column] -= 1
      if s:first_character_byte(b:position)
        break
      endif
    endwhile
  elseif a:dir ==# 'right'
    while 1
      let b:position[s:column] += 1
      if s:first_character_byte(b:position)
        break
      endif
    endwhile
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
