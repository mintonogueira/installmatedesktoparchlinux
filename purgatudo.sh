#!/bin/sh

# Ativa o modo verbose total para rastreamento de cada remoção forçada
set -v
set -x

echo "⚠️⚠️ OPERAÇÃO DE EXTERMÍNIO TOTAL (FORÇA BRUTA) - EXCETO NETWORK-MANAGER ⚠️⚠️"

# --- ETAPA 0: Destravar e Sincronizar ---
sudo rm -f /var/lib/pacman/db.lck
sudo pacman -Sy

# --- ETAPA 1: Parar Serviços (EXCETO NetworkManager) ---
sudo systemctl disable --now ufw lightdm bluetooth 2>/dev/null

# Listas de pacotes para extermínio
PACOTES_AUR="webcamoid brave-bin simplescreenrecorder google-chrome octopi ocs-url archlinux-tweak-tool-git rclone-browser"

# Nota: network-manager-applet e NetworkManager REMOVIDOS da lista de purga
PACOTES_PACMAN="mate-desktop atril caja-image-converter caja-open-terminal caja-sendto eom mate-applets mate-backgrounds mate-calc mate-control-center mate-icon-theme mate-media mate-menus mate-notification-daemon mate-panel mate-polkit mate-power-manager mate-screensaver mate-session-manager mate-settings-daemon mate-system-monitor mate-terminal mate-user-guide mate-utils pluma xorg xorg-server lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings bluez bluez-utils blueman xdg-user-dirs rclone flatpak gufw gparted file-roller xarchiver engrampa timeshift terminator flameshot curl wget transmission-gtk"

# --- ETAPA 2: Força Bruta AUR ---
if command -v paru >/dev/null 2>&1; then
    for pkg in $PACOTES_AUR; do
        echo "Exterminando pacote AUR: $pkg"
        sudo paru -Rdd --noconfirm "$pkg" 2>/dev/null
    done
fi

# --- ETAPA 3: Força Bruta Pacman (Remoção sem volta) ---
for pkg in $PACOTES_PACMAN; do
    echo "Exterminando pacote oficial: $pkg"
    # -Rdd: Remove o pacote e ignora se o sistema vai quebrar ou se há dependências
    sudo pacman -Rdd --noconfirm "$pkg" 2>/dev/null
done

# --- ETAPA 4: Purga de Dependências Órfãs Residuais ---
echo "Limpando resíduos de dependências que ficaram para trás..."
# Este comando remove tudo o que não é explicitamente exigido pelo sistema base
while [ -n "$(pacman -Qdtq)" ]; do
    sudo pacman -Rns $(pacman -Qdtq) --noconfirm 2>/dev/null
done

# --- ETAPA 5: Destruição Física de Diretórios e Configurações ---
echo "Deletando pastas de configuração e caches..."
sudo rm -rf /etc/lightdm
sudo rm -rf /etc/X11/xorg.conf.d/
rm -rf "$HOME/.cache/paru"
rm -rf "$HOME/.config/mate"
rm -rf "$HOME/.config/terminator"
rm -rf "$HOME/.local/share/mate"
rm -rf "$HOME/.config/transmission"
rm -f fixrclone-browser.sh

# Limpeza dos arquivos de inicialização do Shell
for file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile" "$HOME/.xprofile" "$HOME/.bash_profile"; do
    if [ -f "$file" ]; then
        sed -i '/Rclone fix/d' "$file"
        sed -i '/export TERMINAL=/d' "$file"
        sed -i '/Auto-config/d' "$file"
    fi
done

# --- ETAPA 6: VALIDAÇÃO E MENSAGEM DE SUCESSO ---
set +v
set +x
echo "----------------------------------------------------------------"
echo "🔍 VERIFICAÇÃO DE RESQUÍCIOS..."

RESIDUOS=0
for pkg in $PACOTES_AUR $PACOTES_PACMAN; do
    if pacman -Qi "$pkg" >/dev/null 2>&1; then
        echo "❌ FALHA: $pkg ainda detectado."
        RESIDUOS=1
    fi
done

if [ $RESIDUOS -eq 0 ]; then
    echo ""
    echo "################################################################"
    echo "          REMOÇÃO FEITA COM SUCESSO"
    echo "################################################################"
    echo "O sistema foi limpo. NetworkManager preservado e ativo."
else
    echo "⚠️  Alguns pacotes resistiram à força bruta inicial."
fi

echo ""
printf "Pressione [ENTER] para REINICIAR o sistema: "
read -r null_var

sudo reboot
