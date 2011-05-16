command! CoqStart call s:start()

function! s:start()
  if exists('b:coq')
    echohl ErrorMsg
    echo 'coqtop already started!'
    echohl None
    return
  endif
  if !executable('coqtop')
    echohl ErrorMsg
    echo 'cannot execute coqtop!'
    echohl None
    return
  endif
  let b:coq = coqtop#new()
endfunction
