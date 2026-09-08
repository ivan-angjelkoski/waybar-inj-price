#!/bin/bash
# uninstall.sh — remove waybar-inj-price widget
set -euo pipefail

BIN_TARGET="$HOME/.local/bin/waybar-inj-price"
WAYBAR_DIR="$HOME/.config/waybar"
CONFIG="$WAYBAR_DIR/config.jsonc"
STYLE="$WAYBAR_DIR/style.css"

echo "==> waybar-inj-price uninstaller"

rm -f "$BIN_TARGET"
echo "Removed $BIN_TARGET"

CONFIG="$CONFIG" STYLE="$STYLE" python3 - <<'EOF'
import os, re

config_path = os.environ["CONFIG"]
style_path = os.environ["STYLE"]

if os.path.exists(config_path):
    with open(config_path) as f:
        cfg = f.read()
    # Remove from modules arrays
    cfg = re.sub(r'\s*"custom/inj",?\n?', "\n", cfg)
    # Remove module block (from "custom/inj": { ... } up to matching brace at same indent)
    cfg = re.sub(r'\n  "custom/inj": \{.*?\n  \},?\n', "\n", cfg, flags=re.DOTALL)
    with open(config_path, "w") as f:
        f.write(cfg)
    print("Removed custom/inj from config.jsonc")

if os.path.exists(style_path):
    with open(style_path) as f:
        css = f.read()
    # Remove our snippet (everything from #custom-inj { to the stale/offline rule)
    new_css, n = re.subn(r'\n#custom-inj \{.*?\n#custom-inj\.stale,\n#custom-inj\.offline \{.*?\n\}\n', "\n", css, flags=re.DOTALL)
    if n:
        with open(style_path, "w") as f:
            f.write(new_css)
        print("Removed #custom-inj styles")
    else:
        print("No #custom-inj styles found, skipping")
EOF

rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/waybar-inj-price"
echo "Cleared price cache."

if command -v omarchy >/dev/null 2>&1; then
  omarchy restart waybar
  echo "Waybar restarted."
fi

echo "Done."
