#!/bin/bash

# HydraUI Pixel Professional Installer
# Version: 2.0.0
# Author: HydraUI Team

set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'

readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Installation paths
readonly THEMES_DIR="/usr/share/themes"
readonly ICONS_DIR="/usr/share/icons"
readonly BACKGROUNDS_DIR="/usr/share/backgrounds/HydraUI"
readonly TEMP_DIR="/tmp/hydraui-install"
readonly EXTENSIONS_DIR="$HOME/.local/share/gnome-shell/extensions"
readonly CONFIG_DIR="$HOME/.config"

# Installation markers
readonly INSTALL_MARKER="$HOME/.hydraui-installed"
readonly VERSION_FILE="$HOME/.hydraui-version"
readonly CURRENT_VERSION="2.0.0"

# Cleanup function
cleanup() {
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

# Set trap for cleanup
trap cleanup EXIT

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%H:%M:%S')
    
    case $level in
        INFO)  echo -e "${BLUE}[${timestamp}]${NC} ${CYAN}INFO${NC}  $message" ;;
        WARN)  echo -e "${BLUE}[${timestamp}]${NC} ${YELLOW}WARN${NC}  $message" ;;
        ERROR) echo -e "${BLUE}[${timestamp}]${NC} ${RED}ERROR${NC} $message" ;;
        SUCCESS) echo -e "${BLUE}[${timestamp}]${NC} ${GREEN}SUCCESS${NC} $message" ;;
    esac
}

# Enhanced spinner with progress indication
spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local msg="$1"
    local counter=0
    
    echo -ne "${CYAN}${msg}${NC} "
    
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf "${PURPLE}%c${NC}" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b"
        ((counter++))
    done
    
    wait $pid
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        printf "${GREEN}✓${NC}\n"
        return 0
    else
        printf "${RED}✗${NC}\n"
        return $exit_code
    fi
}

# Progress bar function
progress_bar() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))
    local remaining=$((width - completed))
    
    printf "\r${CYAN}Progress: ${NC}["
    printf "%${completed}s" | tr ' ' '█'
    printf "%${remaining}s" | tr ' ' '░'
    printf "] ${WHITE}%d%%${NC}" $percentage
}

# Banner display
show_banner() {
    clear
    echo -e "${PURPLE}"
    cat << 'EOF'
    ██╗  ██╗██╗   ██╗██████╗ ██████╗  █████╗ ██╗   ██╗██╗
    ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██╔══██╗██║   ██║██║
    ███████║ ╚████╔╝ ██║  ██║██████╔╝███████║██║   ██║██║
    ██╔══██║  ╚██╔╝  ██║  ██║██╔══██╗██╔══██║██║   ██║██║
    ██║  ██║   ██║   ██████╔╝██║  ██║██║  ██║╚██████╔╝██║
    ╚═╝  ╚═╝   ╚═╝   ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝
                              Professional UI Installer
EOF
    echo -e "${NC}"
    echo -e "${CYAN}Version: ${WHITE}$CURRENT_VERSION${NC}"
    echo -e "${CYAN}Author:  ${WHITE}HydraUI Team${NC}"
    echo
}

# Check if user wants to proceed with installation
confirm_installation() {
    echo -e "${YELLOW}This installer will set up HydraUI Pixel UI theme on your system.${NC}"
    echo -e "${YELLOW}The following components will be installed:${NC}"
    echo "  • Layan GTK Theme"
    echo "  • Candy Icon Pack"
    echo "  • Custom wallpaper"
    echo "  • GNOME Shell extensions"
    echo "  • Conky system monitor"
    echo "  • Multi-language support"
    echo
    
    read -p "$(echo -e ${WHITE}Do you want to continue? [Y/n]: ${NC})" -r response
    case $response in
        [nN][oO]|[nN])
            log INFO "Installation cancelled by user"
            exit 0
            ;;
        *)
            return 0
            ;;
    esac
}

# Check if already installed
check_existing_installation() {
    if [[ -f "$INSTALL_MARKER" ]]; then
        local installed_version="unknown"
        if [[ -f "$VERSION_FILE" ]]; then
            installed_version=$(cat "$VERSION_FILE")
        fi
        
        echo -e "${YELLOW}HydraUI Pixel UI is already installed (version: $installed_version)${NC}"
        echo
        echo "Choose an option:"
        echo "  1) Cancel installation"
        echo "  2) Remove and reinstall"
        echo "  3) Update/repair installation"
        echo
        
        read -p "$(echo -e ${WHITE}Enter your choice [1-3]: ${NC})" -r choice
        
        case $choice in
            1)
                log INFO "Installation cancelled by user"
                exit 0
                ;;
            2)
                log INFO "Removing existing installation..."
                remove_existing_installation
                ;;
            3)
                log INFO "Proceeding with update/repair..."
                ;;
            *)
                log ERROR "Invalid choice. Exiting."
                exit 1
                ;;
        esac
    fi
}

# Remove existing installation
remove_existing_installation() {
    log INFO "Removing existing HydraUI installation..."
    
    # Remove themes
    [[ -d "$THEMES_DIR/Layan-dark" ]] && sudo rm -rf "$THEMES_DIR/Layan"*
    
    # Remove icons
    [[ -d "$ICONS_DIR/Candy" ]] && sudo rm -rf "$ICONS_DIR/Candy"
    
    # Remove backgrounds
    [[ -d "$BACKGROUNDS_DIR" ]] && sudo rm -rf "$BACKGROUNDS_DIR"
    
    # Remove extensions
    [[ -d "$EXTENSIONS_DIR/blur-my-shell@aunetx" ]] && rm -rf "$EXTENSIONS_DIR/blur-my-shell@aunetx"
    [[ -d "$EXTENSIONS_DIR/just-perfection@just-perfection" ]] && rm -rf "$EXTENSIONS_DIR/just-perfection@just-perfection"
    
    # Remove configs
    [[ -f "$CONFIG_DIR/conky/conky.conf" ]] && rm -f "$CONFIG_DIR/conky/conky.conf"
    [[ -f "$CONFIG_DIR/autostart/conky.desktop" ]] && rm -f "$CONFIG_DIR/autostart/conky.desktop"
    
    # Remove markers
    [[ -f "$INSTALL_MARKER" ]] && rm -f "$INSTALL_MARKER"
    [[ -f "$VERSION_FILE" ]] && rm -f "$VERSION_FILE"
    
    log SUCCESS "Previous installation removed"
}

# Check system requirements
check_requirements() {
    log INFO "Checking system requirements..."
    
    # Check if running GNOME
    if [[ "$XDG_CURRENT_DESKTOP" != *"GNOME"* ]]; then
        log ERROR "This installer requires GNOME desktop environment"
        exit 1
    fi
    
    # Check for required commands
    local required_commands=("wget" "git" "make" "gsettings")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log ERROR "Required command not found: $cmd"
            exit 1
        fi
    done
    
    # Check internet connection
    if ! ping -c 1 google.com >/dev/null 2>&1; then
        log ERROR "Internet connection required for installation"
        exit 1
    fi
    
    log SUCCESS "System requirements satisfied"
}

# Install system dependencies
install_dependencies() {
    log INFO "Installing system dependencies..."
    
    (
        sudo apt update >/dev/null 2>&1
        sudo apt install -y gnome-tweaks gnome-shell-extensions playerctl conky-all \
                           fonts-roboto curl unzip git papirus-icon-theme \
                           translate-shell jq make >/dev/null 2>&1
    ) & spinner "Installing system packages"
    
    if [[ $? -ne 0 ]]; then
        log ERROR "Failed to install system dependencies"
        exit 1
    fi
}

# Create language file
create_language_file() {
    log INFO "Generating multi-language support..."
    
    local lang_file="$TEMP_DIR/lang.json"
    
    (
        local languages=(af am ar az be bg bn bs ca cs cy da de el en eo es et eu fa fi fr ga gl gu he hi hr hu hy id is it ja jv ka kk km kn ko ku ky lo lt lv mg mk ml mn mr ms my ne nl no pa pl ps pt ro ru sd si sk sl sq sr su sv sw ta te th tr ug uk ur uz vi xh yi zh zh-CN zh-TW zu)
        
        declare -A base
        base[downloading]="📦 Downloading files..."
        base[done]="✅ Done!"
        base[setting_up]="🎨 Setting up Pixel UI..."
        
        echo "{" > "$lang_file"
        local total=${#languages[@]}
        local current=0
        
        for lang in "${languages[@]}"; do
            echo "  \"$lang\": {" >> "$lang_file"
            for key in downloading done setting_up; do
                local translated
                translated=$(trans -b :$lang "${base[$key]}" 2>/dev/null | sed 's/"/\\"/g') || translated="${base[$key]}"
                echo "    \"$key\": \"$translated\"," >> "$lang_file"
            done
            sed -i '$ s/,$//' "$lang_file"
            echo "  }," >> "$lang_file"
            
            ((current++))
            progress_bar $current $total
        done
        
        sed -i '$ s/,$//' "$lang_file"
        echo "}" >> "$lang_file"
        echo
    ) & spinner "Generating translations"
    
    if [[ $? -ne 0 ]]; then
        log WARN "Failed to generate some translations, using defaults"
    fi
}

# Install theme components
install_theme() {
    log INFO "Installing Layan GTK theme..."
    
    (
        cd "$TEMP_DIR"
        git clone --depth 1 https://github.com/vinceliuice/Layan-gtk-theme.git >/dev/null 2>&1
        cd Layan-gtk-theme
        sudo ./install.sh -d "$THEMES_DIR" >/dev/null 2>&1
    ) & spinner "Installing GTK theme"
    
    [[ $? -ne 0 ]] && { log ERROR "Failed to install GTK theme"; exit 1; }
}

install_icons() {
    log INFO "Installing Candy icon theme..."
    
    (
        cd "$TEMP_DIR"
        git clone --depth 1 https://github.com/eliverlara/candy-icons.git >/dev/null 2>&1
        sudo mv candy-icons "$ICONS_DIR/Candy"
    ) & spinner "Installing icon theme"
    
    [[ $? -ne 0 ]] && { log ERROR "Failed to install icon theme"; exit 1; }
}

install_wallpaper() {
    log INFO "Installing wallpaper..."
    
    (
        sudo mkdir -p "$BACKGROUNDS_DIR"
        sudo wget -q -O "$BACKGROUNDS_DIR/pixel_wallpaper.jpg" \
            "https://images.unsplash.com/photo-1542751110-97427bbecf20?auto=format&fit=crop&w=1920&q=80"
    ) & spinner "Downloading wallpaper"
    
    [[ $? -ne 0 ]] && { log ERROR "Failed to install wallpaper"; exit 1; }
}

install_extensions() {
    log INFO "Installing GNOME Shell extensions..."
    
    mkdir -p "$EXTENSIONS_DIR"
    
    (
        cd "$TEMP_DIR"
        git clone --depth 1 https://github.com/aunetx/blur-my-shell.git >/dev/null 2>&1
        cd blur-my-shell
        make install >/dev/null 2>&1
        
        cd "$TEMP_DIR"
        git clone --depth 1 https://github.com/justperfection/just-perfection.git >/dev/null 2>&1
        cd just-perfection
        make install >/dev/null 2>&1
    ) & spinner "Installing extensions"
    
    [[ $? -ne 0 ]] && { log ERROR "Failed to install extensions"; exit 1; }
}

configure_conky() {
    log INFO "Configuring Conky system monitor..."
    
    mkdir -p "$CONFIG_DIR/conky" "$CONFIG_DIR/autostart"
    
    cat > "$CONFIG_DIR/conky/conky.conf" << 'EOF'
conky.config = {
    alignment = 'top_right',
    background = true,
    update_interval = 1,
    double_buffer = true,
    minimum_width = 300,
    maximum_width = 400,
    own_window = true,
    own_window_type = 'dock',
    own_window_transparent = true,
    own_window_argb_visual = true,
    own_window_argb_value = 100,
    border_inner_margin = 20,
    use_xft = true,
    font = 'Roboto:size=11',
    default_color = '#FFFFFF',
    draw_shades = false,
    gap_x = 20,
    gap_y = 60,
};

conky.text = [[
${time %A, %d %B %Y}
${time %H:%M:%S}

🎵 ${exec playerctl metadata --format '{{title}} - {{artist}}' 2>/dev/null || echo 'No music playing'}
💾 RAM: $mem/$memmax ($memperc%)
🖥️  CPU: ${cpu cpu0}%
]];
EOF

    cat > "$CONFIG_DIR/autostart/conky.desktop" << EOF
[Desktop Entry]
Type=Application
Exec=conky -c $HOME/.config/conky/conky.conf
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=HydraUI Conky
Comment=HydraUI system monitor
EOF
}

apply_settings() {
    log INFO "Applying theme settings..."
    
    # Apply GNOME settings
    gsettings set org.gnome.desktop.interface gtk-theme 'Layan-dark'
    gsettings set org.gnome.desktop.interface icon-theme 'Candy'
    gsettings set org.gnome.shell.extensions.user-theme name 'Layan-dark'
    gsettings set org.gnome.desktop.background picture-uri "file://$BACKGROUNDS_DIR/pixel_wallpaper.jpg"
    gsettings set org.gnome.shell enabled-extensions "['user-theme@gnome-shell-extensions.gcampax.github.com', 'blur-my-shell@aunetx', 'just-perfection@just-perfection']"
    
    # Create installation markers
    echo "$CURRENT_VERSION" > "$VERSION_FILE"
    date '+%Y-%m-%d %H:%M:%S' > "$INSTALL_MARKER"
    
    log SUCCESS "Settings applied successfully"
}

# Main installation function
main_install() {
    local total_steps=5
    local current_step=0
    
    echo -e "${CYAN}Installation Progress:${NC}"
    echo
    
    # Step 1: Dependencies
    ((current_step++))
    echo -e "${WHITE}[$current_step/$total_steps]${NC} Installing dependencies..."
    install_dependencies
    
    # Step 2-5: Downloading UI kits (combined display)
    ((current_step++))
    echo -e "${WHITE}[$current_step/$total_steps]${NC} Downloading UI kits..."
    create_language_file
    install_theme
    install_icons
    install_wallpaper
    install_extensions
    
    # Step 5: Setting up
    ((current_step++))
    echo -e "${WHITE}[$current_step/$total_steps]${NC} Setting up..."
    configure_conky
    apply_settings
    
    ((current_step++))
    echo -e "${WHITE}[$current_step/$total_steps]${NC} Finalizing..."
    sleep 1
    
    ((current_step++))
    echo -e "${WHITE}[$current_step/$total_steps]${NC} Finished!"
    
    echo
    progress_bar $total_steps $total_steps
    echo
}

# Final success message
show_success() {
    echo
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    🎉 Installation Complete! 🎉                        ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${WHITE}HydraUI Pixel UI has been successfully installed and applied!${NC}"
    echo
    echo -e "${CYAN}✓ Theme automatically applied${NC}"
    echo -e "${CYAN}✓ Extensions enabled${NC}"
    echo -e "${CYAN}✓ Wallpaper set${NC}"
    echo -e "${CYAN}✓ Conky configured${NC}"
    echo
    echo -e "${CYAN}Installed components:${NC}"
    echo "  ✓ Layan GTK Theme"
    echo "  ✓ Candy Icon Pack"
    echo "  ✓ Custom Pixel Wallpaper"
    echo "  ✓ Blur My Shell Extension"
    echo "  ✓ Just Perfection Extension"
    echo "  ✓ Conky System Monitor"
    echo "  ✓ Multi-language Support"
    echo
    echo -e "${YELLOW}If some changes are not visible immediately:${NC}"
    echo "  • Press Alt+F2, type 'r' and press Enter to reload GNOME Shell"
    echo "  • Or log out and log back in"
    echo
    echo -e "${GREEN}Enjoy your new HydraUI Pixel theme! 🎨${NC}"
    echo
}

# Main execution
main() {
    # Create temp directory
    mkdir -p "$TEMP_DIR"
    
    # Show banner
    show_banner
    
    # Check for existing installation
    check_existing_installation
    
    # Confirm installation
    confirm_installation
    
    # Check system requirements
    check_requirements
    
    # Run installation
    main_install
    
    # Show success message
    show_success
    
    log SUCCESS "HydraUI Pixel UI installation completed successfully"
}

# Error handling
set -e
trap 'log ERROR "Installation failed at line $LINENO"' ERR

# Run main function
main "$@"
