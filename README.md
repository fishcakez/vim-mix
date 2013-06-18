vim-mix
=======
A vim plugin to make using mix easier and faster from inside vim.

Features
--------
- Run mix asynchronously.

- Quickfix support.

- Mix command completion.

Install
-------
- Install dispatch.vim (https://github.com/tpope/vim-dispatch)

- Clone this repo and install into your vim path - with pathogen.vim:

```
cd ~/.vim/bundle && git clone https://github.com/fishcakez/vim-mix.git
```


Usage
-----
Exactly the same as `mix`; to run `mix compile`:
```
:Mix compile
```
To set the `MIX_ENV` value (to `test`) for use with`:Mix`:
```
:MixEnv test
```
This will prefix all `mix` calls with `MIX_ENV=test` until you unset it:
```
:MixEnv
```
To run mix in the background:
```
:Mix! test
```
Then to create a quickfix list (requires dispatch.vim):
```
:Copen
```
To run mix in a new, focused, window (requires dispatch.vim):
```
:Mix!! help
```
To tun mix in a new, unfocused, window (requires dispatch.vim):
```
:Mix!!! deps.get
```

Caveats
-------
- Quickfix support is work in progress. No output is lost to allow local tasks.

- Direct use of `:Dispatch`, `:Make` (from disptach.vim) can not use MIX_ENV.
