# Dotfiles

A comprehensive dotfiles and system post-installation setup using a bare git repository and a single unified `postinstall.sh` script.

Designed to be forkable, non-destructive, and interactive, allowing anyone to reuse the workflow for their own dotfiles and package selections.

## Table of Contents
- [Dotfiles](#dotfiles)
  - [Overview](#overview)
    - [Universal Use](#universal-use)
  - [Quick Start](#quick-start)
    - [New System Setup (Recommended)](#new-system-setup-recommended)
    - [Importing Only Dotfiles](#importing-only-dotfiles)
  - [Backup and Conflict Handling](#backup-and-conflict-handling)
  - [Manual Setup](#manual-setup)
    - [Initial Repository Setup](#initial-repository-setup)
    - [SSH Key Setup](#ssh-key-setup)
    - [Tracking Files](#tracking-files)
  - [New System Setup](#new-system-setup)
    - [Automated Setup](#automated-setup)
    - [Manual Configuration](#manual-configuration)
  - [Daily Usage](#daily-usage)
    - [Common Commands](#common-commands)
  - [Customizing Packages](#customizing-packages)
    - [Modifying Package Lists](#modifying-package-lists)

## Overview

This dotfiles repository uses a bare git repository stored in `~/.config` to track configuration files throughout your home directory. This approach allows you to version control your dotfiles without moving them from their expected locations or creating symlinks.

The setup includes:
- **Hyprland** window manager configuration
- **Waybar**, **Mako**, **Wofi** for the desktop environment
- **Ly** display manager
- **Kitty** terminal
- Automated installation script with package management

### Universal Use

You can fork this repository and replace the package lists with your own.
The same `postinstall.sh` script will work for your custom dotfiles repository.

## Quick Start

### New System Setup (Recommended)

The fastest way to set up a new system is using the automated setup script:

```bash
bash <(curl -s https://raw.githubusercontent.com/Dwarf1er/dotfiles/refs/heads/master/postinstall.sh) "https://github.com/Dwarf1er/dotfiles.git"
```

> [!WARNING]
> All conflicting files will be moved to `~/dotfiles-conflicts`. A full backup is also created in `~/dotfiles-backup-TIMESTAMP`.

This will:
1. Update your system
2. Install required packages (official and AUR)
3. Present optional packages for selection
4. Clone and configure dotfiles
5. Set up the `config` alias for dotfiles management

### Importing Only Dotfiles

If you only want to setup the dotfiles (no package installation):
```bash
bash <(curl -s https://raw.githubusercontent.com/Dwarf1er/dotfiles/refs/heads/master/postinstall.sh) "https://github.com/Dwarf1er/dotfiles.git" dotfiles
```
> [!WARNING]
> All conflicting files will be moved to `~/dotfiles-conflicts`. A full backup is also created in `~/dotfiles-backup-TIMESTAMP`.

## Backup and Conflict Handling

This setup is non-destructive. When files conflict during checkout:

- Conflicting files are moved to `~/dotfiles-conflicts`.  
- A full backup of existing configuration files is created in `~/dotfiles-backup-TIMESTAMP`.  
- This ensures you can always recover previous configurations without risk of data loss.

## Manual Setup

### Initial Repository Setup

If you're setting up the dotfiles repository for the first time:

```bash
# Create bare git repository
git init --bare $HOME/.config

# Create the config alias
alias config='/usr/bin/git --git-dir=$HOME/.config/ --work-tree=$HOME'

# Hide untracked files
config config --local status.showUntrackedFiles no

# Make the alias permanent
echo "alias config='/usr/bin/git --git-dir=$HOME/.config/ --work-tree=$HOME'" >> $HOME/.bashrc

# Add remote repository
config remote add origin https://github.com/Dwarf1er/dotfiles
```

### SSH Key Setup

Instructions to set up SSH authentication:

```bash
# Generate SSH key (if you don't have one)
ssh-keygen -t ed25519 -C "your.email@example.com"

# Start SSH agent and add key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Copy public key to clipboard (requires wl-clipboard)
wl-copy < ~/.ssh/id_ed25519.pub

# If your dotfiles repo was cloned using HTTPS, update it to SSH
config remote set-url origin git@github.com:<username>/<repo>.git
```

Then add the public key to your Github account in the SSH keys section.

### Tracking Files

Example on how to start tracking your configuration files:

```bash
# Check status
config status

# Add configuration files
config add .config/hypr/hyprland.conf
config add .config/waybar/config
config add .bashrc
config add .config/kitty/kitty.conf

# Commit changes
config commit -m "feat: initial dotfiles commit"

# Push to remote
config push -u origin main
```

## New System Setup

### Automated Setup

Use the setup script for new installations:

```bash
bash <(curl -s https://raw.githubusercontent.com/Dwarf1er/dotfiles/refs/heads/master/setup.sh) "https://github.com/Dwarf1er/dotfiles.git"
```

### Manual Configuration

If you prefer manual setup on a new system:

```bash
# Create config alias
alias config='/usr/bin/git --git-dir=$HOME/.config/ --work-tree=$HOME'

# Clone the repository
git clone --bare https://github.com/Dwarf1er/dotfiles.git $HOME/.config

# Checkout files (backup existing configs if needed)
config checkout

# If checkout fails due to existing files:
config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} {}.backup
config checkout

# Hide untracked files
config config --local status.showUntrackedFiles no

# Make alias permanent
echo "alias config='/usr/bin/git --git-dir=$HOME/.config/ --work-tree=$HOME'" >> $HOME/.bashrc
```

## Daily Usage

### Common Commands

```bash
# Check status of tracked files
config status

# Add new files to track
config add .config/new-app/config.toml

# Commit changes
config commit -m "Update configuration"

# Push changes
config push

# Pull latest changes
config pull

# View commit history
config log --oneline

# Show differences
config diff
```

## Customizing Packages
The setup script manages packages in three categories within the script itself:

- `REQUIRED_OFFICIAL`: Essential packages from Arch repositories
- `REQUIRED_AUR`: Essential packages from AUR
- `OPTIONAL_PACKAGES`: Optional packages with descriptions, presented during setup

### Modifying Package Lists
To customize what gets installed, edit the arrays in `setup.sh`:
```bash
# Add to required official packages
REQUIRED_OFFICIAL=(
    hyprland
    # ... existing packages
    your-new-package
)

# Add to optional packages with description
declare -A OPTIONAL_PACKAGES=(
    # ... existing packages
    ["your-package"]="Description of package [Official]"
    ["aur-package"]="Description of AUR package [AUR]"
)
```

The `[Official]` or `[AUR]` tags in descriptions determine which package manager is used during installation.

Notes:
- Universal: Anyone can fork this repository, replace the package lists, and re-use the same scripts
- Non-destructive: Your existing configurations are never overwritten without backup. Conflicts are stored in `~/dotfiles-conflicts`
- Interactive: Optional packages are selectable via a TUI (whiptail)
