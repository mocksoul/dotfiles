#!/bin/bash -x

P=$(realpath ${0%/*})
H=$HOME

mkdir -p $H/.local/share/nvim/{plugged,shada,swap,view}
mkdir -p $H/.local/share/zsh

ln -sfn $P/zsh $H/.config/zsh
ln -sfn $H/.config/zsh/zshrc $H/.zshrc

ln -sfn $H/.config/vim/vimrc $H/.vimrc
ln -sfn $P/vim $H/.config/vim

ln -sfn $H/.local/share/nvim/view $H/.vim/view

ln -sfn $P/tmux/tmux.conf $H/.tmux.conf
ln -sfn $P/alacritty $H/.config/alacritty

ln -sfn $P/bin/alacritty_quake_toggle $H/.local/bin

ln -sfn $P/kde/khotkeysrc $H/.config

ln -sfn $P/git/gitconfig $H/.gitconfig
ln -sfn $P/git/tigrc $H/.tigrc

ln -sfn $P/top/toprc $H/.toprc

# Checkout zsh plugins if we didnt do that yet
[ ! -d $H/.local/share/zsh/plug/wakatime ] && git clone https://github.com/sobolevn/wakatime-zsh-plugin.git $H/.local/share/zsh/plug/wakatime

