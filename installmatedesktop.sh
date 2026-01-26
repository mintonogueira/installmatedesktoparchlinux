#!/bin/sh

# Ativa o modo verbose no shell para rastreamento total
set -v
set -x

echo "INICIANDO PROCESSO DE INSTALAÇÃO - MATE DESKTOP & AUR"

# --- ETAPA 1: Repositórios Oficiais ---
# O COMANDO: "sudo pacman -Syyu --needed --noconfirm" é respeitado e MANTIDO.
sudo pacman -Syyu --needed --noconfirm \
    xorg xorg-server \
    lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings \
    network-manager-applet \
    bluez bluez-utils blueman \
    xdg-user-dirs rclone \
    flatpak gufw gparted file-roller xarchiver engrampa \
    git go rust timeshift \
    mate-desktop \
    atril caja-image-converter caja-open-terminal caja-sendto \
    eom mate-applets mate-backgrounds mate-calc mate-control-center \
    mate-icon-theme mate-media mate-menus mate-notification-daemon \
    mate-panel mate-polkit mate-power-manager mate-screensaver \
    mate-session-manager mate-settings-daemon mate-system-monitor \
    mate-terminal mate-user-guide mate-utils pluma

# --- ETAPA 1.2: Configuração de Diretórios de Usuário ---
xdg-user-dirs-update

# --- ETAPA 2: Verificação e Instalação do Paru (AUR Helper) ---
echo "Verificando se o Paru já está instalado..."
if command -v paru >/dev/null 2>&1; then
    echo "Paru detectado. Pulando a compilação..."
else
    echo "Paru não encontrado. Iniciando instalação..."
    if [ -d "paru" ]; then rm -rf paru; fi
    git clone https://aur.archlinux.org/paru.git
    cd paru || exit
    makepkg -si --noconfirm
    cd ..
fi

# --- ETAPA 3: Instalação AUR PACOTE POR PACOTE (100% Interativa) ---
echo "----------------------------------------------------------------"
echo "INICIANDO INSTALAÇÃO INTERATIVA VIA PARU"
echo "----------------------------------------------------------------"

PACOTES_AUR="webcamoid brave-bin simplescreenrecorder google-chrome octopi ocs-url archlinux-tweak-tool rclone-browser"

for pkg in $PACOTES_AUR; do
    # Desativa verbose momentaneamente para a pergunta ficar limpa
    set +v
    set +x
    echo ""
    printf "Deseja instalar o pacote [%s]? (s/n): " "$pkg"
    read -r resposta
    # Reativa o verbose
    set -v
    set -x

    if [ "$resposta" = "s" ] || [ "$resposta" = "S" ]; then
        echo "Instalando $pkg..."
        paru -S --needed --noconfirm "$pkg"
    else
        echo "Pulando o pacote $pkg..."
    fi
done

# --- ETAPA 4: Habilitação de Serviços e Reboot ---
echo "Habilitando serviços de sistema..."
sudo systemctl enable ufw
sudo systemctl enable lightdm
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth

echo "PROCESSO CONCLUÍDO. O SISTEMA REINICIARÁ EM 5 SEGUNDOS..."
sleep 5
sudo reboot
