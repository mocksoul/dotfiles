#!/bin/sh

P=$(realpath ${0%/*})
H=$HOME

mkdir -p $H/.config/nvim
mkdir -p $H/.local/share/nvim/{plugged,shada,swap,view}

ln -sfn $P/vim/vimrc $H/.vimrc
ln -sfn $P/vim/vim $H/.config/vim
ln -sfn $H/.vimrc $H/.config/nvim/init.vim
ln -sfn $H/.local/share/nvim/view $H/.vim/view

ln -sfn $P/tmux/tmux.conf $H/.tmux.conf
ln -sfn $P/alacritty $H/.config/alacritty
