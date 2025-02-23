#!/bin/bash

TIME_VAR=$(date +"%d.%m.%Y_%H-%M-%S")

# selected .config backup
mv ./dotfiles/.config ./dotfiles/.config[$TIME_VAR].bak
mkdir ./dotfiles/.config
backup_dirs=(
      "hypr"
      "wypr" 
      "waybar"
      "wlogout"
      "warp-terminal"
      "starship.toml"
      "rofi"
      "nautilus"
      "fastfetch"
      "kitty"
      "alacritty"
      "nvim"
      "nwg-look"
      "gtk-4.0"
      "gtk-3.0"
      "waypaper"
      )
for dir in "${backup_dirs[@]}"; do
      rsync -av --exclude 'gtk-3.0/bookmarks' ~/.config/"$dir" ./dotfiles/.config
done


# full .config backup
mv ./dotfiles/.config-full ./dotfiles/.config[$TIME_VAR]-full.bak
mkdir ./dotfiles/.config-full
rsync -av --exclude 'Code' --exclude 'microsoft-edge' --exclude 'google-chrome' --exclude 'discord' ~/.config/ ./dotfiles/.config-full
