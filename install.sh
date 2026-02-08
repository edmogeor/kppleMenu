#!/bin/bash

# Install Kpple Menu Plasmoid

PLUGIN_ID="com.github.edmogeor.kppleMenu"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PACKAGE_DIR="$SCRIPT_DIR/package"
TYPE="Plasma/Applet"

global=false
for arg in "$@"; do
    case "$arg" in
        --global) global=true ;;
    esac
done

if $global; then
    echo "Installing Kpple Menu widget globally..."
    INSTALL_DIR="/usr/share/plasma/plasmoids/$PLUGIN_ID"
    GLOBAL_FLAG="-g"
else
    echo "Installing Kpple Menu widget for current user..."
    INSTALL_DIR="$HOME/.local/share/plasma/plasmoids/$PLUGIN_ID"
    GLOBAL_FLAG=""
fi

if [ -d "$INSTALL_DIR" ]; then
    echo "Existing installation found, upgrading..."
    kpackagetool6 -t "$TYPE" $GLOBAL_FLAG -u "$PACKAGE_DIR"
else
    kpackagetool6 -t "$TYPE" $GLOBAL_FLAG -i "$PACKAGE_DIR"
fi

if [ $? -eq 0 ]; then
    echo "Installation complete!"
    echo ""
    echo "To use the widget:"
    echo "1. Right-click on your panel or desktop"
    echo "2. Select 'Add Widgets...'"
    echo "3. Search for 'Kpple Menu'"
    echo "4. Drag it to your panel or desktop"
    echo ""
    echo "You may need to restart Plasma for the widget to appear:"
    echo "  systemctl --user restart plasma-plasmashell.service"
else
    echo "Installation failed."
    exit 1
fi
