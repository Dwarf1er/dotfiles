#!/bin/bash

git_repo_url="$1"

log_info() {
    echo -e "\033[0;32m[INFO]\033[0m $1"
}

log_info "Setting up dotfiles..."

rm -rf "$HOME/.config"
rm -f "$HOME/.bashrc" "$HOME/README.md" "$HOME/setup.sh"

git clone --bare "$git_repo_url" "$HOME/.config"

config() {
    /usr/bin/git --git-dir="$HOME/.config/" --work-tree="$HOME" "$@"
}

config checkout -f

config config --local status.showUntrackedFiles no

sudo mkdir -p /boot/loader
sudo rm -f /boot/loader/loader.conf
sudo ln -sf "$HOME/.config/system-config/boot/loader/loader.conf" /boot/loader/loader.conf

sudo rm -f /etc/tlp.conf
sudo ln -sf "$HOME/.config/tlp/tlp.conf" /etc/tlp.conf

log_info "Dotfiles setup complete!"
