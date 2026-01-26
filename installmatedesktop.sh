#!/bin/sh

# Ativa o modo verbose no shell para rastreamento total
set -v
set -x

echo "INICIANDO INSTALAÇÃO - AMBIENTE MATE, FERRAMENTAS WEB E FIX RCLONE"

# --- ETAPA 1: Repositórios Oficiais ---
# O COMANDO: "sudo pacman -Syyu --needed --noconfirm" é respeitado e MANTIDO.
# Incluídos: curl, wget, transmission-gtk, terminator e flameshot.
sudo pacman -Syyu --needed --noconfirm \
    xorg xorg-server \
    lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings \
    network-manager-applet bluez bluez-utils blueman xdg-user-dirs rclone \
    flatpak gufw gparted file-roller xarchiver engrampa \
    git go rust timeshift terminator flameshot \
    curl wget transmission-gtk \
    mate-desktop atril caja-image-converter caja-open-terminal caja-sendto \
    eom mate-applets mate-backgrounds mate-calc mate-control-center \
    mate-icon-theme mate-media mate-menus mate-notification-daemon \
    mate-panel mate-polkit mate-power-manager mate-screensaver \
    mate-session-manager mate-settings-daemon mate-system-monitor \
    mate-terminal mate-user-guide mate-utils pluma

# --- ETAPA 1.2: Configuração de Diretórios de Usuário ---
xdg-user-dirs-update

# --- ETAPA 2: Verificação e Instalação do Paru (Interativo se já existir) ---
instalar_paru() {
    echo "Iniciando compilação do Paru..."
    if [ -d "paru" ]; then rm -rf paru; fi
    git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si --noconfirm && cd ..
}

if command -v paru >/dev/null 2>&1; then
    set +v +x
    echo "----------------------------------------------------------------"
    echo "O Paru já está instalado."
    printf "Deseja REINSTALAR o Paru agora? (s/n): "
    read -r resp_paru
    set -v -x
    if [ "$resp_paru" = "s" ] || [ "$resp_paru" = "S" ]; then
        instalar_paru
    fi
else
    instalar_paru
fi

# --- ETAPA 3: Instalação AUR PACOTE POR PACOTE (100% Interativa) ---
PACOTES_AUR="webcamoid brave-bin simplescreenrecorder google-chrome octopi ocs-url archlinux-tweak-tool-git rclone-browser"

for pkg in $PACOTES_AUR; do
    set +v +x
    printf "Deseja instalar o pacote AUR [%s]? (s/n): " "$pkg"
    read -r resposta
    set -v -x

    if [ "$resposta" = "s" ] || [ "$resposta" = "S" ]; then
        paru -S --needed --noconfirm "$pkg"
    fi
done

# --- ETAPA 4.2: Configuração de Aplicação Padrão ---
echo "Configurando Terminator como terminal preferencial..."
if command -v terminator >/dev/null 2>&1; then
    gsettings set org.mate.applications-terminal exec 'terminator'
    gsettings set org.mate.applications-terminal exec-arg "-x"
fi

# --- ETAPA 4.3: Criação e Execução do Fix Rclone-Browser ---
echo "Criando e executando fixrclone-browser.sh..."

cat << 'EOF' > fixrclone-browser.sh
#!/bin/sh
CMD_LINE="export TERMINAL=terminator"
for file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile" "$HOME/.xprofile" "$HOME/.bash_profile"; do
    if [ -f "$file" ]; then
        if ! grep -q "export TERMINAL=" "$file"; then
            echo "" >> "$file"
            echo "# Auto-config: Define terminal padrão (Rclone fix)" >> "$file"
            echo "$CMD_LINE" >> "$file"
        fi
    fi
done
EOF

chmod +x fixrclone-browser.sh
./fixrclone-browser.sh

# --- ETAPA 4: Habilitação de Serviços ---
sudo systemctl enable ufw lightdm NetworkManager bluetooth

# --- FINALIZAÇÃO COM PAUSA PARA LEITURA ---
set +v
set +x
echo ""
echo "################################################################"
echo "PROCESSO CONCLUÍDO COM SUCESSO!"
echo "Verifique os logs acima antes de reiniciar."
echo "################################################################"
printf "Pressione [ENTER] para REINICIAR o equipamento ou [Ctrl+C] para cancelar: "
read -r null_var

sudo reboot
