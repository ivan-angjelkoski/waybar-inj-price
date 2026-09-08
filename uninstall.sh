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
        print("Removed #custom-inj styles")
    else:
        print("No #custom-inj styles found, skipping")
    # Remove the theme divider override (aibar-openai is first again, so the
    # theme's own left divider must come back)
    new_css, m = re.subn(r'\n/\* waybar-inj-price: custom/inj sits first.*?\n\}\n', "\n", new_css, flags=re.DOTALL)
    if m:
        print("Removed theme divider override")
    # custom/inj owned the group's left edge while installed; hand it back to
    # ai-usagebar (now first again) so its left divider returns.
    if "#custom-aibar-openai" in new_css and "border-left" not in new_css:
        anchor = "#custom-aibar-openai,\n#custom-aibar-zai,\n#custom-aibar-opencode {\n  border-right:"
        edge = "#custom-aibar-openai {\n  border-left: 1px solid alpha(@foreground, 0.2);\n  padding-left: 15px;\n}\n\n"
        if anchor in new_css:
            new_css = new_css.replace(anchor, edge + anchor, 1)
            print("Restored #custom-aibar-openai left edge")
    with open(style_path, "w") as f:
        f.write(new_css)
EOF

rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/waybar-inj-price"
echo "Cleared price cache."

if command -v omarchy >/dev/null 2>&1; then
  omarchy restart waybar
  echo "Waybar restarted."
fi

echo "Done."
