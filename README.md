# coqtop-vim
Interact with coqtop within Vim.

## install
- Install [vimproc](https://github.com/Shougo/vimproc).
  - NOTE: Use latest vimproc, because vimproc 5.1 has a serious bug for coqtop-vim (fixed by [this commit](https://github.com/Shougo/vimproc/commit/e97c38caa39be79d6971059afbd9548fa1e67681)).
- Copy coqtop-vim to your 'runtimepath' directory (such as ~/.vim).

## usage
`:CoqStart` to start coqtop.

To prevent default local mappings, do `:let g:coqtop_no_default_mappings = 1`.

### :CoqGoto
Goto this line. You can go both forward and backward.

Mapped to `<LocalLeader>g` (in normal mode) and `<C-g>` (in insert mode) by default.

### :CoqClear
Clear current session.

Mapped to `<LocalLeader>c` by default.

### :CoqQuit
Quit coqtop-vim.

Mapped to `<LocalLeader>q` by default.

### :CoqPrint
Same as `Print` vernacular command.

Mapped to `<LocalLeader>p` by default.

### :CoqSearchAbout
Same as `SearchAbout` vernacular command.

Mapped to `<LocalLeader>s` by default.
