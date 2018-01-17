let s:t_number = type(0)
let s:receivers = []


function! s:_vital_healthcheck() abort
  if has('patch-8.0.0001') || has('nvim-0.2.0')
    return
  endif
  return 'This module requires Vim 8.0.0001 or Neovim 0.2.0'
endfunction

function! s:_vital_loaded(V) abort
  let s:Console = a:V.import('Vim.Console')
endfunction

function! s:_vital_depends() abort
  return ['Vim.Console']
endfunction

function! s:_vital_created(module) abort
  call a:module.register(s:get_default_receiver())
endfunction

function! s:message(category, msg) abort
  return printf(
        \ 'vital: App.Revelator: %s: %s',
        \ a:category,
        \ a:msg,
        \)
endfunction

function! s:info(msg) abort
  let v:statusmsg = a:msg
  return s:message('INFO', a:msg)
endfunction

function! s:warning(msg) abort
  let v:warningmsg = a:msg
  return s:message('WARNING', a:msg)
endfunction

function! s:error(msg) abort
  let v:errmsg = a:msg
  return s:message('ERROR', a:msg)
endfunction

function! s:critical(msg) abort
  let v:errmsg = a:msg
  return s:message('CRITICAL', a:msg)
endfunction

function! s:call(func, arglist, ...) abort
  let receivers_saved = copy(s:receivers)
  let dict = a:0 ? a:1 : 0
  try
    return type(dict) == s:t_number
          \ ? call(a:func, a:arglist)
          \ : call(a:func, a:arglist, dict)
  catch /^vital: App\.Revelator: /
    call s:_receive(v:exception, v:throwpoint)
  finally
    let s:receivers = receivers_saved
  endtry
endfunction

function! s:register(receiver) abort
  call add(s:receivers, a:receiver)
endfunction

function! s:unregister(receiver) abort
  let index = index(s:receivers, a:receiver)
  if index != -1
    call remove(s:receivers, index)
  endif
endfunction

function! s:get_default_receiver() abort
  return function('s:_default_receiver')
endfunction


function! s:_receive(exception, throwpoint) abort
  let m = matchlist(a:exception, '^vital: App\.Revelator: \(.\{-}\): \(.*\)$')
  if len(m)
    let category = m[1]
    let message = m[2]
    let revelation = {
          \ 'category': m[1],
          \ 'message': m[2],
          \ 'exception': a:exception,
          \ 'throwpoint': a:throwpoint,
          \}
    for l:Receiver in reverse(copy(s:receivers))
      if call(Receiver, [revelation])
        return
      endif
    endfor
  endif
  throw a:exception . "\n" . a:throwpoint
endfunction

function! s:_default_receiver(revelation) abort
  if a:revelation.category ==# 'INFO'
    redraw
    call s:Console.info(a:revelation.message)
    call s:Console.debug(a:revelation.throwpoint)
    return 1
  elseif a:revelation.category ==# 'WARNING'
    redraw
    call s:Console.warn(a:revelation.message)
    call s:Console.debug(a:revelation.throwpoint)
    return 1
  elseif a:revelation.category ==# 'ERROR'
    redraw
    call s:Console.error(a:revelation.message)
    call s:Console.debug(a:revelation.throwpoint)
    return 1
  elseif a:revelation.category ==# 'CRITICAL'
    redraw
    call s:Console.error(a:revelation.message)
    call s:Console.error(a:revelation.throwpoint)
    return 1
  endif
endfunction
