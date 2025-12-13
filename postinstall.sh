#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

config() {
    /usr/bin/git --git-dir="$HOME/.config/" --work-tree="$HOME" "$@"
}

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
    noto-fonts
    noto-fonts-emoji
    noto-fonts-cjk
    wl-clipboard
    mpv
    gwenview
    starship
    fastfetch
    timeshift
    grub-btrfs
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

    for file in .bashrc README.md setup.sh postinstall.sh dotfiles.sh; do
        if [ -f "$HOME/$file" ]; then
            cp "$HOME/$file" "$backup_dir/"
            log_info "Existing $file backed up to $backup_dir/$file"
        fi
    done
}

setup_dotfiles() {
    local git_repo_url="$1"

    log_info "Setting up dotfiles"
    backup_dotfiles

    if [ ! -d "$HOME/.config" ]; then
        log_info "Cloning dotfiles repository as bare repo"
        git clone --bare "$git_repo_url" "$HOME/.config"
    else
        log_info "Dotfiles repo already exists, fetching updates"
        config fetch origin
    fi

    log_info "Checking out dotfiles"
    if ! config checkout; then
        log_warn "Conflicts detected. Moving conflicting files to ~/dotfiles-conflicts"
        mkdir -p "$HOME/dotfiles-conflicts"

        config checkout 2>&1 \
            | sed -n 's/^\s\+\(.*\)$/\1/p' \
            | while read -r file; do
                mkdir -p "$HOME/dotfiles-conflicts/$(dirname "$file")"
                mv "$HOME/$file" "$HOME/dotfiles-conflicts/$file"
            done

        config checkout
    fi

    config config --local status.showUntrackedFiles no

    sudo ln -sfn "$HOME/.config/tlp/tlp.conf" /etc/tlp.conf

    log_info "Dotfiles setup complete!"
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

setup_snapshots() {
    log_info "Configuring Timeshift automatic snapshots and grub-btrfs"

    if ! sudo btrfs quota show / &>/dev/null; then
        sudo btrfs quota enable /
        log_info "BTRFS quotas enabled"
    else
        log_info "BTRFS quotas already enabled"
    fi

    sudo timeshift --schedule --boot 1 --count 5
    log_info "Timeshift boot snapshots scheduled"

    HOOK_FILE="/etc/pacman.d/hooks/timeshift-pre-update.hook"
    sudo tee "$HOOK_FILE" >/dev/null <<'EOF'
[Trigger]
Operation = Upgrade
Type = Package
Target = *

[Action]
Description = Creating Timeshift BTRFS snapshot before system update
When = PreTransaction
Exec = /usr/bin/timeshift --create --comments "Pre-pacman upgrade" --tags D --delete-old 5
EOF
    log_info "Pacman pre-update hook created at $HOOK_FILE"

    sudo systemctl enable --now grub-btrfs.path
    log_info "grub-btrfs.path service enabled and running"

    sudo grub-mkconfig -o /boot/grub/grub.cfg
    log_info "GRUB menu updated with current snapshots"
}

main() {
    [ "$EUID" -eq 0 ] && { log_error "Do not run this script as root!"; exit 1; }

    local git_repo_url="$1"
    local mode="${2:-full}"

    if [ -z "$git_repo_url" ]; then
        log_error "Usage:"
        echo "  $0 <git-repo-url> [full|dotfiles]"
        exit 1
    fi

    case "$mode" in
        full|dotfiles) ;;
        *)
            log_error "Invalid mode: $mode (use 'full' or 'dotfiles')"
            exit 1
            ;;
    esac

    if [ "$mode" = "full" ]; then
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
        systemctl --user enable pipewire wireplumber
        systemctl --user start pipewire wireplumber

        select_optional_packages
    fi

    setup_dotfiles "$git_repo_url"

    log_info "Refreshing font cache"
    fc-cache -fv

    setup_snapshots
    log_info "Setup complete! Please reboot to apply changes."
}


main "$@"
