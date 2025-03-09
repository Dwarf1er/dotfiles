# Dotfiles

Storing your dotfiles in a git bare repo. This is how you can track your dotfiles using a git bare repo inside $HOME/.config.

# Table of Contents

- [Dotfiles](#dotfiles)
    - [Initial Setup](#initial-setup)
    - [Tracking Files](#tracking-files)
    - [Configuring a New System](#configuring-a-new-system)

## Initial Setup

To start tracking your dotfiles with a bare git repo, use the following commands:
```bash
# Create empty git repo in ~/.config
git init --bare $HOME/.config

# Create an alias for the git command to avoid conflicts with other git repos
alias config='/usr/bin/git --git-dir=$HOME/.config/ --work-tree=$HOME'

# Hide all the files that you aren't explicitly tracking from showing as untracked
config config --local status.showUntrackedFiles no

# Save alias to your .bashrc
echo "alias config='/usr/bin/git --git-dir=$HOME/.config/ --work-tree=$HOME'" >> $HOME/.bashrc

# Set remote origin url
# Replace <git-repo-url> with the URL of your remote repository, for example: https://github.com/Dwarf1er/dotfiles.git
config remote add origin <git-repo-url>
```

## Tracking Files

Once you have setup the bare repository, you can start tracking files using the alias:
```bash
config status
config add ./.config/nvim/init.lua
config commit -m "Add nvim/init.lua"
config add .bashrc
config commit -m "Add bashrc"
config push
```

## Configuring a New System

To get your dotfiles from your remote repository onto a new system use the following commands:
```bash
# Create an alias for the git command to avoid conflicts with other git repos
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

# Add .config to your .gitignore before cloning the remote repository to avoid recursion problems
echo ".config" >> .gitignore

# Clone your remote repository
# Replace <git-repo-url> with the URL of your remote repository, for example: https://github.com/Dwarf1er/dotfiles.git
git clone --bare <git-repo-url> $HOME/.config

# Checkout the content from the repository, it might fail because of already existing config files, you can remove them and try again
config checkout

# Hide all the files that you aren't explicitly tracking from showing as untracked
config config --local status.showUntrackedFiles no
```

## Manage Git Credentials with libsecret

To manage your git credentials with libsecret run the following commands:
```bash
sudo pacman -S libsecret gnome-keyring
cd /usr/share/git/credential/libsecret
sudo make
cd ~
git config --global credential.helper /usr/share/git/credential/libsecret/git-credential-libsecret
```
