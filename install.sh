#!/bin/bash

if [[ $EUID -ne 0 ]]; then
      echo "This script must be run as root. Use sudo." >&2
      exit 1
fi

BOLD='\e[1m'
GREEN='\e[32m'zSs
RED='\e[31m'
BLUE='\e[34m'
PINK='\e[35m'
RESET='\e[0m'

printf '\033[H\033[2J'

echo -e "
${BOLD}${PINK}
██╗    ██╗██╗   ██╗██████╗ ██████╗ 
██║    ██║╚██╗ ██╔╝██╔══██╗██╔══██╗
██║ █╗ ██║ ╚████╔╝ ██████╔╝██████╔╝
██║███╗██║  ╚██╔╝  ██╔═══╝ ██╔══██╗
╚███╔███╔╝   ██║   ██║     ██║  ██║
 ╚══╝╚══╝    ╚═╝   ╚═╝     ╚═╝  ╚═╝${RESET}
"


LOG_FILE="wypr.log"


#############################
# gum install
#############################
{
      echo '[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key' | sudo tee /etc/yum.repos.d/charm.repo >> "$LOG_FILE" 2>&1

      sudo rpm --import https://repo.charm.sh/yum/gpg.key >> "$LOG_FILE" 2>&1
      sudo dnf install -y gum >> "$LOG_FILE" 2>&1
} || {
      echo -e "${RED}gum not installed${RESET}"
}

if gum confirm "Begin WYPR installation?"; then
      echo -e "${GREEN}${BOLD}${RESET}"
else
      echo -e "${RED}${BOLD}Aborting -> ${RESET}"
      exit 1
fi





#############################
# package installation (dnf)
#############################

# packages
packages=(
      "hyprland" # from solopasha/hyprland
      "waypaper" # from solopasha/hyprland
      "wget"
      "unzip"
      "gum"
      "rsync"
      "git"
      "waybar"
      "pavucontrol"
      "rofi-wayland"
      "alacritty"
      "wlogout"
      "dunst"
      "xdg-desktop-portal-hyprland"
      "hyprpaper"
      "hyprlock"
      "firefox"
      "feh"
      "htop"
      "btop"
      "procs"
      "papirus-icon-theme"
      "bat"
      "blueman"
      "nvim"
      "zoxide"
      "fzf"
      "NetworkManager-tui"
      "fontawesome4-fonts"
      "fira-code-fonts"
      "mozilla-fira-sans-fonts"
      "vim"
      "gh"
      "fastfetch"
      "gtk4"
      "libadwaita"
      "jq"
      "python-gobject"
      "nwg-look"
      "grimblast"
)


echo
echo -e "${PINK}${BOLD}Packages to be installed -> ${RESET}"
echo
printf '%s\n' "${packages[@]}" | sort
echo

gum spin --title "Review packages -> " -- sleep 5

echo
if gum confirm "Proceed?"; then
      gum spin --title "Installing packages -> " -- sleep 1
      echo -e "${PINK}${BOLD}Installing packages -> ${RESET}"
      echo
else
      echo -e "${RED}${BOLD}Aborting -> ${RESET}"
      exit 1
fi

# add solopasha/hyprland 
if ! sudo dnf -y copr enable solopasha/hyprland >> "$LOG_FILE" 2>&1; then
      echo -e "${RED}Unable to add solopasha/hyprland${RESET}"
      echo -e "${RED}Attempt to add manually and run script again${RESET}"
      exit 1
fi

# update and upgrade
sudo dnf update -y >> "$LOG_FILE" 2>&1 && sudo dnf upgrade -y >> "$LOG_FILE" 2>&1

# get package name length for building table
max_length=0
for package in "${packages[@]}" "starship" "jetbrains-mono-nf" "msfonts"; do
      if (( ${#package} > max_length )); then
            max_length=${#package}
      fi
done

extra_padding=5
package_col_width=$((max_length + extra_padding))
status_col_width=10
separator=" |          "
divider_length=$((package_col_width + ${#separator} + status_col_width))
divider=$(printf "%-${divider_length}s" " " | tr ' ' '-')

# print table headers
printf "%b%-${package_col_width}s%b%s%b%-${status_col_width}s%b\n" \
      "${WHITE}${BOLD}" "Package" "${RESET}" "$separator" "${WHITE}${BOLD}" "Installed" "${RESET}"
printf "%b%s%b\n" "${WHITE}" "$divider" "${RESET}"

# install function
install_package() {
      package=$1
      package_color="${GREEN}"
      status="${GREEN}✔${RESET}"
      if ! rpm -q "$package" &> /dev/null; then
            if ! sudo dnf install -y "$package" &> /dev/null; then
                  package_color="${RED}"
                  status="${RED}✘${RESET}"
            fi
      fi

# print results
      printf "%b%-${package_col_width}s%b%s%b%-${status_col_width}s\n" \
            "$package_color" "$package" "${RESET}" "$separator" "$status"
}

for package in $(printf '%s\n' "${packages[@]}" | sort); do
      install_package "$package"
done

# misc packages installs function
install_misc() {
      package=$1
      command=$2
      verify_cmd=$3
      package_color="${GREEN}"
      status="${GREEN}✔${RESET}"

      eval "$command" &> /dev/null
      sleep 2
      if ! eval "$verify_cmd" &> /dev/null; then
            package_color="${RED}"
            status="${RED}✘${RESET}"
      fi

      # print results to table
      printf "%b%-${package_col_width}s%b%s%b%-${status_col_width}s\n" \
            "$package_color" "$package" "${RESET}" "$separator" "$status"
}

# get current user
if [[ $SUDO_USER ]]; then
      CURRENT_USER=$SUDO_USER
else
      CURRENT_USER=$(whoami)
fi
USER_HOME=$(eval echo ~$CURRENT_USER)

# misc installs
install_misc "starship" "curl -sS https://starship.rs/install.sh | sh -s -- -f" "command -v starship"
install_misc "jetbrains-mono-nf" "mkdir -p /home/$CURRENT_USER/.local/share/fonts && curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.tar.xz -o JetBrainsMono.tar.xz && tar -xf JetBrainsMono.tar.xz -C /home/$CURRENT_USER/.local/share/fonts && rm JetBrainsMono.tar.xz && fc-cache -fv" "fc-list | grep -i 'JetBrainsMono' || ls /home/$CURRENT_USER/.local/share/fonts | grep -i 'JetBrainsMono'"
install_misc "msfonts" "sudo dnf install -y curl cabextract xorg-x11-font-utils fontconfig && sudo rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm" "fc-list | grep -i 'Arial' || ls /usr/share/fonts | grep -i 'msttcore'"



#############################
# dotfiles and backups - CLEANUP TBD
#############################

echo
if gum confirm "Back up current ~/.config & ~/.bashrc and install wypr configs?"; then
      gum spin --title "Backing up and copying .config & .bashrc -> " -- sleep 1
      echo -e "${PINK}${BOLD}Backing up and copying .config & .bashrc -> ${RESET}"
      echo
else
      echo
      echo -e "${RED}${BOLD}Aborting -> ${RESET}"
      echo
      exit 1
fi

WYPR="$(pwd)"
DOTFILES_DIR="$WYPR/dotfiles"
CONFIG_DIR="$USER_HOME/.config"
BACKUP_DIR="$USER_HOME/wypr_backup_$(date +%Y%m%d_%H%M%S)"
BASHRC="$USER_HOME/.bashrc"
GSETTINGS="$USER_HOME/.local/share/nwg-look/"

mkdir -p "$BACKUP_DIR"

# backup existing .config, .bashrc, gsettings
if [ -d "$CONFIG_DIR" ]; then
      mkdir -p "$BACKUP_DIR/.config"
      rsync -av "$CONFIG_DIR/" "$BACKUP_DIR/.config/" >> "$LOG_FILE" 2>&1
      echo -e "${GREEN}Backup of ~/.config completed = $BACKUP_DIR/.config${RESET}"
else
      echo -e "${RED}No ~/.config directory found.${RESET}"
fi

if [ -f "$BASHRC" ]; then
      cp "$BASHRC" "$BACKUP_DIR/.bashrc" >> "$LOG_FILE" 2>&1
      echo -e "${GREEN}Backup of ~/.bashrc completed = $BACKUP_DIR/.bashrc${RESET}"
else
      echo -e "${RED}No ~/.bashrc file found.${RESET}"
fi

if [ -f "$GSETTINGS" ]; then
      cp "$GSETTINGS" "$USER_HOME/.local/share/nwg-look/" >> "$LOG_FILE" 2>&1
      echo -e "${GREEN}Backup of gsettings completed = $BACKUP_DIR/gsettings${RESET}"
else
      echo -e "${RED}No gsettings file found.${RESET}"
fi

# copy dotfiles .config, .bashrc, gsettings
if [ -d "$DOTFILES_DIR/.config" ]; then
      mkdir -p "$CONFIG_DIR"
      rsync -av "$DOTFILES_DIR/.config/" "$CONFIG_DIR/" >> "$LOG_FILE" 2>&1
      echo -e "${GREEN}Successfully copied .config directory.${RESET}"
else
      echo -e "${RED}Failed to copy .config directory.${RESET}"
fi

if [ -f "$DOTFILES_DIR/.bashrc" ]; then
      cp "$DOTFILES_DIR/.bashrc" "$BASHRC" >> "$LOG_FILE" 2>&1
      echo -e "${GREEN}Successfully copied .bashrc file.${RESET}"
else
      echo -e "${RED}Failed to copy .bashrc file.${RESET}"
fi

if [ -f "$DOTFILES_DIR/gsettings" ]; then
      mkdir "$USER_HOME/.local/share/nwg-look/" >> "$LOG_FILE" 2>&1
      cp "$DOTFILES_DIR/gsettings" "$GSETTINGS" >> "$LOG_FILE" 2>&1
      echo -e "${GREEN}Successfully copied gsettings file.${RESET}"
else
      echo -e "${RED}Failed to copy gsettings file.${RESET}"
fi
chown -R "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.config" "$USER_HOME/.bashrc" "$BACKUP_DIR" >> "$LOG_FILE" 2>&1





#############################
# GTK theme install (Dracula)
#############################

URL="https://github.com/dracula/gtk/archive/master.zip"
ZIP_FILE="gtk-master.zip"
EXTRACTED_DIR="gtk-master"
DEST_DIR="/usr/share/themes"

wget -O "$ZIP_FILE" "$URL" >> "$LOG_FILE" 2>&1 || curl -L -o "$ZIP_FILE" "$URL"

if [[ ! -f "$ZIP_FILE" ]]; then
      echo "Dracula GTK download failed -> "
fi
unzip -o "$ZIP_FILE" >> "$LOG_FILE" 2>&1
mv "$EXTRACTED_DIR" "$DEST_DIR" >> "$LOG_FILE" 2>&1
rm -f "$ZIP_FILE" >> "$LOG_FILE" 2>&1




#############################
# finish
#############################
echo
echo
echo -e "${PINK}${BOLD}Installation logs ->${RESET}"
echo
echo -e "${GREEN}${BOLD}$WYPR/$LOG_FILE ${RESET}"
echo



echo
echo -e "${PINK}${BOLD}Post install -> ${RESET}"
echo
echo -e "${GREEN}${BOLD}After logging in with hyprland, run \`hyprctl monitors\` and note your display's name and amend in "~/.config/hypr/hyprland.conf" under "monitor.conf", e.g "monitor=DP-1" - setting resolution, refresh rate and scale accordingly. Also, changing under "workspace.conf" to the same value.\n
You can use \`sed\` to automate, for example if \`hyprctl monitors\` returns "Virtual-1", you can replace default "DP-1" by running the below:${RESET}\n
${BLUE}${BOLD}sed -i 's/DP-1/Virtual-1/g' ~/.config/hypr/*\n${RESET}"

gum spin --spinner dot --title "You can now logout and select 'hyprland' on login ->  " -- sleep 15