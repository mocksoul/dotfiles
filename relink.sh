#!/bin/sh

P=$(realpath ${0%/*})
H=$HOME

ln -sfn $P/vim/vimrc $H/.vimrc
ln -sfn $P/vim/vim $H/.vim
ln -sfn $P/powerline $H/.config/powerline
