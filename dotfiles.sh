#!/bin/bash
local git_repo_url="$1"

log_info "Setting up dotfiles..."

rm -rf $HOME/.config
rm -f $HOME/.bashrc
rm -f $HOME/README.md
rm -f $HOME/setup.sh

git clone --bare "$git_repo_url" $HOME/.config

config() {
    /usr/bin/git --git-dir=$HOME/.config/ --work-tree=$HOME "$@"
}

config checkout

config config --local status.showUntrackedFiles no

sudo rm /boot/loader/loader.conf
sudo ln -s "$HOME/.config/system-config/boot/loader/loader.conf" /boot/loader/loader.conf

sudo rm /etc/tlp.conf
sudo ln -s ~/.config/tlp/tlp.conf /etc/tlp.conf

log_info "Dotfiles setup complete!"
