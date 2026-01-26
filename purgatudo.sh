#!/bin/sh

# Ativa o modo verbose total para rastreamento detalhado
set -v
set -x

echo "⚠️⚠️ INICIANDO PURGA TOTAL E VALIDAÇÃO DE LIMPEZA ⚠️⚠️"

# Listas de pacotes para purga e checagem
PACOTES_AUR="webcamoid brave-bin simplescreenrecorder google-chrome octopi ocs-url archlinux-tweak-tool-git rclone-browser"
PACOTES_PACMAN="mate-desktop atril caja-image-converter caja-open-terminal caja-sendto eom mate-applets mate-backgrounds mate-calc mate-control-center mate-icon-theme mate-media mate-menus mate-notification-daemon mate-panel mate-polkit mate-power-manager mate-screensaver mate-session-manager mate-settings-daemon mate-system-monitor mate-terminal mate-user-guide mate-utils pluma xorg xorg-server lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings network-manager-applet bluez bluez-utils blueman xdg-user-dirs rclone flatpak gufw gparted file-roller xarchiver engrampa timeshift terminator flameshot curl wget transmission-gtk"

# --- ETAPA 1: Desabilitar Serviços ---
sudo systemctl disable --now ufw lightdm NetworkManager bluetooth 2>/dev/null

# --- ETAPA 2: Purga AUR (Paru) ---
if command -v paru >/dev/null 2>&1; then
    for pkg in $PACOTES_AUR; do
        paru -Rns --noconfirm "$pkg" 2>/dev/null
    done
    paru -Scc --noconfirm
    rm -rf "$HOME/.cache/paru"
fi

# --- ETAPA 3: Purga Oficial (Pacman) ---
# O comando ignora pacotes já removidos para evitar erros em múltiplas execuções
sudo pacman -Rns --noconfirm $PACOTES_PACMAN 2>/dev/null

# --- ETAPA 4: Limpeza de Órfãos e Cache ---
while [ -n "$(pacman -Qdtq)" ]; do
    sudo pacman -Rns $(pacman -Qdtq) --noconfirm 2>/dev/null
done
sudo pacman -Scc --noconfirm

# --- ETAPA 5: Limpeza de Arquivos de Configuração ---
rm -f fixrclone-browser.sh
rm -rf "$HOME/paru" "$HOME/.config/mate" "$HOME/.config/terminator"
CONFIG_FILES="$HOME/.bashrc $HOME/.zshrc $HOME/.profile $HOME/.xprofile $HOME/.bash_profile"
for file in $CONFIG_FILES; do
    if [ -f "$file" ]; then
        sed -i '/# Auto-config: Define terminal padrão (Rclone fix)/d' "$file"
        sed -i '/export TERMINAL=terminator/d' "$file"
        sed -i '/# Auto-config: Rclone fix/d' "$file"
    fi
done

# --- ETAPA 6: CHECAGEM DE INTEGRIDADE DA REMOÇÃO ---
set +v
set +x
echo "----------------------------------------------------------------"
echo "🔍 Verificando se restou algum componente no sistema..."

RESTOU_ALGO=0
for pkg in $PACOTES_AUR $PACOTES_PACMAN; do
    if pacman -Qi "$pkg" >/dev/null 2>&1; then
        echo "⚠️  AVISO: O pacote $pkg ainda consta como instalado."
        RESTOU_ALGO=1
    fi
done

if [ $RESTOU_ALGO -eq 0 ]; then
    echo ""
    echo "################################################################"
    echo "          REMOÇÃO FEITA COM SUCESSO"
    echo "################################################################"
    echo "Nenhum pacote residual foi encontrado na base de dados."
else
    echo "❌ A purga foi parcial. Alguns pacotes ainda estão presentes."
fi

echo ""
printf "Pressione [ENTER] para REINICIAR ou [Ctrl+C] para cancelar: "
read -r null_var

sudo reboot
