#!/usr/bin/env bash
set -euo pipefail

error() { echo "Error: $1" >&2; exit 1; }
info()  { echo "==> $1"; }

# ------------------------------
# Step 0: Update system
# ------------------------------
info "Updating system..."
sudo pacman -Syu

# ------------------------------
# Step 1: Ensure git is installed
# ------------------------------
if ! command -v git &>/dev/null; then
    info "Installing git..."
    sudo pacman -S git
fi

# ------------------------------
# Step 2: Install paru (AUR helper) if missing
# ------------------------------
if ! command -v paru &>/dev/null; then
    info "Installing paru..."
    TEMP_DIR=$(mktemp -d)
    git clone https://aur.archlinux.org/paru.git "$TEMP_DIR/paru"
    cd "$TEMP_DIR/paru"
    makepkg -si
    cd -
    rm -rf "$TEMP_DIR"
fi

# ------------------------------
# Step 3: NVIDIA drivers if GPU detected
# ------------------------------
# if lspci | grep -i nvidia &>/dev/null; then
#    info "NVIDIA GPU detected. Installing drivers..."
#     sudo pacman -S --needed nvidia nvidia-utils lib32-nvidia-utils xorg-xwayland
#    info "Make sure 'nvidia-drm.modeset=1' is in your GRUB kernel parameters"
# else
#     info "No NVIDIA GPU detected, skipping drivers"
# fi

# ------------------------------
# Step 4: Install Hyprland + utilities
# ------------------------------
CORE_PKGS=(
    hyprland hyprlock hyprpaper hypridle hyprcursor
    uwsm waybar wofi dunst kitty thunar qt6ct-kde nwg-look
)
UTIL_PKGS=(
    pavucontrol blueman nm-connection-editor starship brightnessctl
    slurp grim wl-clipboard bat fzf zoxide eza power-profiles-daemon
    breeze breeze-gtk otf-font-awesome ttf-terminus-nerd
)

info "Installing core Hyprland packages..."
paru -S --needed "${CORE_PKGS[@]}"

info "Installing utility packages..."
paru -S --needed "${UTIL_PKGS[@]}"

# ------------------------------
# Step 5: Enable services
# ------------------------------
info "Enabling power-profiles-daemon..."
sudo systemctl enable power-profiles-daemon --now || true

# ------------------------------
# Step 6: Clone your dotfiles
# ------------------------------
DOTFILES_REPO="https://github.com/icykcypher/Hyprland-dotfiles.git"
DOTFILES_DIR="$HOME/Hyprland-dotfiles"

if [ -d "$DOTFILES_DIR" ]; then
    info "Dotfiles repo already exists. Pulling latest changes..."
    git -C "$DOTFILES_DIR" pull
else
    info "Cloning dotfiles from GitHub..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

# ------------------------------
# Step 7: Set NVIDIA Wayland env if GPU
# ------------------------------
#ENV_FILE="$HOME/.config/hypr/env.conf"
#mkdir -p "$(dirname "$ENV_FILE")"

#if lspci | grep -i nvidia &>/dev/null; then
#    info "Writing NVIDIA environment variables..."
#    cat > "$ENV_FILE" <<'EOF'
# NVIDIA Wayland environment variables
#export WLR_NO_HARDWARE_CURSORS=1
#export GBM_BACKEND=nvidia-drm
#export __GLX_VENDOR_LIBRARY_NAME=nvidia
#EOF
#fi

# ------------------------------
# Step 8: Activate dotfiles
# ------------------------------
CONFIG_DIR="$HOME/.config"
info "Installing dotfiles..."

for d in hypr kitty waybar; do
    TARGET="$CONFIG_DIR/$d"
    [ -d "$TARGET" ] && mv "$TARGET" "$TARGET.bak"
    ln -s "$DOTFILES_DIR/config/$d" "$TARGET"
done

[ -f "$CONFIG_DIR/starship.toml" ] && mv "$CONFIG_DIR/starship.toml" "$CONFIG_DIR/starship.toml.bak"
ln -s "$DOTFILES_DIR/config/starship.toml" "$CONFIG_DIR/starship.toml"

[ -f "$CONFIG_DIR/start.sh" ] && mv "$CONFIG_DIR/start.sh" "$CONFIG_DIR/start.sh.bak"
ln -s "$DOTFILES_DIR/config/start.sh" "$CONFIG_DIR/start.sh"

[ -f "$HOME/.bashrc" ] && mv "$HOME/.bashrc" "$HOME/.bashrc.bak"
ln -s "$DOTFILES_DIR/bashrc" "$HOME/.bashrc"

[ -f "$HOME/.bash_profile" ] && mv "$HOME/.bash_profile" "$HOME/.bash_profile.bak"
ln -s "$DOTFILES_DIR/bash_profile" "$HOME/.bash_profile"

info "Dotfiles installed successfully."

# ------------------------------
# Step 9: Optional tips
# ------------------------------
info "Optional: install reflector and pacman-contrib for mirror management"
info "Optional: use grub-customizer to apply a custom GRUB theme"

info "Bootstrap complete! Reboot your system for full effect."
