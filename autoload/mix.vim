" Copyright 2013 James Fish
"
" Licensed under the Apache License, Version 2.0 (the "License");
" you may not use this file except in compliance with the License.
" You may obtain a copy of the License at
"
"     http://www.apache.org/licenses/LICENSE-2.0
"
" Unless required by applicable law or agreed to in writing, software
" distributed under the License is distributed on an "AS IS" BASIS,
" WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
" See the License for the specific language governing permissions and
" limitations under the License.
if exists('g:autoloaded_mix')
    finish
endif
let g:autoloaded_mix = 1

function! mix#dispatch(bang, args)
    let args = join(a:args)
    let [bangs, mixargs] = mix#split_args(args)
    let cmd = 'mix ' . mixargs
    if exists(':Dispatch') && exists(':Start')
        if strlen(bangs) == 0
            execute 'Dispatch' . a:bang mix#env_add(cmd)
        else
            let bang = (strlen(bangs) > 1) ? '!' : ''
            execute 'Start' . bang cmd
        endif
    else
        return mix#compile_command(a:bang, mixargs)
    endif
endfunction

function! mix#split_args(args)
    "match leading !'s and the remainder
    return matchlist(a:args, '\(!*\)\(.*\)')[1:2]
endfunction

function! mix#compile_command(bang, args)
    let compiler_info = mix#get_compiler_info()
    if &autowrite
        wall
    endif
    try
        execute 'compiler mix'
        execute 'make' . a:bang a:args
    finally
        call mix#set_compiler_info(compiler_info)
    endtry
    return ''
endfunction

function! mix#get_compiler_info()
    return [get(b:, 'current_compiler', ''), &l:makeprg, &l:efm]
endfunction

function! mix#set_compiler_info(compiler_info)
    let [name, &l:makeprg, &l:efm] = a:compiler_info
    if empty(name)
        unlet! b:current_compiler
    else
        let b:current_compiler = name
    endif
endfunction

function! mix#complete(arglead, cmdline, cursorpos)
    let cmdlist = split(a:cmdline, ' ')
    let mix_and_bangs = cmdlist[0]
    " cursorpos is on extra bangs, can't offer any completion
    if (a:cursorpos <= strlen(mix_and_bangs)) ||
                \((len(cmdlist) == 1) &&
                \(strlen(a:cmdline) == strlen(cmdlist[0])))
        return ''
    else
        " Add trailing space if existed before split.
        if a:cmdline[strlen(a:cmdline)-1] == ' '
            call add(cmdlist, '')
        endif
        let cmdline = join(cmdlist[1:-1], ' ')
        " Move cursorpos back 1 for space between Mix and command
        let cursorpos = a:cursorpos - (strlen(mix_and_bangs) + 1)
        let suggestions = mix#complete#list(a:arglead, cmdline, cursorpos)
        return join(suggestions, "\n")
    endif
endfunction

function! mix#env_list(arglead, cmdline, cursorpos)
    return join(['dev', 'test', 'prod', 'doc'], "\n")
endfunction

function! mix#env_get()
    if exists('g:mix_env') && type(g:mix_env) == type('')
        return g:mix_env
    else
        return ''
    endif
endfunction

function! mix#env_set(mix_env)
    if type(a:mix_env) != type('')
        echomsg 'Invalid MIX_ENV=' . a:mix_env
    elseif a:mix_env =~ '^[a-z][a-zA-Z0-9]*$'
        let g:mix_env = copy(a:mix_env)
    elseif !empty(a:mix_env)
        echomsg 'Invalid MIX_ENV=' . a:mix_env
    elseif exists('g:mix_env')
        unlet g:mix_env
    endif
    return ''
endfunction

function! mix#env_add(cmd)
    let mix_env = mix#env_get()
    if empty(mix_env)
        return a:cmd
    else
        " For :Dispatch to use mix errorformat the command line must start
        " with mix and not MIX_ENV=. mix with no command is used as noop.
        return 'mix && MIX_ENV=' . mix_env . ' ' . a:cmd
    endif
endfunction

function! mix#purge()
    return mix#complete#purge()
endfunction

function! mix#fill()
    return mix#complete#fill()
endfunction
