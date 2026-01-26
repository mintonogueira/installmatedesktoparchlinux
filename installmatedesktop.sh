#!/bin/sh

# Ativa o modo verbose no shell para rastreamento detalhado de cada etapa
# -v: imprime as linhas do script conforme são lidas
# -x: imprime os comandos e seus argumentos conforme são executados
set -v
set -x

echo "INICIANDO PROCESSO DE INSTALAÇÃO EM MODO VERBOSE..."

# --- ETAPA 1: Repositórios Oficiais (MATE, Utilitários e Network Manager) ---
# O comando "sudo pacman -Syyu --needed --noconfirm" é mantido e respeitado.
# Foram incluídos individualmente os pacotes do mate-desktop, mate-extra e o network-manager-applet.

echo "Executando Etapa 1: Instalação via pacman..."

sudo pacman -Syyu --needed --noconfirm \
    xorg xorg-server \
    lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings \
    network-manager-applet \
    flatpak gufw gparted file-roller xarchiver engrampa \
    git go rust timeshift \
    mate-desktop \
    atril caja-image-converter caja-open-terminal caja-sendto \
    eom mate-applets mate-backgrounds mate-calc mate-control-center \
    mate-icon-theme mate-media mate-menus mate-notification-daemon \
    mate-panel mate-polkit mate-power-manager mate-screensaver \
    mate-session-manager mate-settings-daemon mate-system-monitor \
    mate-terminal mate-user-guide mate-utils pluma

# --- ETAPA 2: Compilação do Paru (AUR Helper) ---
echo "Executando Etapa 2: Clonagem e compilação do Paru..."
if [ -d "paru" ]; then 
    echo "Removendo diretório paru existente para nova clonagem..."
    rm -rf paru
fi

git clone https://aur.archlinux.org/paru.git
cd paru
# O makepkg exibirá todo o processo de build detalhadamente
makepkg -si --noconfirm
cd ..

# --- ETAPA 3: Instalação AUR com Questionamento de Veracidade ---
echo "----------------------------------------------------------------"
echo "SOLICITAÇÃO DE VERIFICAÇÃO HUMANA - PACOTES AUR"
echo "Os seguintes pacotes foram localizados via PARU:"
echo "webcamoid, brave-bin, simplescreenrecorder, google-chrome,"
echo "octopi, ocs-url, archlinux-tweak-tool"
echo "----------------------------------------------------------------"

# Desativa verbose temporariamente para que a pergunta ao usuário seja legível
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
        octopi ocs-url archlinux-tweak-tool
else
    echo "Etapa 3 abortada pelo usuário. Os pacotes AUR não foram instalados."
fi

# --- ETAPA 4: Habilitação de Serviços e Reinicialização ---
echo "Executando Etapa 4: Habilitação de serviços e reboot..."

# Habilita o firewall, o gerenciador de login e o NetworkManager (necessário para o applet)
sudo systemctl enable ufw
sudo systemctl enable lightdm
sudo systemctl enable NetworkManager

echo "PROCESSO CONCLUÍDO. O SISTEMA REINICIARÁ EM 5 SEGUNDOS..."
sleep 5
sudo reboot
