#!/bin/sh

# Ativa o modo verbose no shell para rastreamento total
set -v
set -x

echo "INICIANDO INSTALAÇÃO COMPLETA - MATE DESKTOP & FIX RCLONE"

# --- ETAPA 1: Repositórios Oficiais ---
sudo pacman -Syyu --needed --noconfirm \
    xorg xorg-server \
    lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings \
    network-manager-applet \
    bluez bluez-utils blueman \
    xdg-user-dirs rclone \
    flatpak gufw gparted file-roller xarchiver engrampa \
    git go rust timeshift terminator flameshot \
    mate-desktop \
    atril caja-image-converter caja-open-terminal caja-sendto \
    eom mate-applets mate-backgrounds mate-calc mate-control-center \
    mate-icon-theme mate-media mate-menus mate-notification-daemon \
    mate-panel mate-polkit mate-power-manager mate-screensaver \
    mate-session-manager mate-settings-daemon mate-system-monitor \
    mate-terminal mate-user-guide mate-utils pluma

# --- ETAPA 1.2: Configuração de Diretórios de Usuário ---
xdg-user-dirs-update

# --- ETAPA 2: Verificação e Instalação do Paru ---
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

# --- ETAPA 3: Instalação AUR PACOTE POR PACOTE (Interativa) ---
PACOTES_AUR="webcamoid brave-bin simplescreenrecorder google-chrome octopi ocs-url archlinux-tweak-tool rclone-browser"
for pkg in $PACOTES_AUR; do
    set +v +x
    printf "Deseja instalar o pacote AUR [%s]? (s/n): " "$pkg"
    read -r resposta
    set -v -x
    if [ "$resposta" = "s" ] || [ "$resposta" = "S" ]; then paru -S --needed --noconfirm "$pkg"; fi
done

# --- ETAPA 4.2: Configurações de Interface e Atalhos (MATE) ---
echo "Configurando atalhos e Terminal padrão no MATE..."
gsettings set org.mate.applications-terminal exec 'terminator'
gsettings set org.mate.SettingsDaemon.plugins.media-keys screenshot ''
BASE_KEY="org.mate.SettingsDaemon.plugins.external-keybindings"

# Atalhos personalizados
gsettings set $BASE_KEY.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom0/ name 'flameshot'
gsettings set $BASE_KEY.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom0/ command '/usr/bin/flameshot gui'
gsettings set $BASE_KEY.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom0/ binding 'Print'

gsettings set $BASE_KEY.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom1/ name 'mate-system-monitor1'
gsettings set $BASE_KEY.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom1/ command '/usr/bin/mate-system-monitor'
gsettings set $BASE_KEY.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom1/ binding '<Control><Alt>Delete'

gsettings set $BASE_KEY.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom2/ name 'mate-system-monitor2'
gsettings set $BASE_KEY.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom2/ command '/usr/bin/mate-system-monitor'
gsettings set $BASE_KEY.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom2/ binding '<Control><Shift>Escape'

gsettings set $BASE_KEY.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom3/ name 'terminator'
gsettings set $BASE_KEY.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom3/ command '/usr/bin/terminator'
gsettings set $BASE_KEY.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom3/ binding '<Control><Alt>t'

gsettings set $BASE_KEY.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom4/ name 'caja'
gsettings set $BASE_KEY.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom4/ command '/usr/bin/caja'
gsettings set $BASE_KEY.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom4/ binding '<Mod4>e'

gsettings set org.mate.SettingsDaemon.plugins.keybinding custom-list "['custom0', 'custom1', 'custom2', 'custom3', 'custom4']"

# --- ETAPA 4.3: Criação e Execução do Fix Rclone-Browser ---
echo "Iniciando Etapa 4.3: Criando fixrclone-browser.sh..."

cat << 'EOF' > fixrclone-browser.sh
#!/bin/sh
echo "🔍 Iniciando detecção do terminal padrão do MATE..."
TARGET_TERM=""
if command -v gsettings >/dev/null 2>&1; then
    MATE_TERM=$(gsettings get org.mate.applications-terminal exec 2>/dev/null | tr -d "'")
    if [ -n "$MATE_TERM" ]; then
        echo "   -> Configuração lida do MATE: '$MATE_TERM'"
        CLEAN_TERM=$(echo "$MATE_TERM" | awk '{print $1}')
        if command -v "$CLEAN_TERM" >/dev/null 2>&1; then
            TARGET_TERM="$MATE_TERM"
        else
            echo "⚠️  O terminal configurado ($MATE_TERM) não foi encontrado no sistema."
        fi
    fi
else
    echo "⚠️  Comando 'gsettings' não encontrado."
fi
if [ -z "$TARGET_TERM" ]; then
    echo "⚠️  Tentando detecção manual..."
    for term in mate-terminal gnome-terminal konsole xfce4-terminal terminator alacritty kitty xterm; do
        if command -v $term >/dev/null 2>&1; then
            TARGET_TERM=$term
            echo "   -> Terminal encontrado manualmente: $TARGET_TERM"
            break
        fi
    done
fi
if [ -z "$TARGET_TERM" ]; then
    echo "❌ ERRO CRÍTICO: Nenhum emulador de terminal encontrado."
    exit 1
fi
echo "✅ Terminal definido para uso: $TARGET_TERM"
CMD_LINE="export TERMINAL=$TARGET_TERM"
CONFIG_FILES="$HOME/.bashrc $HOME/.zshrc $HOME/.profile $HOME/.xprofile $HOME/.bash_profile"
FOUND_ANY=0
for file in $CONFIG_FILES; do
    if [ -f "$file" ]; then
        FOUND_ANY=1
        if grep -q "export TERMINAL=" "$file"; then
            echo "ℹ️  O arquivo $file já possui uma configuração de TERMINAL."
        else
            echo "" >> "$file"
            echo "# Auto-config: Define terminal padrão (Rclone fix)" >> "$file"
            echo "$CMD_LINE" >> "$file"
            echo "✅ Configuração gravada em: $file"
        fi
    fi
done
if [ $FOUND_ANY -eq 0 ]; then
    echo "✅ Criando ~/.bashrc..."
    echo "$CMD_LINE" > "$HOME/.bashrc"
fi
echo "🎉 Sucesso! Variável configurada."
EOF

chmod +x fixrclone-browser.sh
./fixrclone-browser.sh

# --- ETAPA 4: Habilitação de Serviços ---
sudo systemctl enable ufw
sudo systemctl enable lightdm
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth

echo "PROCESSO FINALIZADO. REINICIANDO EM 5 SEGUNDOS..."
sleep 5
sudo reboot
