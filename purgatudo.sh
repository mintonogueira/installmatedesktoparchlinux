#!/bin/sh

# Ativa o modo verbose total para rastreamento de cada ação de remoção
set -v
set -x

echo "⚠️⚠️ INICIANDO PURGA TOTAL E DEFINITIVA - MODO SEGURANÇA MÁXIMA ⚠️⚠️"

# --- ETAPA 1: Parar e Desabilitar Serviços Imediatamente ---
echo "Encerrando e desabilitando serviços ativos..."
sudo systemctl disable --now ufw lightdm NetworkManager bluetooth 2>/dev/null

# --- ETAPA 2: Purga dos Aplicativos AUR (via Paru) ---
# Listagem completa de todos os pacotes instalados via AUR
PACOTES_AUR="webcamoid brave-bin simplescreenrecorder google-chrome octopi ocs-url archlinux-tweak-tool-git rclone-browser"

if command -v paru >/dev/null 2>&1; then
    echo "Iniciando purga dos pacotes AUR..."
    for pkg in $PACOTES_AUR; do
        # -Rns: R (remove), n (ignora backups .pacsave), s (remove dependências recursivas)
        if paru -Qi "$pkg" >/dev/null 2>&1; then
            echo "Purgando pacote AUR: $pkg"
            paru -Rns --noconfirm "$pkg"
        fi
    done

    # Limpeza total dos arquivos de build, fontes baixadas e cache do Paru
    echo "Eliminando todos os vestígios de build do Paru em ~/.cache/paru"
    paru -Scc --noconfirm
    rm -rf "$HOME/.cache/paru"
fi

# --- ETAPA 3: Purga dos Pacotes Oficiais e Ambiente Desktop ---
echo "Removendo ambiente MATE, X11 e utilitários de sistema..."

# O comando -Rns aqui garante que até os arquivos de configuração em /etc sejam removidos
sudo pacman -Rns --noconfirm \
    mate-desktop atril caja-image-converter caja-open-terminal caja-sendto \
    eom mate-applets mate-backgrounds mate-calc mate-control-center \
    mate-icon-theme mate-media mate-menus mate-notification-daemon \
    mate-panel mate-polkit mate-power-manager mate-screensaver \
    mate-session-manager mate-settings-daemon mate-system-monitor \
    mate-terminal mate-user-guide mate-utils pluma \
    xorg xorg-server lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings \
    network-manager-applet bluez bluez-utils blueman xdg-user-dirs rclone \
    flatpak gufw gparted file-roller xarchiver engrampa \
    timeshift terminator flameshot curl wget transmission-gtk

# --- ETAPA 4: Limpeza Profunda de Órfãos e Cache do Pacman ---
echo "Limpando dependências órfãs e cache de pacotes baixados..."

# Loop para garantir que todos os níveis de órfãos sejam removidos
while [ -n "$(pacman -Qdtq)" ]; do
    sudo pacman -Rns $(pacman -Qdtq) --noconfirm
done

# Limpa o cache do pacman (/var/cache/pacman/pkg/)
sudo pacman -Scc --noconfirm

# --- ETAPA 5: Remoção de Resíduos de Configuração e Scripts ---
echo "Limpando arquivos residuais no diretório Home..."
rm -f fixrclone-browser.sh
rm -rf "$HOME/paru"
rm -rf "$HOME/.config/mate"
rm -rf "$HOME/.config/terminator"

# Reversão completa das variáveis de ambiente nos arquivos de perfil
CONFIG_FILES="$HOME/.bashrc $HOME/.zshrc $HOME/.profile $HOME/.xprofile $HOME/.bash_profile"
for file in $CONFIG_FILES; do
    if [ -f "$file" ]; then
        echo "Limpando configurações em $file..."
        # Remove blocos de comentários e exportações específicas
        sed -i '/# Auto-config: Define terminal padrão (Rclone fix)/d' "$file"
        sed -i '/export TERMINAL=terminator/d' "$file"
        sed -i '/# Auto-config: Rclone fix/d' "$file"
    fi
done

# --- FINALIZAÇÃO COM PAUSA PARA CONFERÊNCIA ---
set +v
set +x
echo ""
echo "################################################################"
echo "PURGA 100% CONCLUÍDA!"
echo "Status atual:"
echo "1. Todos os pacotes AUR e Oficiais foram removidos."
echo "2. Arquivos de cache e build foram deletados."
echo "3. Serviços foram desabilitados."
echo "4. Variáveis de ambiente foram limpas."
echo "################################################################"
echo "AVISO: O sistema voltará ao terminal puro (sem interface gráfica)."
printf "Pressione [ENTER] para REINICIAR ou [Ctrl+C] para conferir os logs: "
read -r null_var

sudo reboot
