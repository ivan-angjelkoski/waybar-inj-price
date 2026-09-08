#!/bin/bash
# install.sh — install waybar-inj-price (INJ price widget for Waybar/Omarchy)
# Idempotent: safe to re-run. Backs up waybar config before patching.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_TARGET="$HOME/.local/bin/waybar-inj-price"
WAYBAR_DIR="$HOME/.config/waybar"
CONFIG="$WAYBAR_DIR/config.jsonc"
STYLE="$WAYBAR_DIR/style.css"

echo "==> waybar-inj-price installer"

# 1. Deps
for dep in curl jq python3; do
  if ! command -v "$dep" >/dev/null 2>&1; then
    echo "Missing dependency: $dep. Install it first (e.g.: omarchy pkg add $dep)" >&2
    exit 1
  fi
done

# 2. Install script
mkdir -p "$(dirname "$BIN_TARGET")" "$WAYBAR_DIR"
cp "$REPO_DIR/waybar-inj-price" "$BIN_TARGET"
chmod +x "$BIN_TARGET"
echo "Installed script -> $BIN_TARGET"

# 3. Verify script works
if ! "$BIN_TARGET" | jq -e '.text' >/dev/null; then
  echo "Warning: script ran but output was unexpected (offline?). Continuing." >&2
fi

# 4. Patch waybar config + style (backups first)
if [ -f "$CONFIG" ]; then
  cp "$CONFIG" "$CONFIG.bak.$(date +%s)"
fi
if [ -f "$STYLE" ]; then
  cp "$STYLE" "$STYLE.bak.$(date +%s)"
fi

MODULE_JSON="$(cat "$REPO_DIR/waybar-module.jsonc")"
CSS_SNIPPET="$(cat "$REPO_DIR/style-snippet.css")"

CONFIG="$CONFIG" STYLE="$STYLE" MODULE_JSON="$MODULE_JSON" CSS_SNIPPET="$CSS_SNIPPET" python3 - <<'EOF'
import os, re

config_path = os.environ["CONFIG"]
style_path = os.environ["STYLE"]
module_json = os.environ["MODULE_JSON"].rstrip() + "\n"
css_snippet = os.environ["CSS_SNIPPET"].strip() + "\n"

with open(config_path) as f:
    cfg = f.read()

# a) Ensure "custom/inj" is in modules-right
if '"custom/inj"' not in cfg:
    m = re.search(r'"modules-right"\s*:\s*\[', cfg)
    if not m:
        raise SystemExit("Could not find modules-right in config.jsonc")
    cfg = cfg[:m.end()] + '\n    "custom/inj",' + cfg[m.end():]
    print('Added "custom/inj" to modules-right')
else:
    print('"custom/inj" already in modules-right, skipping')

# b) Ensure module block exists
if re.search(r'"custom/inj"\s*:', cfg):
    print('"custom/inj" block already present, skipping')
else:
    # Insert before the last top-level closing brace
    idx = cfg.rfind("}")
    assert idx != -1
    # Add comma to previous block if needed
    head = cfg[:idx].rstrip()
    if not head.endswith(",") and not head.endswith("{"):
        head += ","
    cfg = head + "\n" + module_json + cfg[idx:]
    print('Added "custom/inj" module block')

with open(config_path, "w") as f:
    f.write(cfg)

# c) Ensure CSS snippet present
if os.path.exists(style_path):
    with open(style_path) as f:
        css = f.read()
else:
    css = ""
if "#custom-inj" not in css:
    if css and not css.endswith("\n"):
        css += "\n"
    css += "\n" + css_snippet
    with open(style_path, "w") as f:
        f.write(css)
    print("Appended #custom-inj styles")
else:
    print("#custom-inj styles already present, skipping")
EOF

# 5. Restart waybar (Omarchy) so changes take effect
if command -v omarchy >/dev/null 2>&1; then
  omarchy restart waybar
  echo "Waybar restarted."
else
  echo "Installed. Restart waybar manually (e.g. pkill waybar; waybar &)."
fi

echo "Done. You should now see INJ price in the right modules."
echo "Click it to open https://injscan.com"
echo "Refresh interval: 180s. Manual refresh: pkill -RTMIN+11 waybar"
