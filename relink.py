#!/usr/bin/env python3.9

import argparse
# import collections
import pathlib


# tgt, src
# for o/* items order is flipped so "o/src tgt"

NOREL = 1

items = [
    'O/',                                   '~/.config/dotfiles',                               NOREL,

    'o/zsh',                                '~/.config/zsh',
    '~/.zshrc',                             '~/.config/zsh/zshrc',

    'o/bash',                               '~/.config/bash',
    '~/.bashrc',                            '~/.config/bash/bashrc',
    '~/.bash_profile',                      '~/.config/bash/bash_profile',
    '~/.bash_logout',                       '~/.config/bash/bash_logout',

    'o/vim',                                '~/.config/vim',
    '~/.vimrc',                             '~/.config/vim/vimrc',
    '~/.vim/view',                          '~/.local/share/nvim/view',                         NOREL,

    'o/tmux',                               '~/.config/tmux',
    '~/.tmux.conf',                         '~/.config/tmux/tmux.conf',

    'o/alacritty',                          '~/.config/alacritty',
    '~/.local/bin/alacritty_quake_toggle',  '~/.config/alacritty/alacritty_quake_toggle',       NOREL,

    'o/kde/khotkeysrc',                     '~/.config/khotkeysrc',

    'o/git',                                '~/.config/git',
    '~/.gitconfig',                         '~/.config/git/gitconfig',
    '~/.gitignore',                         '~/.config/git/gitignore',
    '~/.tigrc',                             '~/.config/git/tigrc',
    '~/.local/bin/lazygit',                 '~/go/src/github.com/jesseduffield/lazygit/lazygit', NOREL,

    'o/top',                                '~/.config/top',
    '~/.toprc',                             '~/.config/top/toprc',

    'o/arc',                                '~/.config/arc',
    '~/.arcconfig',                         '~/.config/arc/arcconfig',
    '~/.arcignore',                         '~/.config/arc/arcignore',
    '~/.arcignore.symlink',                 '~/.config/arc/arcignore.symlink',
]


mkdirs = [
    '~/.local/share/nvim/plugged',
    '~/.local/share/nvim/shada',
    '~/.local/share/nvim/swap',
    '~/.local/share/nvim/view',
    '~/.local/share/zsh'
]

zshplugs = (
    '[ ! -d $H/.local/share/zsh/plug/wakatime ] && '
    'git clone https://github.com/sobolevn/wakatime-zsh-plugin.git $H/.local/share/zsh/plug/wakatime'
)


def pairopts():
    item_a = None
    item_b = None

    for itm in items:
        if item_a is None:
            item_a = itm
        elif item_b is None:
            item_b = itm
        else:
            if isinstance(itm, int):
                yield (item_a, item_b, itm)
                item_a = item_b = None
            else:
                yield (item_a, item_b, 0)
                item_a = itm
                item_b = None

    if item_a is not None and item_b is not None:
        yield (item_a, item_b, 0)
        item_a = item_b = None


def pairwise(iterable):
    iterator = iter(iterable)
    return zip(iterator, iterator)


def relink(fix=False, verbose=False):
    opath = None

    for tgt, src, opt in pairopts():
        src, tgt = pathlib.Path(src), pathlib.Path(tgt)
        srco, tgto = src, tgt

        if tgt.parts[0] == 'O':
            tgt = pathlib.Path('.').absolute().joinpath(*tgt.parts[1:])
            src, tgt = tgt, src
            srco, tgto = tgto, srco
            opath = tgt

        if tgt.parts[0] == 'o':
            assert opath is not None
            tgt = pathlib.Path(opath).expanduser().joinpath(*tgt.parts[1:])
            src, tgt = tgt, src
            srco, tgto = tgto, srco

        src = src.expanduser()
        tgt = tgt.expanduser()

        if not src.exists():
            print(f'EE src path {src} not found')
            continue

        if src.is_symlink():
            print(f'EE src path {src} is link, but we do not expect this')
            continue

        # print('src', src, 'tgt', tgt)

        # print(src, tgt)
        srcl = src

        if opt & NOREL == 0:
            try:
                rel = src.relative_to(tgt.parent)
                srcl = rel
            except ValueError:
                print(f'WW unable to compute relative path {srco} => {tgto}')

        if tgt.is_symlink():
            if tgt.readlink() == srcl:
                if verbose:
                    print(f'OK {srco} => {tgto}')
            else:
                if tgt.resolve() == src.resolve():
                    print(f'II {srco} => {tgto}')
                    print('  replacing symlink to samefile')
                    print(f'    old: {tgt.readlink()}')
                    print(f'    new: {src}')
                    tgt.unlink()
                    tgt.symlink_to(srcl)
                else:
                    print(f'EE {srco} => {tgto}')
                    print(f'  current symlink target : {tgt.readlink()}')
                    print(f'  expected symlink target: {src}')
        else:
            if tgt.exists():
                print(f'EE {srco} => {tgto}')
                print('  target already exists')
            else:
                print(f'II {srco} => {tgto}')
                if not tgt.parent.exists():
                    print(f'  creating parents {tgt.parent}')
                    tgt.parent.mkdir(parents=True)

                print(f'  creating link {srco} => {tgto}')
                tgt.symlink_to(srcl)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--fix', type=bool, default=False)
    parser.add_argument('-v', '--verbose', action='store_true', default=False)

    args = parser.parse_args()

    return relink(fix=args.fix, verbose=args.verbose)


if __name__ == '__main__':
    main()
