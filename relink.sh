#!/bin/bash -x

P=$(realpath ${0%/*})
H=$HOME

mkdir -p $H/.local/share/nvim/{plugged,shada,swap,view}

ln -sfn $P/vim/vimrc $H/.vimrc
ln -sfn $P/vim/vim $H/.config/vim
ln -sfn $H/.local/share/nvim/view $H/.vim/view

ln -sfn $P/tmux/tmux.conf $H/.tmux.conf
ln -sfn $P/alacritty $H/.config/alacritty

ln -sfn $P/bin/alacritty_quake_toggle $H/.local/bin

ln -sfn $P/kde/khotkeysrc $H/.config
