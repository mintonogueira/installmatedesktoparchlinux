#!/bin/sh

# Ativa o modo verbose no shell para rastreamento total
set -v
set -x

echo "INICIANDO INSTALAÇÃO - VERSÃO SEM ATALHOS CUSTOMIZADOS"

# --- ETAPA 1: Repositórios Oficiais ---
sudo pacman -Syyu --needed --noconfirm \
    xorg xorg-server \
    lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings \
    network-manager-applet bluez bluez-utils blueman xdg-user-dirs rclone \
    flatpak gufw gparted file-roller xarchiver engrampa \
    git go rust timeshift terminator flameshot \
    mate-desktop atril caja-image-converter caja-open-terminal caja-sendto \
    eom mate-applets mate-backgrounds mate-calc mate-control-center \
    mate-icon-theme mate-media mate-menus mate-notification-daemon \
    mate-panel mate-polkit mate-power-manager mate-screensaver \
    mate-session-manager mate-settings-daemon mate-system-monitor \
    mate-terminal mate-user-guide mate-utils pluma

# --- ETAPA 1.2: Configuração de Diretórios de Usuário ---
xdg-user-dirs-update

# --- ETAPA 2: Verificação do Paru ---
instalar_paru() {
    if [ -d "paru" ]; then rm -rf paru; fi
    git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si --noconfirm && cd ..
}
if command -v paru >/dev/null 2>&1; then
    set +v +x
    printf "Paru detectado. Deseja REINSTALAR? (s/n): "
    read -r resp_paru
    set -v -x
    if [ "$resp_paru" = "s" ] || [ "$resp_paru" = "S" ]; then instalar_paru; fi
else
    instalar_paru
fi

# --- ETAPA 3: Instalação AUR PACOTE POR PACOTE ---
PACOTES_AUR="webcamoid brave-bin simplescreenrecorder google-chrome octopi ocs-url archlinux-tweak-tool-git rclone-browser"
for pkg in $PACOTES_AUR; do
    set +v +x
    printf "Deseja instalar o pacote AUR [%s]? (s/n): " "$pkg"
    read -r resposta
    set -v -x
    if [ "$resposta" = "s" ] || [ "$resposta" = "S" ]; then paru -S --needed --noconfirm "$pkg"; fi
done

# --- ETAPA 4.2: Configuração de Aplicação Padrão ---
echo "Configurando Terminator como terminal preferencial..."
if command -v terminator >/dev/null 2>&1; then
    gsettings set org.mate.applications-terminal exec 'terminator'
    gsettings set org.mate.applications-terminal exec-arg "-x"
fi

# --- ETAPA 4.3: Fix Rclone-Browser ---
cat << 'EOF' > fixrclone-browser.sh
#!/bin/sh
CMD_LINE="export TERMINAL=terminator"
for file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile" "$HOME/.xprofile"; do
    [ -f "$file" ] && ! grep -q "export TERMINAL=" "$file" && echo "$CMD_LINE" >> "$file"
done
EOF
chmod +x fixrclone-browser.sh
./fixrclone-browser.sh

# --- ETAPA 4: Habilitação de Serviços ---
sudo systemctl enable ufw lightdm NetworkManager bluetooth

# --- FINALIZAÇÃO COM PAUSA ---
set +v
set +x
echo ""
echo "################################################################"
echo "PROCESSO CONCLUÍDO!"
echo "O sistema está pronto. Os atalhos de teclado devem ser"
echo "configurados manualmente em: Centro de Controle > Atalhos."
echo "################################################################"
printf "Pressione [ENTER] para reiniciar o sistema ou [Ctrl+C] para sair: "
read -r null_var

sudo reboot
