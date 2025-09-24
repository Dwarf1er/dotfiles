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

declare -A DEVELOPMENT_OFFICIAL=(
    ["go"]="Golang"
    ["godot"]="Godot Engine"
)

declare -A DEVELOPMENT_AUR=(
    ["neovim-nightly-bin"]="Neovim Nightly"
)

declare -A GAMING_OFFICIAL=(
    ["steam"]="Steam"
)

declare -A GAMING_AUR=()

declare -A MEDIA_OFFICIAL=(
    ["gimp"]="GIMP"
    ["inkscape"]="Inkscape"
    ["obs-studio"]="OBS"
    ["audacity"]="Audacity"
    ["blender"]="Blender"
    ["kdenlive"]="KDEnlive"
)

declare -A MEDIA_AUR=()

declare -A THREED_PRINTING_OFFICIAL=(
    ["freecad"]="FreeCAD"
)

declare -A THREED_PRINTING_AUR=(
    ["orca-slicer-bin"]="Orca Slicer"
)

declare -A OFFICE_OFFICIAL=(
    ["libreoffice-fresh"]="LibreOffice"
)

declare -A OFFICE_AUR=()

declare -A COMMUNICATION_OFFICIAL=(
    ["signal-desktop"]="Signal Messenger"
    ["discord"]="Discord"
)

declare -A COMMUNICATION_AUR=(
    ["vencord-bin"]="Vencord discord client mod"
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

show_category_selection() {
    local categories=$(whiptail --title "Package Categories" \
        --checklist "Select package categories to install:" 18 70 6 \
        "development" "Development tools" OFF \
        "gaming" "Gaming packages" OFF \
        "media" "Media & Graphics tools" OFF \
        "3d-printing" "3D Printing tools" OFF \
        "office" "Office & Productivity" OFF \
        "communication" "Communication apps" OFF \
        3>&1 1>&2 2>&3)
    
    if [ $? -ne 0 ]; then
        log_info "Category selection cancelled."
        return 1
    fi
    
    echo $categories | tr -d '"'
}

select_from_category() {
    local category="$1"
    local official_var="$2"
    local aur_var="$3"
    
    local options=()
    
    local -n official_packages=$official_var
    for pkg in "${!official_packages[@]}"; do
        options+=("$pkg" "${official_packages[$pkg]} [Official]" OFF)
    done
    
    local -n aur_packages=$aur_var
    for pkg in "${!aur_packages[@]}"; do
        options+=("$pkg" "${aur_packages[$pkg]} [AUR]" OFF)
    done
    
    if [ ${#options[@]} -eq 0 ]; then
        log_warn "No packages available for category: $category"
        return 1
    fi
    
    local selections=$(whiptail --title "Select $category Packages" \
        --checklist "Choose specific packages or cancel to install all:" \
        20 80 12 \
        "${options[@]}" \
        3>&1 1>&2 2>&3)
    
    echo $selections | tr -d '"'
}

install_category_packages() {
    local category="$1"
    local official_var="$2"
    local aur_var="$3"
    
    if whiptail --title "Install $category Packages" \
        --yesno "Install ALL $category packages or SELECT specific ones?\n\nYes = Install All\nNo = Select Specific" 10 60; then
        log_info "Installing all $category packages..."
        
        local -n official_packages=$official_var
        local -n aur_packages=$aur_var
        
        if [ ${#official_packages[@]} -gt 0 ]; then
            install_packages "official" "${!official_packages[@]}"
        fi
        
        if [ ${#aur_packages[@]} -gt 0 ]; then
            install_packages "aur" "${!aur_packages[@]}"
        fi
    else
        local selected=$(select_from_category "$category" "$official_var" "$aur_var")
        
        if [ -n "$selected" ]; then
            log_info "Installing selected $category packages..."
            
            local selected_official=()
            local selected_aur=()
            
            IFS=' ' read -ra selected_packages <<< "$selected"
            
            local -n official_packages=$official_var
            local -n aur_packages=$aur_var
            
            for pkg in "${selected_packages[@]}"; do
                if [[ -n "${official_packages[$pkg]:-}" ]]; then
                    selected_official+=("$pkg")
                elif [[ -n "${aur_packages[$pkg]:-}" ]]; then
                    selected_aur+=("$pkg")
                fi
            done
            
            if [ ${#selected_official[@]} -gt 0 ]; then
                install_packages "official" "${selected_official[@]}"
            fi
            
            if [ ${#selected_aur[@]} -gt 0 ]; then
                install_packages "aur" "${selected_aur[@]}"
            fi
        else
            log_info "No packages selected for $category."
        fi
    fi
}

install_optional_packages() {
    local selected_categories=$(show_category_selection)
    
    if [ -z "$selected_categories" ]; then
        log_info "No categories selected."
        return 0
    fi
    
    IFS=' ' read -ra categories <<< "$selected_categories"
    
    for category in "${categories[@]}"; do
        case $category in
            "development")
                install_category_packages "Development" "DEVELOPMENT_OFFICIAL" "DEVELOPMENT_AUR"
                ;;
            "gaming")
                install_category_packages "Gaming" "GAMING_OFFICIAL" "GAMING_AUR"
                ;;
            "media")
                install_category_packages "Media" "MEDIA_OFFICIAL" "MEDIA_AUR"
                ;;
            "3d-printing")
                install_category_packages "3D Printing" "THREED_PRINTING_OFFICIAL" "THREED_PRINTING_AUR"
                ;;
            "office")
                install_category_packages "Office" "OFFICE_OFFICIAL" "OFFICE_AUR"
                ;;
            "communication")
                install_category_packages "Communication" "COMMUNICATION_OFFICIAL" "COMMUNICATION_AUR"
                ;;
        esac
    done
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
    install_optional_packages
    
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
