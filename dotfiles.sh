#!/bin/bash
git_repo_url="$1"

log_info() { echo -e "\033[0;32m[INFO]\033[0m $1"; }
log_warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }
log_error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }

backup_dotfiles() {
    local backup_dir="$HOME/dotfiles-backup-$(date +%Y%m%d%H%M%S)"
    mkdir -p "$backup_dir"

    if [ -d "$HOME/.config" ]; then
        cp -r "$HOME/.config" "$backup_dir/"
        log_info "Existing .config backed up to $backup_dir/.config"

        rm -rf "$HOME/.config"
        log_info "Removed existing .config"
    fi

    for file in .bashrc README.md setup.sh; do
        if [ -f "$HOME/$file" ]; then
            cp "$HOME/$file" "$backup_dir/"
            log_info "Existing $file backed up to $backup_dir/$file"
        fi
    done
}

main() {
    if [ -z "$git_repo_url" ]; then
        log_error "Usage: $0 <git-repo-url>"
        exit 1
    fi

    log_info "Backing up existing dotfiles"
    backup_dotfiles

    log_info "Cloning dotfiles repository as bare repo"
    git clone --bare "$git_repo_url" "$HOME/.config"

    config() { /usr/bin/git --git-dir="$HOME/.config/" --work-tree="$HOME" "$@"; }

    log_info "Checking out dotfiles"
    if ! config checkout 2>&1; then
        log_warn "Conflicts detected. Moving existing files to $HOME/dotfiles-conflicts"
        mkdir -p "$HOME/dotfiles-conflicts"
        config checkout 2>&1 | grep -E "\s+\." | awk '{print $1}' | while read -r file; do
            mv "$HOME/$file" "$HOME/dotfiles-conflicts/"
        done
        config checkout
    fi

    config config --local status.showUntrackedFiles no

    sudo mkdir -p /boot/loader
    sudo ln -sfn "$HOME/.config/system-config/boot/loader/loader.conf" /boot/loader/loader.conf
    sudo ln -sfn "$HOME/.config/tlp/tlp.conf" /etc/tlp.conf

    log_info "Dotfiles setup complete!"
}

main
