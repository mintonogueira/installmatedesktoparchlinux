#!/bin/sh

# Ativa o modo verbose no shell para rastreamento total
# -v: imprime as linhas do script conforme lidas
# -x: imprime os comandos expandidos antes da execução
set -v
set -x

echo "INICIANDO PROCESSO DE INSTALAÇÃO - AMBIENTE MATE COMPLETO"

# --- ETAPA 1: Repositórios Oficiais ---
# O COMANDO: "sudo pacman -Syyu --needed --noconfirm" é respeitado e MANTIDO.
# Incluído o pacote: terminator
sudo pacman -Syyu --needed --noconfirm \
    xorg xorg-server \
    lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings \
    network-manager-applet \
    bluez bluez-utils blueman \
    xdg-user-dirs rclone \
    flatpak gufw gparted file-roller xarchiver engrampa \
    git go rust timeshift terminator \
    mate-desktop \
    atril caja-image-converter caja-open-terminal caja-sendto \
    eom mate-applets mate-backgrounds mate-calc mate-control-center \
    mate-icon-theme mate-media mate-menus mate-notification-daemon \
    mate-panel mate-polkit mate-power-manager mate-screensaver \
    mate-session-manager mate-settings-daemon mate-system-monitor \
    mate-terminal mate-user-guide mate-utils pluma

# --- ETAPA 1.2: Configuração de Diretórios de Usuário ---
echo "Executando Etapa 1.2: xdg-user-dirs-update"
xdg-user-dirs-update

# --- ETAPA 2: Verificação e Instalação do Paru (Interativo se já existir) ---
instalar_paru() {
    echo "Iniciando compilação do Paru..."
    if [ -d "paru" ]; then rm -rf paru; fi
    git clone https://aur.archlinux.org/paru.git
    cd paru || exit
    makepkg -si --noconfirm
    cd ..
}

if command -v paru >/dev/null 2>&1; then
    set +v
    set +x
    echo "----------------------------------------------------------------"
    echo "O Paru já está instalado."
    printf "Deseja REINSTALAR o Paru agora? (s/n): "
    read -r resp_paru
    set -v
    set -x

    if [ "$resp_paru" = "s" ] || [ "$resp_paru" = "S" ]; then
        instalar_paru
    fi
else
    instalar_paru
fi

# --- ETAPA 3: Instalação AUR PACOTE POR PACOTE (100% Interativa) ---
echo "----------------------------------------------------------------"
echo "INSTALAÇÃO INTERATIVA VIA PARU"
echo "----------------------------------------------------------------"

PACOTES_AUR="webcamoid brave-bin simplescreenrecorder google-chrome octopi ocs-url archlinux-tweak-tool rclone-browser"

for pkg in $PACOTES_AUR; do
    set +v
    set +x
    printf "Deseja instalar o pacote AUR [%s]? (s/n): " "$pkg"
    read -r resposta
    set -v
    set -x

    if [ "$resposta" = "s" ] || [ "$resposta" = "S" ]; then
        paru -S --needed --noconfirm "$pkg"
    fi
done

# --- ETAPA 4: Habilitação de Serviços e Reboot ---
sudo systemctl enable ufw
sudo systemctl enable lightdm
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth

echo "PROCESSO FINALIZADO. REINICIANDO EM 5 SEGUNDOS..."
sleep 5
sudo reboot
