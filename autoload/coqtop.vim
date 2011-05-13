function! coqtop#start()"{{{
  if exists('b:coq')
    echohl ErrorMsg
    echo 'coqtop already started!'
    echohl None
    return
  endif

  let b:coq = {}
  let b:coq.proc = vimproc#popen2(['coqtop', '-emacs-U'])
  let b:coq.last_line = 0

  rightbelow vnew
    let l:bufnr = bufnr('%')
    setlocal buftype=nofile bufhidden=hide noswapfile
  wincmd p
  let b:coq.bufnr = l:bufnr
  let l:msg = b:coq.proc.stdout.read(-1, 100)
  call coqtop#display(split(l:msg, '\n'))

  let l:prompt = b:coq.proc.stderr.read(-1, 100)
  let b:coq.backtrack = {}
  let b:coq.backtrack[0] = s:parse_prompt(l:prompt)

  command! -buffer CoqQuit call coqtop#quit()
  command! -buffer CoqClear call coqtop#clear()
  command! -buffer CoqGoto call coqtop#goto(<line2>)

  inoremap <buffer> <expr> <Plug>(coqtop-goto) <SID>coqgoto_i()
  if !exists('g:coqtop_no_default_mappings') || !g:coqtop_no_default_mappings
    nnoremap <buffer> <silent> <LocalLeader>q :<C-u>CoqQuit<CR>
    nnoremap <buffer> <silent> <LocalLeader>c :<C-u>CoqClear<CR>
    nnoremap <buffer> <silent> <LocalLeader>g :<C-u>CoqGoto<CR>
    imap <buffer> <C-g> <Plug>(coqtop-goto)
  endif

  hi def link coqtopFrozen Folded
  augroup coqtop
    autocmd CursorMoved,CursorMovedI <buffer> call s:check_line()
  augroup END
endfunction"}}}

function! s:check_line()"{{{
  let l:line = line('.')
  if l:line <= b:coq.last_line && l:line < line('$')
    setlocal nomodifiable
  else
    setlocal modifiable
  endif
endfunction"}}}

function! s:coqgoto_i()"{{{
  let l:prefix = "\<Esc>:\<C-u>CoqGoto\<CR>"
  if line('.') == line('$')
    return l:prefix . 'o'
  else
    return l:prefix . 'jO'
  endif
endfunction"}}}

function! coqtop#quit()"{{{
  call b:coq.proc.stdin.write("Quit.\n")
  call b:coq.proc.waitpid()

  execute bufwinnr(b:coq.bufnr) 'wincmd p'
  close

  unlet b:coq
  augroup coqtop
    autocmd!
  augroup END

  delcommand CoqQuit
  delcommand CoqClear
  delcommand CoqGoto

  setlocal modifiable
endfunction"}}}

function! coqtop#clear()"{{{
  call coqtop#quit()
  call coqtop#start()
endfunction"}}}

function! coqtop#goto(end) abort"{{{
  if a:end < b:coq.last_line
    call s:backtrack(a:end)
  else
    call s:eval_to(a:end)
  endif
  "let l:pats = range(1, b:coq.last_line)
  "call map(l:pats, '"\\%" . v:val . "l"')
  "execute 'match coqtopFrozen /' . join(l:pats, '\|') . '/'
  execute 'match coqtopFrozen /\%' . b:coq.last_line . 'l/'
endfunction"}}}

function! s:backtrack(end) abort"{{{
  let l:end = a:end
  while !has_key(b:coq.backtrack, l:end) && l:end >= 0
    let l:end -= 1
  endwhile
  if b:coq.backtrack[b:coq.last_line].id != b:coq.backtrack[l:end].id
    call coqtop#clear()
    call s:eval_to(l:end)
  endif

  let l:backtrack = b:coq.backtrack[l:end]
  call b:coq.proc.stdin.write(printf("Backtrack %d %d 0.\n", l:backtrack.env_state, l:backtrack.proof_state))
  let l:msg = b:coq.proc.stdout.read(-1, 100)
  if !empty(l:msg)
    call coqtop#display(split(l:msg, '\n'))
  endif
  let l:prompt = b:coq.proc.stderr.read(-1, 100)
  if match(l:msg, '^Error') == -1
    let b:coq.backtrack[l:end] = s:parse_prompt(l:prompt)
    let b:coq.last_line = l:end
  else
    call coqtop#clear()
    call s:eval_to(l:end)
  endif
endfunction"}}}

function! s:eval_to(end) abort"{{{
  let l:last_msg = ''
  let l:lines = getline(b:coq.last_line+1, a:end)
  let l:lineno = b:coq.last_line+1
  for l:line in l:lines
    let l:line = substitute(l:line, '^\s*', '', '')
    let l:line = substitute(l:line, '\s*$', '', '')
    if !empty(l:line)
      call b:coq.proc.stdin.write(l:line . "\n")
      let l:msg = b:coq.proc.stdout.read(-1, 100)
      if !empty(l:msg)
        let l:last_msg = l:msg
      endif
      let l:prompt = b:coq.proc.stderr.read(-1, 100)
      let b:coq.backtrack[l:lineno] = s:parse_prompt(l:prompt)
      let b:coq.last_line = l:lineno
    endif
    let l:lineno += 1
  endfor
  if !empty(l:last_msg)
    call coqtop#display(split(l:last_msg, '\n'))
  endif
endfunction"}}}

function! s:parse_prompt(prompt) abort"{{{
  let l:prompt = matchstr(a:prompt, '<prompt>\zs.*\ze</prompt>')
  let l:dict = {}
  let l:id_and_nums = split(l:prompt, '\s*<\s*')
  let l:dict.id = l:id_and_nums[0]
  let l:env = split(l:id_and_nums[1], '\s*|\s*')
  let l:dict.env_state = l:env[0]
  let l:dict.opened_proofs = l:env[1 : -2]
  let l:dict.proof_state = l:env[-1]
  return l:dict
endfunction"}}}

function! coqtop#display(lines)"{{{
  try
    let l:cur = winnr()
    execute bufwinnr(b:coq.bufnr) 'wincmd w'
    silent %delete _
    call setline(1, a:lines)
  finally
    execute l:cur 'wincmd w'
  endtry
endfunction"}}}
