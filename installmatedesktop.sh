#!/bin/sh

# Ativa o modo verbose no shell para rastreamento total
set -v
set -x

echo "INICIANDO INSTALAÇÃO - VERSÃO COM ATALHOS CORRIGIDOS E PAUSA"

# --- ETAPA 1: Repositórios Oficiais ---
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

# --- ETAPA 2: Verificação do Paru ---
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

# --- ETAPA 3: Instalação AUR PACOTE POR PACOTE ---
PACOTES_AUR="webcamoid brave-bin simplescreenrecorder google-chrome octopi ocs-url archlinux-tweak-tool-git rclone-browser"
for pkg in $PACOTES_AUR; do
    set +v +x
    printf "Deseja instalar o pacote AUR [%s]? (s/n): " "$pkg"
    read -r resposta
    set -v -x
    if [ "$resposta" = "s" ] || [ "$resposta" = "S" ]; then paru -S --needed --noconfirm "$pkg"; fi
done

# --- ETAPA 4.2: Configurações de Interface e Atalhos (MATE) ---
echo "Configurando Terminator e Atalhos de Teclado..."

# Define Terminator como padrão
if command -v terminator >/dev/null 2>&1; then
    gsettings set org.mate.applications-terminal exec 'terminator'
    gsettings set org.mate.applications-terminal exec-arg "-x"
fi

# Limpa o PrintScreen padrão
gsettings set org.mate.SettingsDaemon.plugins.media-keys screenshot ''

# Configuração detalhada de atalhos personalizados
BASE="org.mate.SettingsDaemon.plugins.external-keybindings"

# Atalho 1: Flameshot (Print)
gsettings set $BASE.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom0/ name 'flameshot'
gsettings set $BASE.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom0/ command 'flameshot gui'
gsettings set $BASE.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom0/ binding 'Print'

# Atalho 2: System Monitor (Ctrl+Alt+Del)
gsettings set $BASE.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom1/ name 'mate-system-monitor1'
gsettings set $BASE.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom1/ command 'mate-system-monitor'
gsettings set $BASE.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom1/ binding '<Control><Alt>Delete'

# Atalho 3: System Monitor (Ctrl+Shift+Esc)
gsettings set $BASE.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom2/ name 'mate-system-monitor2'
gsettings set $BASE.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom2/ command 'mate-system-monitor'
gsettings set $BASE.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom2/ binding '<Control><Shift>Escape'

# Atalho 4: Terminator (Ctrl+Alt+T)
gsettings set $BASE.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom3/ name 'terminator'
gsettings set $BASE.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom3/ command 'terminator'
gsettings set $BASE.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom3/ binding '<Control><Alt>t'

# Atalho 5: Caja (Super+E)
gsettings set $BASE.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom4/ name 'caja'
gsettings set $BASE.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom4/ command 'caja'
gsettings set $BASE.custom-keybindings:/org/mate/settings-daemon/plugins/external-keybindings/custom4/ binding '<Mod4>e'

# Ativa a lista de atalhos
gsettings set org.mate.SettingsDaemon.plugins.keybinding custom-list "['custom0', 'custom1', 'custom2', 'custom3', 'custom4']"

# --- ETAPA 4.3: Fix Rclone-Browser ---
cat << 'EOF' > fixrclone-browser.sh
#!/bin/sh
CMD_LINE="export TERMINAL=terminator"
for file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile" "$HOME/.xprofile"; do
    [ -f "$file" ] && ! grep -q "export TERMINAL=" "$file" && echo "$CMD_LINE" >> "$file"
done
EOF
chmod +x fixrclone-browser.sh
./fixrclone-browser.sh

# --- ETAPA 4: Habilitação de Serviços ---
sudo systemctl enable ufw lightdm NetworkManager bluetooth

# --- FINALIZAÇÃO COM PAUSA ---
set +v
set +x
echo ""
echo "################################################################"
echo "PROCESSO CONCLUÍDO!"
echo "Todos os pacotes foram instalados e os atalhos foram configurados."
echo "Por favor, revise as mensagens acima."
echo "################################################################"
printf "Pressione [ENTER] para reiniciar o sistema ou [Ctrl+C] para sair: "
read -r null_var

sudo reboot
