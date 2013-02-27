#!/bin/sh

P=$(realpath ${0%/*})
H=$HOME

ln -sfn $P/vim/vimrc $H/.vimrc
ln -sfn $P/vim/vim $H/.config/vim
ln -sfn $P/powerline $H/.config/powerline
ln -sfn $P/bin/peat $H/bin/peat
