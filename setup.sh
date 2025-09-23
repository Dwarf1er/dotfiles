#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

install_packages() {
    local repo="$1"
    shift
    for package in "$@"; do
        if ! pacman -Qs "^${package}$" &> /dev/null; then
            log_info "$package is not installed. Installing $package..."
            if [ "$repo" = "aur" ]; then
                paru -S --noconfirm "$package"
            else
                sudo pacman -S --noconfirm "$package"
            fi
        else
            log_info "$package is already installed."
        fi
    done
}

install_paru() {
    if ! command -v paru &> /dev/null; then
        log_info "Installing paru AUR helper..."
        sudo pacman -S --needed base-devel git
        cd /tmp
        git clone https://aur.archlinux.org/paru.git
        cd paru
        makepkg -si --noconfirm
        cd ~
        rm -rf /tmp/paru
    else
        log_info "paru is already installed."
    fi
}

setup_dotfiles() {
    local git_repo_url="$1"
    
    log_info "Setting up dotfiles..."
    
    rm -rf $HOME/.config
    rm -f $HOME/.bashrc
    
    git clone --bare "$git_repo_url" $HOME/.config
    
    config() {
        /usr/bin/git --git-dir=$HOME/.config/ --work-tree=$HOME "$@"
    }
    
    config checkout
    
    config config --local status.showUntrackedFiles no
    
    log_info "Dotfiles setup complete!"
}

main() {
    if [ -z "$1" ]; then
        echo "Usage: $0 <git-repo-url>"
        exit 1
    fi
    
    local git_repo_url="$1"
    
    log_info "Starting full system setup..."
    
    log_info "Updating system..."
    sudo pacman -Syu --noconfirm
    
    log_info "Installing essential packages..."
    install_packages "official" git
    
    install_paru
    
    log_info "Installing Hyprland and Wayland packages..."
    install_packages "official" \
        hyprland \
        xdg-desktop-portal-hyprland \
        qt5-wayland \
        qt6-wayland \
        wireplumber \
        pipewire \
        pipewire-pulse \
        pipewire-alsa
    
    log_info "Installing applications..."
    install_packages "official" \
        kitty \
        dolphin \
        wofi \
        brightnessctl \
        playerctl
    
    log_info "Installing AUR packages..."
    install_packages "aur" \
        librewolf-bin \
        hyprshot \
        hyprlock \
        waybar \
        mako \
        hypridle \
        hyprpaper
    
    log_info "Installing additional useful packages..."
    install_packages "official" \
        discord \
        gimp \
        inkscape \
    
    setup_dotfiles "$git_repo_url"
    
    log_info "Enabling services..."
    sudo systemctl enable --now pipewire pipewire-pulse wireplumber
    
    log_info "Setup complete! Please reboot to ensure all changes take effect."
    log_warn "After reboot, you may need to configure your display manager to use Hyprland."
}

if [ "$EUID" -eq 0 ]; then
    log_error "Please do not run this script as root!"
    exit 1
fi

main "$@"
