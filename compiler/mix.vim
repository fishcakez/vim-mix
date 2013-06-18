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
if exists('current_compiler')
    finish
endif
let current_compiler = 'mix'

if exists(':CompilerSet') != 2
    command -nargs=* CompilerSet setlocal <args>
endif

let s:cpo_save = &cpo
set cpo-=C

let s:mix_env = mix#env_get()
if empty(s:mix_env)
    CompilerSet makeprg=mix
else
    "If :Dispatch is not present we need to add the MIX_ENV so :make uses is.
    execute 'CompilerSet makeprg=MIX_ENV=' . s:mix_env .'\ mix'
endif
unlet s:mix_env

CompilerSet errorformat=
            \%+E%\\s%#\*\*\ (%[%^)]%\\+)\ %f:%l:%.%#,
            \%+E%.%#\*\*\ (%[%^)]%\\+)%.%#,
            \%+Z%\\s%#at\ %f:%l,
            \%-Z,
            \%+C%\\s%#%f:%l%.%#,
            \%+C%\\s%#%.%#,
            \%f:%l:\ %m,
            \%f:none:\ %m,
            \%f:%l:\ %tarning:\ %m,
            \%f:none:\ %tarning:\ %m,
            \%-G

let &cpo = s:cpo_save
unlet s:cpo_save
