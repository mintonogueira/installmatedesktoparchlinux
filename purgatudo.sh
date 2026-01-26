#!/bin/sh

# Ativa o modo verbose total para rastreamento de cada ação
set -v
set -x

echo "⚠️⚠️ EXTERMÍNIO TOTAL E LIMPEZA DE CONFIGURAÇÕES ⚠️⚠️"

# Listas de alvos para remoção
PACOTES_AUR="webcamoid brave-bin simplescreenrecorder google-chrome octopi ocs-url archlinux-tweak-tool-git rclone-browser"
PACOTES_PACMAN="mate-desktop atril caja-image-converter caja-open-terminal caja-sendto eom mate-applets mate-backgrounds mate-calc mate-control-center mate-icon-theme mate-media mate-menus mate-notification-daemon mate-panel mate-polkit mate-power-manager mate-screensaver mate-session-manager mate-settings-daemon mate-system-monitor mate-terminal mate-user-guide mate-utils pluma xorg xorg-server lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings bluez bluez-utils blueman xdg-user-dirs rclone flatpak gufw gparted file-roller xarchiver engrampa timeshift terminator flameshot curl wget transmission-gtk"

# --- ETAPA 1: Verificação de Execução Prévia ---
set +v +x
ALGO_INSTALADO=0
for pkg in $PACOTES_AUR $PACOTES_PACMAN; do
    if pacman -Qi "$pkg" >/dev/null 2>&1; then
        ALGO_INSTALADO=1
        break
    fi
done

if [ $ALGO_INSTALADO -eq 0 ]; then
    echo "################################################################"
    echo "          REMOÇÃO JÁ FOI FEITA COM SUCESSO"
    echo "################################################################"
    exit 0
fi
set -v -x

# --- ETAPA 2: Força Bruta de Remoção (Ignorando Dependências) ---
sudo rm -f /var/lib/pacman/db.lck
sudo systemctl disable --now ufw lightdm bluetooth 2>/dev/null

# Remove pacotes AUR
for pkg in $PACOTES_AUR; do
    sudo paru -Rdd --noconfirm "$pkg" 2>/dev/null
done

# Remove pacotes oficiais um por um (Força Bruta)
for pkg in $PACOTES_PACMAN; do
    sudo pacman -Rdd --noconfirm "$pkg" 2>/dev/null
done

# --- ETAPA 3: Purga de Órfãos e Resíduos de Dependências ---
while [ -n "$(pacman -Qdtq)" ]; do
    sudo pacman -Rns $(pacman -Qdtq) --noconfirm 2>/dev/null
done
sudo pacman -Scc --noconfirm

# --- ETAPA 4: Limpeza Profunda de Configurações e Arquivos de Usuário ---
echo "Removendo arquivos de configuração e vestígios do script..."

# Remove diretórios de configuração do sistema e do usuário
sudo rm -rf /etc/lightdm /etc/X11/xorg.conf.d/
rm -rf "$HOME/.cache/paru" "$HOME/.config/mate" "$HOME/.config/terminator"
rm -rf "$HOME/.local/share/mate" "$HOME/.config/transmission" "$HOME/.config/flameshot"
rm -rf "$HOME/.config/rclone" "$HOME/.config/octopi"
rm -f fixrclone-browser.sh

# Limpa rigorosamente os arquivos de perfil do Shell
for file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile" "$HOME/.xprofile" "$HOME/.bash_profile"; do
    if [ -f "$file" ]; then
        # Remove todas as linhas que contenham as marcas do nosso script
        sed -i '/Rclone fix/d' "$file"
        sed -i '/export TERMINAL=/d' "$file"
        sed -i '/Auto-config/d' "$file"
        sed -i '/terminator/d' "$file"
    fi
done

# --- ETAPA 5: Validação Final ---
set +v +x
RESIDUOS=0
for pkg in $PACOTES_AUR $PACOTES_PACMAN; do
    if pacman -Qi "$pkg" >/dev/null 2>&1; then
        RESIDUOS=1
    fi
done

if [ $RESIDUOS -eq 0 ]; then
    echo ""
    echo "################################################################"
    echo "          REMOÇÃO FEITA COM SUCESSO"
    echo "################################################################"
else
    echo "⚠️  Alguns elementos resistiram. Recomenda-se executar novamente."
fi

printf "Pressione [ENTER] para REINICIAR o sistema: "
read -r null_var
sudo reboot
