#!/bin/sh

# Ativa o modo verbose no shell para rastreamento total de cada linha e comando
set -v
set -x

echo "INICIANDO PROCESSO DE INSTALAÇÃO INTEGRAL - MODO VERBOSE"

# --- ETAPA 1: Repositórios Oficiais (MATE, Rede, Bluetooth e XDG) ---
# O COMANDO: "sudo pacman -Syyu --needed --noconfirm" é respeitado e MANTIDO.
echo "Executando Etapa 1: Instalação via pacman..."

sudo pacman -Syyu --needed --noconfirm \
    xorg xorg-server \
    lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings \
    network-manager-applet \
    bluez bluez-utils blueman \
    xdg-user-dirs \
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
echo "Executando Etapa 1.2: Atualização dos diretórios XDG..."
xdg-user-dirs-update

# --- ETAPA 2: Instalação do Paru (AUR Helper) ---
echo "Executando Etapa 2: Clonagem e compilação do Paru..."
if [ -d "paru" ]; then 
    rm -rf paru
fi

git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si --noconfirm
cd ..

# --- ETAPA 3: Instalação AUR com Questionamento de Veracidade ---
# Incluído o pacote rclone-browser conforme solicitado.
echo "----------------------------------------------------------------"
echo "SOLICITAÇÃO DE VERIFICAÇÃO HUMANA - PACOTES AUR (PARU)"
echo "Pacotes: webcamoid, brave-bin, simplescreenrecorder, google-chrome,"
echo "octopi, ocs-url, archlinux-tweak-tool, rclone-browser"
echo "----------------------------------------------------------------"

# Pausa momentânea do verbose para garantir a leitura do prompt pelo utilizador
set +v
set +x
printf "Você confirma a veracidade e deseja proceder com a instalação via PARU? (s/n): "
read -r resposta
set -v
set -x

if [ "$resposta" = "s" ] || [ "$resposta" = "S" ]; then
    echo "Procedendo com a instalação via Paru..."
    paru -Syyu --needed --noconfirm \
        webcamoid brave-bin simplescreenrecorder google-chrome \
        octopi ocs-url archlinux-tweak-tool rclone-browser
else
    echo "Etapa 3 ignorada pelo utilizador."
fi

# --- ETAPA 4: Habilitação de Serviços e Reinicialização ---
echo "Executando Etapa 4: Habilitação de serviços e reboot automatizado..."

sudo systemctl enable ufw
sudo systemctl enable lightdm
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth

echo "PROCESSO CONCLUÍDO. REINICIANDO EM 5 SEGUNDOS..."
sleep 5
sudo reboot
