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

REQUIRED_OFFICIAL=(
    hyprland
    xdg-desktop-portal-hyprland
    qt5-wayland
    qt6-wayland
    wireplumber
    pipewire
    pipewire-pulse
    pipewire-alsa
    kitty
    dolphin
    wofi
    brightnessctl
    playerctl
    git
    ttf-font-awesome
    ttf-d2coding-nerd
)

REQUIRED_AUR=(
    librewolf-bin
    hyprshot
    hyprlock
    waybar
    mako
    hypridle
    hyprpaper
)

# Define optional packages with their descriptions and repo type
declare -A OPTIONAL_PACKAGES=(
    # Development
    ["go"]="Golang programming language [Official]"
    ["godot"]="Godot game engine [Official]"
    ["neovim-nightly-bin"]="Neovim nightly build [AUR]"
    
    # Gaming
    ["steam"]="Steam gaming platform [Official]"
    
    # Media & Graphics
    ["gimp"]="GNU Image Manipulation Program [Official]"
    ["inkscape"]="Vector graphics editor [Official]"
    ["obs-studio"]="Open Broadcaster Software [Official]"
    ["audacity"]="Audio editor [Official]"
    ["blender"]="3D creation suite [Official]"
    ["kdenlive"]="Video editor [Official]"
    
    # 3D Printing
    ["freecad"]="Parametric 3D CAD modeler [Official]"
    ["orca-slicer-bin"]="3D printer slicer [AUR]"
    
    # Office & Productivity
    ["libreoffice-fresh"]="Office suite [Official]"
    
    # Communication
    ["signal-desktop"]="Signal messenger [Official]"
    ["discord"]="Discord chat application [Official]"
    ["vencord-bin"]="Discord client modification [AUR]"
)

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

install_whiptail() {
    if ! command -v whiptail &> /dev/null; then
        log_info "Installing whiptail for package selection..."
        sudo pacman -S --noconfirm libnewt
    fi
}

setup_dotfiles() {
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
    
    log_info "Dotfiles setup complete!"
}

install_required_packages() {
    log_info "Installing required packages..."
    
    log_info "Installing required official packages..."
    install_packages "official" "${REQUIRED_OFFICIAL[@]}"
    
    log_info "Installing required AUR packages..."
    install_packages "aur" "${REQUIRED_AUR[@]}"
}

is_aur_package() {
    local pkg="$1"
    [[ "${OPTIONAL_PACKAGES[$pkg]}" == *"[AUR]"* ]]
}

select_optional_packages() {
    if whiptail --title "Optional Packages" \
        --yesno "Install ALL optional packages or SELECT specific ones?\n\nYes = Install All\nNo = Select Specific" 10 60; then
        
        log_info "Installing all optional packages..."
        
        local official_packages=()
        local aur_packages=()
        
        for pkg in "${!OPTIONAL_PACKAGES[@]}"; do
            if is_aur_package "$pkg"; then
                aur_packages+=("$pkg")
            else
                official_packages+=("$pkg")
            fi
        done
        
        if [ ${#official_packages[@]} -gt 0 ]; then
            install_packages "official" "${official_packages[@]}"
        fi
        
        if [ ${#aur_packages[@]} -gt 0 ]; then
            install_packages "aur" "${aur_packages[@]}"
        fi
            
        return 0
    fi
    
    local whiptail_options=()
    for pkg in "${!OPTIONAL_PACKAGES[@]}"; do
        whiptail_options+=("$pkg" "${OPTIONAL_PACKAGES[$pkg]}" OFF)
    done
    
    local selections=$(whiptail --title "Optional Packages" \
        --checklist "Select packages to install (SPACE=toggle, TAB=navigate, ENTER=confirm):" \
        25 90 15 \
        "${whiptail_options[@]}" \
        3>&1 1>&2 2>&3)
    
    if [ $? -ne 0 ]; then
        log_info "Package selection cancelled."
        return 1
    fi
    
    if [ -z "$selections" ]; then
        log_info "No packages selected."
        return 0
    fi
    
    selections=$(echo "$selections" | tr -d '"')
    IFS=' ' read -ra selected_packages <<< "$selections"
    
    local official_packages=()
    local aur_packages=()
    
    for pkg in "${selected_packages[@]}"; do
        if is_aur_package "$pkg"; then
            aur_packages+=("$pkg")
        else
            official_packages+=("$pkg")
        fi
    done
    
    if [ ${#official_packages[@]} -gt 0 ]; then
        log_info "Installing selected official packages: ${official_packages[*]}"
        install_packages "official" "${official_packages[@]}"
    fi
    
    if [ ${#aur_packages[@]} -gt 0 ]; then
        log_info "Installing selected AUR packages: ${aur_packages[*]}"
        install_packages "aur" "${aur_packages[@]}"
    fi
    
    log_info "Selected package installation complete!"
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
    install_packages "official" git base-devel
    
    install_paru
    install_whiptail
    
    install_required_packages
    select_optional_packages
    
    setup_dotfiles "$git_repo_url"
    
    log_info "Enabling services..."
    sudo systemctl --user enable pipewire
    sudo systemctl enable --now pipewire-pulse wireplumber
    
    log_info "Refreshing font cache..."
    fc-cache -fv
    
    log_info "Setup complete! Please reboot to ensure all changes take effect."
}

if [ "$EUID" -eq 0 ]; then
    log_error "Please do not run this script as root!"
    exit 1
fi

main "$@"
