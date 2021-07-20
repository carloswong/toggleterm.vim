" Toggle Term
" Last Change:	2021 Jul 17
" Maintainer:	Anandha Padmanaban Prasad <padmanabam_789@hotmail.com>
" License: MIT

if exists("g:loaded_toggle_term") || !has("terminal")
  finish
endif
let g:loaded_toggle_term = 1

let s:save_cpo = &cpo
set cpo&vim

if !hasmapto('<Plug>ToggletermToggle')
    nmap <silent> <C-Bslash> <Plug>ToggletermToggle
    tmap <silent> <C-Bslash> <C-w><S-N><Plug>ToggletermToggle
endif
noremap <silent> <script> <Plug>ToggletermToggle  <SID>Toggle
noremap <silent> <script> <SID>Toggle  :call <SID>Toggle()<CR>

" Constants
let s:term_name = "toggle_term"
let s:latest_window_ids = {1: -1}  " tabpage => window_id

" Customizations
let s:toggle_term_height = get(g:, "toggle_term_height", float2nr((35 * &lines)/100)) " default 35% height of total
let s:toggle_term_position = get(g:, "toggle_term_position", "botright")

" Toggle Term
function s:Toggle()
    let l:term_hidden = s:IsHidden()

    " Save window id of cursor position so that we can jump back to the
    " appropriate buffer upon toggling the terminal off
    if bufname() != s:term_name
        call s:SetLatestWindowId()
    endif

    " Toggle NERDtree on and off such that we get the terminal placed at the
    " bottom spanning across all the other windows except NERDTree's
    "
    " i.e.
    " ------------------
    " |    |     |     |
    " |    |  1  |  2  |
    " | NT |     |     |
    " |    |-----------|
    " |    |    TT     |
    " ------------------
    if exists("g:NERDTree") && g:NERDTree.IsOpen()
        execute "NERDTreeClose"
        let l:should_toggle_nerdtree = 1
    endif

    " Initialize terminal if it already does not exist, or toggle
    if !bufexists(s:term_name)
        execute printf("%s call term_start('%s', {'term_name': '%s', 'term_finish': 'close', 'term_kill': 'kill'})", s:toggle_term_position, &shell, s:term_name)
        setlocal termwinsize=""
    elseif l:term_hidden
        execute printf("%s new", s:toggle_term_position)
        execute printf("buffer %d", bufnr(s:term_name))

        " Make sure we do not get any errors when trying to go to insert mode
        if mode() == 'n'
            silent normal A
        endif
    elseif !l:term_hidden
        call s:Focus()
        wincmd N | hide
    endif

    if get(l:, "should_toggle_nerdtree", 0)
        execute "NERDTreeFocus"
    endif

    " Set focus and set height if terminal has been toggled on
    if l:term_hidden
        call s:Focus()
        call s:SetTermHeight()
    else
        " Otherwise, go back to previous window in the current tab
        call s:GoToWindow(get(s:latest_window_ids, printf('%d', tabpagenr())))
    endif
endfunction

" Move cursor to the toggle terminal's buffer
function s:Focus()
    let l:winid = s:GetToggleTermWindowId()
    if l:winid != -1
        call s:GoToWindow(l:winid)
    endif
endfunction

" Check if the buffer is hidden across all tab pages
function s:IsHidden()
    let l:currentTab = tabpagenr()
    for l:bId in tabpagebuflist(currentTab)
        if bufname(l:bId) == s:term_name
            return 0
        endif
    endfor

    return 1
endfunction

" Go to the window given the window id
function s:GoToWindow(window_id)
    if win_id2win(a:window_id)
        execute "call win_gotoid(" . a:window_id . ")"
    else
        " Otherwise go to the first window in this tabpage
        execute "call win_gotoid(" . win_getid(1) ")"
    endif
endfunction

function s:SetLatestWindowId()
    let l:win_id = bufwinid(bufnr())
    if l:win_id != s:GetToggleTermWindowId()
        execute printf("let s:latest_window_ids.%s = l:win_id", tabpagenr())
    endif
endfunction

function s:GetToggleTermWindowId()
    return bufwinid(s:term_name)
endfunction

function s:SetTermHeight()
    execute "resize " . s:toggle_term_height
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
