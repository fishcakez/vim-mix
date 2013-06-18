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

if exists('g:autoloaded_mix_complete')
    finish
endif
let g:autoloaded_mix_complete = 1

" Purge caches
function! mix#complete#purge()
    let purges = 0
    if exists('g:mix#complete#deps_list_cache')
        unlet g:mix#complete#deps_list_cache
        let purges += 1
    endif
    if exists('g:mix#complete#local_list_cache')
        unlet g:mix#complete#local_list_cache
        let purges += 1
    endif
    return purges
endfunction

" Fill caches
function! mix#complete#fill()
    let results = len(mix#complete#deps_list()) + len(mix#complete#local_list())
    return results
endfunction

" List suggestions
function! mix#complete#list(arglead, cmdline, cursorpos)
    let [cmd, opts] = mix#complete#split_cmdline(a:cmdline)
    let cursorpos = a:cursorpos - (strlen(a:cmdline) - strlen(opts))
    if empty(cmd) || (cursorpos <= 0)
        return mix#complete#cmd_list()
    else
        return mix#complete#opts(cmd, a:arglead, opts, cursorpos)
    end
endfunction

" Split command from options, command empty if not found
function! mix#complete#split_cmdline(cmdline)
    return matchlist(a:cmdline, '\s*\([a-z][a-z0-9_.]*\)\?\(.*\)')[1:2]
endfunction

" List suggestions for a command
function! mix#complete#opts(cmd, arglead, cmdline, cursorpos)
    let info = mix#complete#cmd_info()
    let Cmd_info = get(info, a:cmd, [])
    if type(Cmd_info) == type(function('strlen'))
        return Cmd_info(a:arglead, a:cmdline, a:cursorpos)
    elseif type(Cmd_info) == type([])
        return mix#complete#opts_list(a:cmd, Cmd_info)
    else
        echomsg 'Invalid command info for '. a:cmd
        return []
    endif
endfunction

" List suggestions for a command given command info
function! mix#complete#opts_list(cmd, cmd_info)
    let suggestions = []
    for Suggestion in a:cmd_info
        if type(Suggestion) == type('')
            call add(suggestions, Suggestion)
        elseif type(Suggestion) == type(function('strlen'))
            let suggestions2 = Suggestion()
            call extend(suggestions, suggestions2)
        else
           echomsg 'Invalid command info for ' . a:cmd
           return []
       endif
       " unlet so can change the type between string and funcref
       unlet Suggestion
   endfor
   return suggestions
endfunction

" List all commands (including local tasks)
function! mix#complete#cmd_list()
   let cmds = keys(mix#complete#cmd_info())
   let local = mix#complete#local_list()
   return sort(cmds + local)
endfunction

" List all local tasks
function! mix#complete#local_list()
    if exists('g:mix#complete#local_list_cache')
        return g:mix#complete#local_list_cache
    else
        " matching 'mix cmd_name[.sub_cmd1] ...'
        let pattern = 'mix \([a-z][a-z0-9_/]*\) .*'
        let cache = mix#complete#run_filter('local', pattern)
        let g:mix#complete#local_list_cache = copy(cache)
        return cache
    endif
endfunction

" List all deps
function! mix#complete#deps_list()
    if exists('g:mix#complete#deps_list_cache') &&
                \g:mix#complete#deps_list_cache[0] == getcwd() &&
                \g:mix#complete#deps_list_cache[1] == getftime('mix.exs')
        return g:mix#complete#deps_list_cache[2]
    else
        let dir = getcwd()
        let ftime = getftime('mix.exs')
         " matching '* depname ...'
        let deps = mix#complete#run_filter("deps", '\* \([^ ]\+\) .*')
        let g:mix#complete#deps_list_cache = [dir, ftime, copy(deps)]
        return deps
    endif
endfunction

" Run mix with a command and return first match per line for filter
function! mix#complete#run_filter(cmd, filter)
    let lines = mix#complete#run(a:cmd)
    let results = []
    for line in lines
        let result = matchlist(line, a:filter)
        if !empty(result) && !empty(result[1])
            call add(results, result[1])
        endif
    endfor
    return results
endfunction

" Run a mix command, stdout split per line
function! mix#complete#run(cmd)
    let lines = system("mix " . a:cmd)
    if v:shell_error
        return []
    else
        return split(lines, '\n')
    endif
endfunction

" List all test files - with current file listed first if a test file
function! mix#complete#test()
    let test_files = reverse(split(globpath('.', '**/*_test.exs'), '\n'))
    let current_file = expand('%')
    if current_file =~ '_test.exs$'
        call insert(test_files, current_file)
    endif
    return test_files
endfunction

" Find command in do list and return a list of suggestions for that command or
" a list of commands if cursorpos on command name. Works by creating a sub
" context inside 'do' - ',' OR ',' - ',' OR 'do' - end OR ',' - end and
" passing the sub context to mix#complete#list
function! mix#complete#do(arglead, cmdline, cursorpos)
    " no suggestion for a ','
    if a:cmdline[a:cursorpos] == ','
        return []
    else
        let cmdlist = split(a:cmdline, ',')
        let cmdline = ''
        let cursorpos = a:cursorpos
        let pos_start = a:cmdline[0] == ',' ? 1 : 0
        for cmd in cmdlist
            let pos_end = pos_start + strlen(cmd)
            if pos_end >= a:cursorpos
                " This cmd is the cmdline
                let cmdline = cmd
                let cursorpos = a:cursorpos - pos_start
                break
            endif
            let pos_start = pos_end + 1
        endfor
        echomsg '|' . a:arglead . '|' . cmdline . '|' . cursorpos
        return mix#complete#list(a:arglead, cmdline, cursorpos)
    endif
endfunction

" Get dictionary with command info.
function! mix#complete#cmd_info()
    return {
                \'clean' : ['--all'],
                \'compile' : ['--list'],
                \'deps' : [],
                \'deps.get' : ['--no-compile', '--quiet'],
                \'deps.compile' : [function('mix#complete#deps_list')],
                \'deps.update' : [
                    \function('mix#complete#deps_list'), '--no-compile'
                    \],
                \'deps.clean' : [
                    \function('mix#complete#deps_list'), '--unlock'
                    \],
                \'deps.unlock' : [function('mix#complete#deps_list')],
                \'do' : function('mix#complete#do'),
                \'escriptize' : ['--force', '--no-compile'],
                \'help' : [function('mix#complete#cmd_list')],
                \'local' : [],
                \'local.install' : ['--force'],
                \'local.rebar' : [],
                \'local.uninstall' : [function('mix#complete#local_list')],
                    \'new' : [
                    \'--sup', '--module', '--umbrella'
                    \],
                \'run' : [
                    \'--require', '-r', '--parallel-require', '-pr',
                    \'--nohalt', '--no-compile', '--no-start'
                    \],
                \'test' : [
                    \function('mix#complete#test'), '--cover', '--force',
                    \'--quick', '-q', '--no-compile', '--no-start'
                    \]
                \}
endfunction
