#!/bin/bash
install_packages() {
    for package in "$@"; do
        if ! command -v "$package" &> /dev/null; then
            echo "$package is not installed. Installing $package..."
            sudo pacman -S --noconfirm "$package"
        else
            echo "$package is already installed."
        fi
    done
}

if [ -z "$1" ]; then
    echo "Usage: $0 <git-repo-url>"
    exit 1
fi

GIT_REPO_URL="$1"

echo "Removing existing .config directory and .bashrc..."
rm -rf $HOME/.config
rm -f $HOME/.bashrc

echo "Installing packages..."
install_packages git

echo "Cloning dotfiles repository..."
git clone --bare $GIT_REPO_URL $HOME/.config

echo "Setting up temporary config function for setup..."
config() {
    /usr/bin/git --git-dir=$HOME/.config/ --work-tree=$HOME "$@"
}

echo "Checking out files..."
config checkout

echo "Hiding untracked files..."
config config --local status.showUntrackedFiles no

echo "Setup complete!"
