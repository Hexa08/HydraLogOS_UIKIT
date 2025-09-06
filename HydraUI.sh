#!/bin/bash
# HydraUI Professional UI Installer
# Version: 2.0.0
# Author: Hexa Innovate Org

set -euo pipefail
trap 'log ERROR "Installation failed at line $LINENO"; exit 1' ERR
trap 'log WARN "Installation interrupted by user"; exit 2' INT

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m'

# Paths
readonly THEMES_DIR="/usr/share/themes"
readonly ICONS_DIR="/usr/share/icons"
readonly BACKGROUNDS_DIR="/usr/share/backgrounds/HydraUI-Professional"
readonly TEMP_DIR="/tmp/hydraui-install"
readonly EXTENSIONS_DIR="$HOME/.local/share/gnome-shell/extensions"
readonly CONFIG_DIR="$HOME/.config"
readonly INSTALL_MARKER="$HOME/.hydraui-installed"
readonly VERSION_FILE="$HOME/.hydraui-version"
readonly CURRENT_VERSION="2.0.0"

# Logging
log() {
    local level="$1"; shift
    local msg="$*"
    local timestamp=$(date '+%H:%M:%S')
    case "$level" in
        INFO) echo -e "${BLUE}[${timestamp}]${NC} ${CYAN}INFO${NC}  $msg" ;;
        WARN) echo -e "${BLUE}[${timestamp}]${NC} ${YELLOW}WARN${NC}  $msg" ;;
        ERROR) echo -e "${BLUE}[${timestamp}]${NC} ${RED}ERROR${NC} $msg" ;;
        SUCCESS) echo -e "${BLUE}[${timestamp}]${NC} ${GREEN}SUCCESS${NC} $msg" ;;
    esac
}

# Spinner for background tasks
spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local msg="$1"
    echo -ne "${CYAN}${msg}${NC} "
    while kill -0 "$pid" 2>/dev/null; do
        printf "%c" "${spinstr:0:1}"
        spinstr=${spinstr:1}${spinstr:0:1}
        sleep $delay
        printf "\b"
    done
    wait $pid
    [[ $? -eq 0 ]] && echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}"
}

# Cleanup temp
cleanup() { [[ -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"; }
trap cleanup EXIT

# Banner
show_banner() {
    clear
    echo -e "${PURPLE}
██╗  ██╗██╗   ██╗██████╗ ██████╗  █████╗ ██╗   ██╗██╗
██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██╔══██╗██║   ██║██║
███████║ ╚████╔╝ ██║  ██║██████╔╝███████║██║   ██║██║
██╔══██║  ╚██╔╝  ██║  ██║██╔══██╗██╔══██║██║   ██║██║
██║  ██║   ██║   ██████╔╝██║  ██║██║  ██║╚██████╔╝██║
╚═╝  ╚═╝   ╚═╝   ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝
                              Professional UI Installer
${NC}"
    echo -e "${CYAN}Version: ${WHITE}$CURRENT_VERSION${NC}"
    echo -e "${CYAN}Author:  ${WHITE}Hexa Innovate Org${NC}\n"
}

# Confirm installation
confirm_installation() {
    echo -e "${YELLOW}This will install HydraUI Professional UI components:${NC}
  • Layan GTK Theme
  • Candy Icon Pack
  • Custom Wallpaper
  • GNOME Shell Extensions
  • Conky System Monitor
  • Multi-language Support
"
    read -rp "$(echo -e ${WHITE}Continue? [Y/n]: ${NC})" response
    [[ "$response" =~ ^[nN] ]] && log INFO "Installation cancelled" && exit 0
}

# Check GNOME and commands
check_requirements() {
    log INFO "Checking system requirements..."
    [[ "$XDG_CURRENT_DESKTOP" != *GNOME* ]] && log ERROR "GNOME required" && exit 1
    for cmd in wget git make gsettings; do 
        command -v $cmd >/dev/null 2>&1 || { log ERROR "$cmd missing"; exit 1; }
    done
    ping -c1 google.com >/dev/null 2>&1 || { log ERROR "Internet required"; exit 1; }
    log SUCCESS "System requirements OK"
}

# Install dependencies
install_dependencies() {
    log INFO "Installing dependencies..."
    (sudo apt update >/dev/null 2>&1 && sudo apt install -y \
        gnome-tweaks gnome-shell-extensions playerctl conky-all fonts-roboto curl unzip git \
        papirus-icon-theme translate-shell jq make >/dev/null 2>&1) & spinner "Installing packages"
}

# Theme install
install_theme() {
    log INFO "Installing Layan GTK theme..."
    (git clone --depth 1 https://github.com/vinceliuice/Layan-gtk-theme.git "$TEMP_DIR/Layan" >/dev/null 2>&1 && \
     sudo "$TEMP_DIR/Layan/install.sh" -d "$THEMES_DIR" >/dev/null 2>&1) & spinner "Installing GTK theme"
}

# Icon install
install_icons() {
    log INFO "Installing Candy icons..."
    (git clone --depth 1 https://github.com/eliverlara/candy-icons.git "$TEMP_DIR/candy" >/dev/null 2>&1 && \
     sudo mv "$TEMP_DIR/candy" "$ICONS_DIR/Candy") & spinner "Installing icons"
}

# Wallpaper
install_wallpaper() {
    log INFO "Installing wallpaper..."
    (sudo mkdir -p "$BACKGROUNDS_DIR" && \
     sudo wget -q -O "$BACKGROUNDS_DIR/professional_wallpaper.jpg" \
        "https://images.unsplash.com/photo-1542751110-97427bbecf20?auto=format&fit=crop&w=1920&q=80") & spinner "Downloading wallpaper"
}

# Extensions
install_extensions() {
    log INFO "Installing GNOME Shell extensions..."
    mkdir -p "$EXTENSIONS_DIR"
    (git clone --depth 1 https://github.com/aunetx/blur-my-shell.git "$TEMP_DIR/blur" >/dev/null 2>&1 && \
     cd "$TEMP_DIR/blur" && make install >/dev/null 2>&1) & spinner "Installing blur-my-shell"
    
    (git clone --depth 1 https://github.com/justperfection/just-perfection.git "$TEMP_DIR/just" >/dev/null 2>&1 && \
     cd "$TEMP_DIR/just" && make install >/dev/null 2>&1) & spinner "Installing just-perfection"
}

# Conky
configure_conky() {
    log INFO "Configuring Conky..."
    mkdir -p "$CONFIG_DIR/conky" "$CONFIG_DIR/autostart"
    cat > "$CONFIG_DIR/conky/conky.conf" <<'EOF'
conky.config = { alignment='top_right', background=true, update_interval=1, double_buffer=true, minimum_width=300, maximum_width=400,
own_window=true, own_window_type='dock', own_window_transparent=true, own_window_argb_visual=true, own_window_argb_value=100,
border_inner_margin=20, use_xft=true, font='Roboto:size=11', default_color='#FFFFFF', draw_shades=false, gap_x=20, gap_y=60 }
conky.text = [[
${time %A, %d %B %Y}
${time %H:%M:%S}
🎵 ${exec playerctl metadata --format '{{title}} - {{artist}}' 2>/dev/null || echo 'No music playing'}
💾 RAM: $mem/$memmax ($memperc%)
🖥️ CPU: ${cpu cpu0}%
]]
EOF
    cat > "$CONFIG_DIR/autostart/conky.desktop" <<EOF
[Desktop Entry]
Type=Application
Exec=conky -c $CONFIG_DIR/conky/conky.conf
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=HydraUI System Monitor
Comment=HydraUI Professional system monitor
EOF
}

# Apply settings
apply_settings() {
    log INFO "Applying settings..."
    gsettings set org.gnome.desktop.interface gtk-theme 'Layan-dark'
    gsettings set org.gnome.desktop.interface icon-theme 'Candy'
    gsettings set org.gnome.shell.extensions.user-theme name 'Layan-dark'
    gsettings set org.gnome.desktop.background picture-uri "file://$BACKGROUNDS_DIR/professional_wallpaper.jpg"
    gsettings set org.gnome.shell enabled-extensions "['user-theme@gnome-shell-extensions.gcampax.github.com','blur-my-shell@aunetx','just-perfection@just-perfection']"
    echo "$CURRENT_VERSION" > "$VERSION_FILE"
    date '+%Y-%m-%d %H:%M:%S' > "$INSTALL_MARKER"
    log SUCCESS "Settings applied"
}

# Success message
show_success() {
    echo
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    🎉 Installation Complete! 🎉                        ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${WHITE}HydraUI Professional has been successfully installed!${NC}"
    echo
    echo -e "${CYAN}✓ Theme applied${NC}"
    echo -e "${CYAN}✓ Extensions enabled${NC}"
    echo -e "${CYAN}✓ Wallpaper set${NC}"
    echo -e "${CYAN}✓ Conky configured${NC}"
    echo
    echo -e "${GREEN}Enjoy your new HydraUI Professional theme! 🎨${NC}"
    echo
}

# Main installer
main() {
    mkdir -p "$TEMP_DIR"
    show_banner
    check_existing_installation
    confirm_installation
    check_requirements
    install_dependencies
    install_theme
    install_icons
    install_wallpaper
    install_extensions
    configure_conky
    apply_settings
    show_success
    log SUCCESS "HydraUI Professional installation completed!"
}

main "$@"
