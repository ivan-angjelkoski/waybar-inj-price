# waybar-inj-price

INJ (Injective) price widget for [Waybar](https://github.com/Alexays/Waybar), built for [Omarchy](https://omarchy.org/).

Shows `INJ $6.48 ▲ +18.5%` in your bar with a tooltip, green/red 24h coloring, offline caching, and click-to-open [injscan.com](https://injscan.com).

Price source: [CoinGecko](https://www.coingecko.com/) simple price API (`injective-protocol`) — the same source `injective-explorer` uses for its 24h % change. No API key needed.

## Preview

```
INJ $6.48 ▲ +18.5%
```

Tooltip:

```
Injective (INJ)
$6.48 (+18.5% 24h)
Source: CoinGecko
Updated: 2026-09-08 03:57:40
Click: open injscan.com
```

## Requirements

- Waybar with a `custom/*` module slot
- `curl`, `jq`, `python3` (python3 only used by the installer)
- Internet access (CoinGecko public API, ~10–30 req/min limit — we poll every 180s)

## Install

```bash
git clone https://github.com/<you>/waybar-inj-price.git
cd waybar-inj-price
./install.sh
```

What it does:

1. Copies `waybar-inj-price` to `~/.local/bin/` (must be on your `PATH`)
2. Backs up `~/.config/waybar/config.jsonc` and `style.css`
3. Adds `"custom/inj"` to `modules-right` + the module block (skips if already present)
4. Appends `#custom-inj` styles (skips if already present)
5. Runs `omarchy restart waybar` (or tells you to restart manually)

Manual refresh signal: `pkill -RTMIN+11 waybar`

## Configure

Edit the module block in `~/.config/waybar/config.jsonc`:

```jsonc
"custom/inj": {
  "exec": "waybar-inj-price",
  "return-type": "json",
  "interval": 180,        // poll seconds — keep >= 120 for CoinGecko limits
  "tooltip": true,
  "on-click": "xdg-open https://injscan.com >/dev/null 2>&1 &",
  "signal": 11
}
```

Move `"custom/inj"` anywhere in `modules-left` / `modules-center` / `modules-right` to reposition it.

## Uninstall

```bash
./uninstall.sh
```

Removes the binary, the module entry + styles, and clears the price cache.

## How it works

- Fetches `https://api.coingecko.com/api/v3/simple/price?ids=injective-protocol&vs_currencies=usd&include_24hr_change=true`
- Emits Waybar JSON: `{"text": ..., "tooltip": ..., "class": "up|down|stale|offline"}`
- Caches the last good response in `~/.cache/waybar-inj-price/last-good.json` so a failed poll still shows the stale price instead of going blank
- `up` = green, `down` = red, `stale`/`offline` = dimmed (see `style-snippet.css`)

## Why not the Injective asset-price API?

`injective-explorer`'s header price comes from `https://k8s.global.mainnet.asset.injective.network/asset-price/v1/denoms?withPrice=true&onlyActive=true` (on-chain INJ/USDT). It's exact but returns ~260KB per poll and no 24h change. CoinGecko's simple price is tiny and includes 24h change in one call — a better fit for a 180s bar widget. If you want the on-chain price instead, swap the `API_URL` and jq path (`.inj.price.price`).

## License

MIT
