command! CoqStart call s:start()

function! s:start()
  if exists('b:coq')
    echohl ErrorMsg
    echo 'coqtop already started!'
    echohl None
    return
  endif
  let b:coq = coqtop#new()
endfunction
