enterless.vim
=============

Enterless is a minimalist directory viewer built for fast file browsing.

Features
--------

Most of the code is taken from Dirvish, a fantastic plugin written by
@justinimk.

His contributions includes the following features:

- _simple:_ each line is literally just a filepath
- _flexible:_ mash up the buffer with `:g` and friends
- _safe:_ never modifies the filesystem
- original and _alternate_ buffers are preserved
- meticulous, non-intrusive defaults
- 2x faster than netrw (try a directory with 1000+ items)
- visual selection opens multiple files
- `:Shdo` performs any shell command on selected file(s)
- fewer bugs: 400 lines of code (netrw has 11000)
- compatible with Vim 7.2+

Each line is an absolute filepath (hidden by Vim's
[conceal](https://neovim.io/doc/user/syntax.html#conceal) feature).

- Use plain old `y` to yank the path under the cursor, then feed it to `:r` or
  `:e` or whatever.
- Sort with `:sort` and filter with `:global`. Press `R` to reload.
- Instead of netrw's special mark/move commands, you can:
  `:!mv <c-r><c-a> <c-r><c-a>foo`
    - Or add lines to the quickfix list (`:'<,'>caddb`) and iterate them
      (`:cdo`, `:cfdo`).
- `:set ft=enterless` works on any text you throw at it. Try this:
  `git ls-files|vim +'setf enterless' -`

Each Enterless buffer name is the _actual directory name_, so commands and
plugins (fugitive.vim) that work with `@%` and `@#` do the Right Thing.

- Create directories with `:!mkdir %foo`.
- Create files with `:e %foo.txt`
- Enable fugitive: `autocmd FileType enterless call fugitive#detect(@%)`

In addtion, Enterless adds its own search forward system for lightning fast
file navigation.


Acknowledgements
----------------

Enterless was originally forked from Dirvish.
[dirvish](https://github.com/justinmk/dirvish-vim). Thanks to @justinmk.
