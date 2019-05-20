for dir in ['left', 'right', 'up', 'down']
  execute 'inoremap <silent> <expr> <'.dir.'> beebcopy#move("'.dir.'")'
endfor

inoremap <silent> <expr> <End> beebcopy#copy()
