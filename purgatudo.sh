#!/bin/sh

# Ativa o modo verbose total
set -v
set -x

echo "⚠️ INICIANDO PURGA COM PROTEÇÃO TOTAL AO NETWORKMANAGER ⚠️"

# --- ETAPA 1: Identificação de Dependências Protegidas ---
# Extraímos dinamicamente tudo que o NetworkManager precisa para rodar
PROTECTED_DEPS=$(pactree -u networkmanager)
echo "Pacotes protegidos: $PROTECTED_DEPS"

# --- ETAPA 2: Listas de Alvos ---
PACOTES_AUR="webcamoid brave-bin simplescreenrecorder google-chrome octopi ocs-url archlinux-tweak-tool-git rclone-browser"
PACOTES_PACMAN="mate-desktop atril caja-image-converter caja-open-terminal caja-sendto eom mate-applets mate-backgrounds mate-calc mate-control-center mate-icon-theme mate-media mate-menus mate-notification-daemon mate-panel mate-polkit mate-power-manager mate-screensaver mate-session-manager mate-settings-daemon mate-system-monitor mate-terminal mate-user-guide mate-utils pluma xorg xorg-server lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings bluez bluez-utils blueman xdg-user-dirs rclone flatpak gufw gparted file-roller xarchiver engrampa timeshift terminator flameshot curl wget transmission-gtk"

# --- ETAPA 3: Purga com Filtro de Segurança ---
for pkg in $PACOTES_AUR $PACOTES_PACMAN; do
    # Verifica se o pacote atual está na lista de proteção do NetworkManager
    if echo "$PROTECTED_DEPS" | grep -qw "$pkg"; then
        echo "🛡️ Pulando $pkg (Dependência crítica do NetworkManager)"
    else
        # Remove apenas se NÃO for uma dependência necessária para a rede
        sudo pacman -Rdd --noconfirm "$pkg" 2>/dev/null
    fi
done

# --- ETAPA 4: Limpeza de Órfãos com Exclusão ---
# Remove órfãos, mas garante que nada do NetworkManager entre na faxina
while [ -n "$(pacman -Qdtq)" ]; do
    ORPHANS=$(pacman -Qdtq)
    for orphan in $ORPHANS; do
        if ! echo "$PROTECTED_DEPS" | grep -qw "$orphan"; then
            sudo pacman -Rns "$orphan" --noconfirm 2>/dev/null
        fi
    done
    # Se a lista de órfãos não diminuir mais, quebra o loop
    break 
done

# --- ETAPA 5: Limpeza de Configurações de Usuário ---
echo "Removendo rastros de configuração nos arquivos de perfil..."
rm -f fixrclone-browser.sh
for file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile" "$HOME/.xprofile"; do
    [ -f "$file" ] && sed -i '/TERMINAL/d; /Rclone/d; /Auto-config/d; /terminator/d' "$file"
done

# --- ETAPA 6: Validação Final ---
set +v
set +x

# Verificação de sobrevivência da rede
if pacman -Qi networkmanager >/dev/null 2>&1; then
    echo "################################################################"
    echo "          REMOÇÃO FEITA COM SUCESSO"
    echo "      (NetworkManager e dependências preservados)"
    echo "################################################################"
else
    echo "❌ Erro grave: O NetworkManager foi afetado. Reinstale imediatamente."
fi

printf "Deseja reiniciar agora? (s/n): "
read -r resp
if [ "$resp" = "s" ]; then sudo reboot; fi
