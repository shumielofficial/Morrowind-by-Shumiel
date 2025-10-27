#!/bin/bash
#==================================================================
# Fully Automated OpenMW + MOMW / UMO / Morrowind Mod Setup Script
#
# Official UMO URLs:
#   - https://modding-openmw.gitlab.io/umo/
#   - https://modding-openmw.com/guides/auto/
#
# Supported systems:
#   - Debian / Ubuntu / Mint (APT-based only)
#
# Status:
#   - Confirmed working on Linux Mint (VMware environment)
#   - For UMO "Slow download" issues, avoid Tampermonkey / Tab Wrangler
#   - Recommended: use Nexus Premium for faster mod downloads
#
# Note:
#   If any of my scripts or resources from this repository
#   helped you, taught you something new, or even just inspired you —
#   please consider supporting me by subscribing to my YouTube channels:
#
#     PL:  https://www.youtube.com/@Shumiel
#     ENG: https://www.youtube.com/@ShuTastyBytes
#
# Your support keeps me motivated and fuels future initiatives.
#==================================================================

#==================================================================
# ========================= CONFIGURATION =========================
#==================================================================

# OpenMW
OPENMW_VERSION="${OPENMW_VERSION:-0.49.0}"
OPENMW_INSTALL_DIR="${OPENMW_INSTALL_DIR:-$HOME/games/OpenMW}"
OPENMW_BIN="$OPENMW_INSTALL_DIR/bin/openmw"
OPENMW_LAUNCHER_BIN="$OPENMW_INSTALL_DIR/bin/openmw-launcher"

# MOMW Tools Pack
TOOLS_PACK_URL="${TOOLS_PACK_URL:-https://gitlab.com/modding-openmw/momw-tools-pack/-/package_files/212976856/download}"
TOOLS_PACK_DIR="${TOOLS_PACK_DIR:-$HOME/games/momw-tools-pack}"
CONFIGURATOR_BIN="$TOOLS_PACK_DIR/momw-configurator-linux-amd64"

# UMO
MODS_DIR="${MODS_DIR:-$HOME/games/morrowind-mods}"
CACHE_DIR="${CACHE_DIR:-$HOME/.cache/morrowind-mods}"
MODLIST="${MODLIST:-total-overhaul}"
UMO_BIN="$TOOLS_PACK_DIR/umo"

# OpenMW Settings
OPENMW_CONFIG_DIR="${OPENMW_CONFIG_DIR:-$HOME/.config/openmw}"
SETTINGS_FILE="$OPENMW_CONFIG_DIR/settings.cfg"

#==================================================================
# ======================= SYSTEM DEPENDENCIES =====================
#==================================================================
echo "===== Installing system dependencies ====="
sudo apt update -y
sudo apt upgrade -y

## Target for Radeon and AMD
#
sudo apt install -y \
    curl tar mesa-utils mesa-vulkan-drivers vulkan-tools \
    libsdl2-2.0-0 libsdl2-image-2.0-0 libsdl2-mixer-2.0-0 libsdl2-ttf-2.0-0 \
    open-vm-tools open-vm-tools-desktop steam pulseaudio unzip

sudo systemctl enable --now open-vm-tools.service || true
systemctl --user restart pulseaudio || echo "Pulseaudio restarted"

#==================================================================
# ==================== STEAM & MORROWIND PROMPT ===================
#==================================================================
echo "===== Launching Steam ====="
echo "Please log in and install Morrowind before continuing."
echo "UMO/OpenMW setup requires access to Morrowind's Data Files."
echo "Once Morrowind is installed, re-run UMO or MOMW Configurator if needed."

# Launch Steam in background
# steam &

# Pause until user confirms installation
# read -p "Press Enter once Morrowind is installed. Remember to check where you installed Morrowind!"

#==================================================================
# =========================== OPENMW INSTALL ======================
#==================================================================
echo "===== Installing OpenMW ${OPENMW_VERSION} ====="
mkdir -p /tmp/openmw_install
cd /tmp/openmw_install

OPENMW_URL="https://github.com/OpenMW/openmw/releases/download/openmw-${OPENMW_VERSION}/openmw-${OPENMW_VERSION}-Linux-64Bit.tar.gz"
curl -L -o openmw.tar.gz "$OPENMW_URL"

mkdir -p "$OPENMW_INSTALL_DIR"
tar -xzf openmw.tar.gz -C "$OPENMW_INSTALL_DIR" --strip-components=1

mkdir -p "$HOME/.local/bin"
ln -sf "$OPENMW_BIN" "$HOME/.local/bin/openmw"
ln -sf "$OPENMW_LAUNCHER_BIN" "$HOME/.local/bin/openmw-launcher"
export PATH="$HOME/.local/bin:$PATH"

cd ~
rm -rf /tmp/openmw_install
echo "OpenMW installed at $OPENMW_INSTALL_DIR"

#==================================================================
# ======================== MOMW TOOLS PACK ========================
#==================================================================
echo "===== Installing MOMW Tools Pack ====="
mkdir -p /tmp/momw_tools_install
cd /tmp/momw_tools_install

curl -L -o momw-tools-pack.tar.gz "$TOOLS_PACK_URL"
mkdir -p "$TOOLS_PACK_DIR"
tar -xzf momw-tools-pack.tar.gz -C "$TOOLS_PACK_DIR"

cd ~
rm -rf /tmp/momw_tools_install
echo "MOMW Tools Pack installed at $TOOLS_PACK_DIR"

#==================================================================
# ==================== DESKTOP SHORTCUT & MAPPING =================
#==================================================================
echo "===== Creating desktop shortcuts for OpenMW folders ====="

# Detect desktop directory (handles both English and localized systems)
DESKTOP_DIR="$HOME/Desktop"
[ ! -d "$DESKTOP_DIR" ] && DESKTOP_DIR="$HOME/Pulpit"

# Ensure required folders exist
mkdir -p "$HOME/games/OpenMW"
mkdir -p "$HOME/games/momw-tools-pack"
mkdir -p "$HOME/games/morrowind-mods"

# Create launcher wrapper
WRAPPER_PATH="$HOME/.local/bin/openmw-launcher-wrapper.sh"
mkdir -p "$(dirname "$WRAPPER_PATH")"
cat > "$WRAPPER_PATH" <<'EOL'
#!/bin/bash
"$HOME/games/OpenMW/openmw-launcher"
EOL
chmod +x "$WRAPPER_PATH"

# Create OpenMW launcher desktop icon
DESKTOP_FILE="$DESKTOP_DIR/OpenMW.desktop"
cat > "$DESKTOP_FILE" <<EOL
[Desktop Entry]
Name=OpenMW Launcher
Comment=Launch Morrowind via OpenMW
Exec=$WRAPPER_PATH
Icon=$HOME/games/OpenMW/share/icons/openmw.png
Terminal=false
Type=Application
Categories=Game;
EOL
chmod +x "$DESKTOP_FILE"
echo "Created OpenMW launcher icon at $DESKTOP_FILE"

# Helper function to make real folder shortcuts
create_folder_shortcut() {
    local target_dir="$1"
    local name="$2"
    local file="$DESKTOP_DIR/${name}.desktop"
    if [ -d "$target_dir" ]; then
        cat > "$file" <<EOL
[Desktop Entry]
Name=$name
Comment=Open $name folder
Exec=xdg-open "$target_dir"
Icon=folder
Terminal=false
Type=Application
Categories=Utility;
EOL
        chmod +x "$file"
        echo "Created desktop shortcut for: $name"
    else
        echo "Skipping $name — folder not found: $target_dir"
    fi
}

# Create real folder shortcuts
create_folder_shortcut "$HOME/games/OpenMW" "OpenMW-Folder"
create_folder_shortcut "$HOME/games/momw-tools-pack" "MOMW-Tools-Folder"
create_folder_shortcut "$HOME/games/morrowind-mods" "Morrowind-Mods-Folder"

# Detect Steam Morrowind installation
STEAM_MORROWIND_DIR="$HOME/.steam/steam/steamapps/common/Morrowind"
create_folder_shortcut "$STEAM_MORROWIND_DIR" "Morrowind-Steam-Folder"

echo "===== Desktop folder shortcuts created successfully ====="

#==================================================================
# ============================= UMO SETUP =========================
#==================================================================
if [[ ! -x "$UMO_BIN" ]]; then
    echo "UMO executable not found in $TOOLS_PACK_DIR."
    exit 1
fi

echo "===== Running UMO setup ====="
cd "$TOOLS_PACK_DIR"
"$UMO_BIN" setup

mkdir -p "$MODS_DIR" "$CACHE_DIR"
export UMO_MODS_DIR="$MODS_DIR"
export UMO_CACHE_DIR="$CACHE_DIR"

echo "===== Installing modlist '${MODLIST}' ====="
"$UMO_BIN" install --sync "$MODLIST"
echo "Modlist '${MODLIST}' installed into $MODS_DIR"

#==================================================================
# ======================= MOMW CONFIGURATOR =======================
#==================================================================
if [[ ! -x "$CONFIGURATOR_BIN" ]]; then
    echo "MOMW Configurator executable not found in $TOOLS_PACK_DIR."
    exit 1
fi

cd "$TOOLS_PACK_DIR"
echo "===== Running MOMW Configurator ====="
if [[ "$OPENMW_VERSION" == "0.49"* ]]; then
    "$CONFIGURATOR_BIN" config "$MODLIST" --run-navmeshtool --run-validator --verbose
else
    "$CONFIGURATOR_BIN" config "$MODLIST" --run-navmeshtool --run-validator --verbose --dev
fi

#==================================================================
# ====================== FINAL SETTINGS GUIDE =====================
#==================================================================
echo "===== OpenMW Settings Guidance ====="
echo "Settings file location: $SETTINGS_FILE"
echo "1. DO NOT edit settings.cfg while OpenMW Launcher is open."
echo "2. DO NOT open the Launcher while settings.cfg is open in a text editor."
echo "3. Use Launcher Settings menu for detailed options and tooltips."
echo "4. Reapply Configurator settings anytime by running:"
echo "   cd $TOOLS_PACK_DIR && ./momw-configurator-linux-amd64 config $MODLIST"
echo "=================================================================="

echo "===== Installation Complete ====="
echo "You can now launch OpenMW via 'openmw-launcher' or 'openmw'."


