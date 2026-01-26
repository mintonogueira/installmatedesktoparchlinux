#!/bin/sh

# Ativa o modo verbose no shell para rastreamento total de cada linha
set -v
set -x

echo "INICIANDO INSTALAÇÃO - AMBIENTE MATE, FIX RCLONE E TERMINATOR PADRÃO"

# --- ETAPA 1: Repositórios Oficiais ---
# O COMANDO: "sudo pacman -Syyu --needed --noconfirm" é respeitado e MANTIDO.
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

# --- ETAPA 2: Verificação e Instalação do Paru (AUR Helper) ---
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

# --- ETAPA 3: Instalação AUR PACOTE POR PACOTE (100% Interativa) ---
# CORREÇÃO: archlinux-tweak-tool alterado para archlinux-tweak-tool-git
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

# --- ETAPA 4.2: Configurações de Interface e Atalhos (MATE) ---
echo "Configurando Terminator como terminal padrão e atalhos de teclado..."

# Verificação de segurança antes de definir o padrão
if command -v terminator >/dev/null 2>&1; then
    gsettings set org.mate.applications-terminal exec 'terminator'
    gsettings set org.mate.applications-terminal exec-arg "-x"
    if command -v xdg-mime >/dev/null 2>&1; then
        xdg-mime default terminator.desktop x-scheme-handler/terminal
    fi
fi

# Desabilita PrintScreen padrão e define novos atalhos
gsettings set org.mate.SettingsDaemon.plugins.media-keys screenshot ''
BASE_KEY="org.mate.SettingsDaemon.plugins.external-keybindings"

# Atalho 1: Flameshot
gsettings set $BASE_KEY.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom0/ name 'flameshot'
gsettings set $BASE_KEY.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom0/ command '/usr/bin/flameshot gui'
gsettings set $BASE_KEY.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom0/ binding 'Print'

# Atalho 2: System Monitor (Ctrl+Alt+Del)
gsettings set $BASE_KEY.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom1/ name 'mate-system-monitor1'
gsettings set $BASE_KEY.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom1/ command '/usr/bin/mate-system-monitor'
gsettings set $BASE_KEY.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom1/ binding '<Control><Alt>Delete'

# Atalho 3: System Monitor (Ctrl+Shift+Esc)
gsettings set $BASE_KEY.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom2/ name 'mate-system-monitor2'
gsettings set $BASE_KEY.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom2/ command '/usr/bin/mate-system-monitor'
gsettings set $BASE_KEY.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom2/ binding '<Control><Shift>Escape'

# Atalho 4: Terminator (Ctrl+Alt+T)
gsettings set $BASE_KEY.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom3/ name 'terminator'
gsettings set $BASE_KEY.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom3/ command '/usr/bin/terminator'
gsettings set $BASE_KEY.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom3/ binding '<Control><Alt>t'

# Atalho 5: Caja (Super+E)
gsettings set $BASE_KEY.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom4/ name 'caja'
gsettings set $BASE_KEY.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom4/ command '/usr/bin/caja'
gsettings set $BASE_KEY.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom4/ binding '<Mod4>e'

gsettings set org.mate.SettingsDaemon.plugins.keybinding custom-list "['custom0', 'custom1', 'custom2', 'custom3', 'custom4']"

# --- ETAPA 4.3: Criação e Execução do Fix Rclone-Browser ---
echo "Criando e executando fixrclone-browser.sh..."

cat << 'EOF' > fixrclone-browser.sh
#!/bin/sh
echo "🔍 Detectando terminal padrão para Rclone Fix..."
TARGET_TERM=""
MATE_TERM=$(gsettings get org.mate.applications-terminal exec 2>/dev/null | tr -d "'")
if [ -n "$MATE_TERM" ] && command -v "$MATE_TERM" >/dev/null 2>&1; then
    TARGET_TERM="$MATE_TERM"
else
    TARGET_TERM="terminator"
fi
echo "✅ Terminal definido: $TARGET_TERM"
CMD_LINE="export TERMINAL=$TARGET_TERM"
CONFIG_FILES="$HOME/.bashrc $HOME/.zshrc $HOME/.profile $HOME/.xprofile $HOME/.bash_profile"
for file in $CONFIG_FILES; do
    if [ -f "$file" ]; then
        if ! grep -q "export TERMINAL=" "$file"; then
            echo "" >> "$file"
            echo "# Auto-config: Rclone fix" >> "$file"
            echo "$CMD_LINE" >> "$file"
        fi
    fi
done
EOF

chmod +x fixrclone-browser.sh
./fixrclone-browser.sh

# --- ETAPA 4: Habilitação de Serviços e Reboot ---
sudo systemctl enable ufw lightdm NetworkManager bluetooth

echo "PROCESSO CONCLUÍDO. REINICIANDO EM 5 SEGUNDOS..."
sleep 5
sudo reboot
