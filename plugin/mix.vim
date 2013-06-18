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
if exists('g:loaded_mix')
    finish
endif
let g:loaded_mix = 1

command! -bang -nargs=* -complete=custom,mix#complete Mix
            \ echo mix#dispatch(expand('<bang>'), [<f-args>])

command! -nargs=? -complete=custom,mix#env_list MixEnv
            \ echo mix#env_set(<q-args>)

command! -nargs=0 MixFill echo mix#fill()
command! -nargs=0 MixPurge echo mix#purge()