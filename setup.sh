#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

REQUIRED_OFFICIAL=(
    openssh
    hyprland
    archlinux-xdg-menu
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    ly
    qt5-wayland
    qt6-wayland
    qt6ct
    adw-gtk-theme
    wireplumber
    pipewire
    pipewire-pulse
    pipewire-alsa
    networkmanager
    kitty
    dolphin
    wofi
    brightnessctl
    playerctl
    git
    ttf-font-awesome
    ttf-d2coding-nerd
    wl-clipboard
    mpv
    gwenview
    starship
    fastfetch
)

REQUIRED_AUR=(
    librewolf-bin
    hyprshot
    hyprlock
    waybar
    mako
    wlogout
    hypridle
    hyprpaper
    hyprpicker
    pwvucontrol
    nmgui-bin
)

declare -A OPTIONAL_PACKAGES=(
    ["go"]="Golang programming language [Official]"
    ["godot"]="Godot game engine [Official]"
    ["neovim-nightly-bin"]="Neovim nightly build [AUR]"
    ["steam"]="Steam gaming platform [Official]"
    ["gimp"]="GNU Image Manipulation Program [Official]"
    ["inkscape"]="Vector graphics editor [Official]"
    ["obs-studio"]="Open Broadcaster Software [Official]"
    ["audacity"]="Audio editor [Official]"
    ["blender"]="3D creation suite [Official]"
    ["kdenlive"]="Video editor [Official]"
    ["freecad"]="Parametric 3D CAD modeler [Official]"
    ["orca-slicer-bin"]="3D printer slicer [AUR]"
    ["libreoffice-fresh"]="Office suite [Official]"
    ["brave-bin"]="Brave browser [AUR]"
    ["signal-desktop"]="Signal messenger [Official]"
    ["vesktop"]="Vesktop discord client [AUR]"
    ["tlp"]="TLP battery optimization [Official]"
    ["tlp-rdw"]="Radio devices optimization [Official]"
    ["smartmontools"]="Disk optimization [Official]"
    ["ethtool"]="Ethernet optimization [Official]"
)

install_packages() {
    local repo="$1"; shift
    for pkg in "$@"; do
        if ! pacman -Qs "^${pkg}$" &>/dev/null; then
            log_info "Installing $pkg"
            if [ "$repo" = "aur" ]; then
                paru -S --noconfirm "$pkg"
            else
                sudo pacman -S --noconfirm "$pkg"
            fi
        else
            log_info "$pkg is already installed."
        fi
    done
}

install_paru() {
    if ! command -v paru &>/dev/null; then
        log_info "Installing paru AUR helper"
        sudo pacman -S --needed base-devel git --noconfirm
        tmpdir=$(mktemp -d)
        git clone https://aur.archlinux.org/paru.git "$tmpdir/paru"
        cd "$tmpdir/paru"
        makepkg -si --noconfirm
        cd ~
        rm -rf "$tmpdir"
    fi
}

install_whiptail() {
    if ! command -v whiptail &>/dev/null; then
        log_info "Installing whiptail"
        sudo pacman -S --noconfirm libnewt
    fi
}

backup_dotfiles() {
    local backup_dir="$HOME/dotfiles-backup-$(date +%Y%m%d%H%M%S)"
    mkdir -p "$backup_dir"
    if [ -d "$HOME/.config" ]; then cp -r "$HOME/.config" "$backup_dir/"; fi
    for f in .bashrc README.md setup.sh; do [ -f "$HOME/$f" ] && cp "$HOME/$f" "$backup_dir/"; done
}

setup_dotfiles() {
    local git_repo_url="$1"
    log_info "Setting up dotfiles"
    backup_dotfiles
    git clone --bare "$git_repo_url" "$HOME/.config"
    config() { /usr/bin/git --git-dir="$HOME/.config/" --work-tree="$HOME" "$@"; }
    if ! config checkout 2>&1; then
        log_warn "Conflicts detected. Moving existing files to $HOME/dotfiles-conflicts"
        mkdir -p "$HOME/dotfiles-conflicts"
        config checkout 2>&1 | grep -E "\s+\." | awk '{print $1}' | while read -r file; do mv "$HOME/$file" "$HOME/dotfiles-conflicts/"; done
        config checkout
    fi
    config config --local status.showUntrackedFiles no
    sudo mkdir -p /boot/loader
    sudo ln -sfn "$HOME/.config/system-config/boot/loader/loader.conf" /boot/loader/loader.conf
    sudo ln -sfn "$HOME/.config/tlp/tlp.conf" /etc/tlp.conf
    sudo mv /etc/xdg/menus/arch-applications.menu /etc/xdg/menus/applications.menu || true
}

is_aur_package() { [[ "${OPTIONAL_PACKAGES[$1]}" == *"[AUR]"* ]]; }

enable_multilib_if_needed() {
    for pkg in "$@"; do
        [[ "$pkg" == "steam" ]] && {
            log_info "Steam selected: enabling multilib"
            sudo sed -i '/^\#\[multilib\]/, /^\#Include = \/etc\/pacman.d\/mirrorlist/ s/^\#//' /etc/pacman.conf
            sudo pacman -Sy --noconfirm
            return
        }
    done
}

select_optional_packages() {
    if whiptail --title "Optional Packages" --yesno "Install ALL optional packages or SELECT specific ones?\nYes = All, No = Select" 10 60; then
        log_info "Installing all optional packages"
        local official=() aur=()
        for pkg in "${!OPTIONAL_PACKAGES[@]}"; do
            is_aur_package "$pkg" && aur+=("$pkg") || official+=("$pkg")
        done
        enable_multilib_if_needed "${official[@]}"
        install_packages "official" "${official[@]}"
        install_packages "aur" "${aur[@]}"
        return
    fi

    local whiptail_opts=()
    for pkg in "${!OPTIONAL_PACKAGES[@]}"; do
        whiptail_opts+=("$pkg" "${OPTIONAL_PACKAGES[$pkg]}" OFF)
    done

    local selections
    selections=$(whiptail --title "Optional Packages" --checklist "Select packages (SPACE=toggle, ENTER=confirm):" 25 90 15 "${whiptail_opts[@]}" 3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && { log_info "Package selection cancelled."; return; }

    [ -z "$selections" ] && { log_info "No optional packages selected."; return; }

    selections=$(echo "$selections" | tr -d '"')
    IFS=' ' read -ra selected <<< "$selections"

    local official=() aur=()
    for pkg in "${selected[@]}"; do
        is_aur_package "$pkg" && aur+=("$pkg") || official+=("$pkg")
    done

    enable_multilib_if_needed "${official[@]}"
    [ ${#official[@]} -gt 0 ] && install_packages "official" "${official[@]}"
    [ ${#aur[@]} -gt 0 ] && install_packages "aur" "${aur[@]}"
}

main() {
    [ "$EUID" -eq 0 ] && { log_error "Do not run this script as root!"; exit 1; }
    [ -z "$1" ] && { echo "Usage: $0 <git-repo-url>"; exit 1; }
    local git_repo_url="$1"

    log_info "Updating system"
    sudo pacman -Syu --noconfirm

    log_info "Installing essential packages"
    install_packages "official" git base-devel

    install_paru
    install_whiptail

    log_info "Installing required packages"
    install_packages "official" "${REQUIRED_OFFICIAL[@]}"
    install_packages "aur" "${REQUIRED_AUR[@]}"

    log_info "Enabling and starting PipeWire and WirePlumber services"
    systemctl --user enable pipewire
    systemctl --user start pipewire
    systemctl --user enable wireplumber
    systemctl --user start wireplumber

    select_optional_packages
    setup_dotfiles "$git_repo_url"

    log_info "Refreshing font cache"
    fc-cache -fv

    log_info "Setup complete! Please reboot to apply changes."
}

main "$@"
