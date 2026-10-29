#!/usr/bin/env bash
# palette.sh <image_path>
#
# Derives the rice's palette from a wallpaper and pushes it to everything that can
# take colours: the shell (palette.json), Vesktop, Hyprland's window borders,
# ghostty and btop. The control panel's wallpaper picker runs this, so choosing a
# wallpaper re-themes the machine rather than only the bar.
set -euo pipefail

IMAGE="${1:-}"
if [ -z "$IMAGE" ] || [ ! -f "$IMAGE" ]; then
    echo "Usage: $0 <image_path>" >&2
    exit 1
fi

export PALETTE_IMAGE="$IMAGE"
export PALETTE_OUTPUT="$HOME/.config/quickshell/palette.json"

python3 - <<'PY'
import colorsys
import json
import os
import re
import subprocess

from PIL import Image
import numpy as np
from scipy.cluster.vq import kmeans

Image.MAX_IMAGE_PIXELS = None

HOME = os.path.expanduser("~")
IMAGE = os.environ["PALETTE_IMAGE"]
OUTPUT = os.path.expanduser(os.environ["PALETTE_OUTPUT"])


def extract_palette(image_path):
    img = Image.open(image_path).convert('RGB')
    img.thumbnail((150, 150))
    pixels = np.array(img).reshape(-1, 3).astype(float)
    try:
        centroids, _ = kmeans(pixels, 8)
    except Exception:
        centroids = pixels[:8]
    colors = []
    for c in centroids:
        r, g, b = c / 255.0
        h, l, s = colorsys.rgb_to_hls(r, g, b)
        colors.append({'rgb': (int(c[0]), int(c[1]), int(c[2])), 'h': h, 'l': l, 's': s})

    def accent_score(c):
        s, l = c['s'], c['l']
        if l < 0.20 or l > 0.88:
            return -1
        return s * (1.0 - abs(l - 0.55))

    sorted_colors = sorted(colors, key=accent_score, reverse=True)
    if sorted_colors and sorted_colors[0]['s'] > 0.10:
        best = sorted_colors[0]
    else:
        best = {'h': 0.75, 'l': 0.70, 's': 0.70}

    ah, al, asat = best['h'], best['l'], best['s']
    accent_h = ah
    accent_s = min(max(asat, 0.55), 0.88)
    accent_l = min(max(al, 0.64), 0.79)
    ar, ag, ab = colorsys.hls_to_rgb(accent_h, accent_l, accent_s)
    accent_hex = '#{:02x}{:02x}{:02x}'.format(int(ar*255), int(ag*255), int(ab*255))

    def dark(l, sat_mult=0.14):
        r, g, b = colorsys.hls_to_rgb(accent_h, l, min(accent_s * sat_mult, 0.13))
        return '#{:02x}{:02x}{:02x}'.format(int(r*255), int(g*255), int(b*255))

    def light_text(l, sat_mult=0.10):
        r, g, b = colorsys.hls_to_rgb(accent_h, l, min(accent_s * sat_mult, 0.09))
        return '#{:02x}{:02x}{:02x}'.format(int(r*255), int(g*255), int(b*255))

    # The semantic names Theme.qml uses. The Lacia structure is kept whatever the
    # wallpaper is: a blue-black ladder whose blue bias rises with lightness, an
    # accent taken from the picture, and a hair gradient built from it. Only the
    # hue moves, so a wallpaper change never turns the shell grey.
    def ladder(l, sat):
        r, g, b = colorsys.hls_to_rgb(accent_h, l, min(accent_s * sat, 0.20))
        return '#{:02x}{:02x}{:02x}'.format(int(r*255), int(g*255), int(b*255))

    return {
        # body: the accent's hue at very low saturation, getting bluer/lighter
        'glass':      ladder(0.05, 0.10),
        'bodyLow':    ladder(0.09, 0.12),
        'bodyMid':    ladder(0.13, 0.14),
        'bodyTop':    ladder(0.19, 0.16),
        'rim':        ladder(0.27, 0.20),
        'edge':       ladder(0.03, 0.08),
        'recess':     ladder(0.07, 0.10),
        # ink: cool white, very slightly tinted
        'ink':        light_text(0.94, 0.05),
        'inkDim':     light_text(0.84, 0.07),
        'inkFaint':   light_text(0.66, 0.08),
        # her hair: the accent, and two stops either side of it
        'ice':        light_text(0.90, 0.12),
        'accentCyan': '#{:02x}{:02x}{:02x}'.format(*[int(v*255) for v in
                      colorsys.hls_to_rgb((accent_h + 0.04) % 1.0, 0.70, 0.55)]),
        'accent':     accent_hex,
        'accentDeep': '#{:02x}{:02x}{:02x}'.format(*[int(v*255) for v in
                      colorsys.hls_to_rgb((accent_h - 0.03) % 1.0, 0.40, 0.62)]),
        'danger':     '#d9667f',
        # Carried alongside for the downstream targets, which need a few semantic
        # colours the shell never asks for. Not written to palette.json.
        '_warn':      '#c9955e',
        '_hue':       accent_h,
    }


def hx(rgb):
    return '#{:02x}{:02x}{:02x}'.format(int(rgb[0]), int(rgb[1]), int(rgb[2]))


def hsl(h, s, l):
    return hx([v * 255 for v in colorsys.hls_to_rgb(h % 1.0, l, s)])


def rgba(hexstr, alpha):
    return 'rgba({}{:02x})'.format(hexstr.lstrip('#'), alpha)


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        f.write(text)


palette = extract_palette(IMAGE)

shell_palette = {k: v for k, v in palette.items() if not k.startswith('_')}
write(OUTPUT, json.dumps(shell_palette, indent=2) + '\n')

# --- Vesktop ---------------------------------------------------------------
vesktop_css_dir = os.path.join(HOME, '.config', 'vesktop', 'settings')
if os.path.isdir(vesktop_css_dir):
    write(os.path.join(vesktop_css_dir, 'wallpaper-palette.css'), f'''/* Auto-generated by quickshell wallpaper palette */
:root {{
    --bg-4: {palette['bodyLow']} !important;
    --bg-3: {palette['glass']} !important;
    --bg-2: {palette['bodyMid']} !important;
    --bg-1: {palette['bodyTop']} !important;
    --text-1: {palette['ink']} !important;
    --text-2: {palette['inkDim']} !important;
    --text-3: {palette['inkFaint']} !important;
    --accent-1: {palette['accent']} !important;
    --accent-2: {palette['accent']} !important;
    --accent-3: {palette['accent']} !important;
    --accent-4: {palette['accent']} !important;
    --accent-5: {palette['accent']} !important;
    --brand-experiment: {palette['accent']} !important;
}}
''')

# --- Hyprland window borders ----------------------------------------------
# Read by hyprland.lua via dofile. Written as Lua rather than a sourced .conf
# because the Lua config is what actually wins for `general` here.
write(os.path.join(HOME, '.config', 'hypr', 'palette.lua'), f'''-- Generated by quickshell/scripts/palette.sh. Do not edit.
return {{
    active_border = {{ colors = {{ "{rgba(palette['accent'], 0xee)}", "{rgba(palette['accentCyan'], 0xee)}" }}, angle = 45 }},
    inactive_border = "{rgba(palette['rim'], 0xaa)}",
}}
''')

# --- ghostty ---------------------------------------------------------------
# ANSI slots 1/2/3/5 have no Lacia equivalent; they are derived from the accent
# hue so a terminal still has a distinguishable red/green/yellow/magenta instead
# of four greys.
ansi = [
    palette['glass'],
    palette['danger'],
    hsl(palette['_hue'] + 0.30, 0.34, 0.62),
    palette['_warn'],
    palette['accent'],
    hsl(palette['_hue'] - 0.28, 0.42, 0.68),
    palette['accentCyan'],
    palette['inkDim'],
    palette['rim'],
    hsl(palette['_hue'] - 0.28, 0.48, 0.76),
    hsl(palette['_hue'] + 0.30, 0.40, 0.74),
    hsl(palette['_hue'] + 0.12, 0.50, 0.78),
    palette['accent'],
    hsl(palette['_hue'] - 0.22, 0.45, 0.80),
    palette['ice'],
    palette['ink'],
]

ghostty_theme = [
    '# Generated by quickshell/scripts/palette.sh. Do not edit.',
    'background = ' + palette['glass'],
    'foreground = ' + palette['ink'],
    'cursor-color = ' + palette['accent'],
    'cursor-text = ' + palette['glass'],
    'selection-background = ' + palette['bodyTop'],
    'selection-foreground = ' + palette['ink'],
]
ghostty_theme += ['palette = %d=%s' % (i, c) for i, c in enumerate(ansi)]
write(os.path.join(HOME, '.config', 'ghostty', 'themes', 'lacia'), '\n'.join(ghostty_theme) + '\n')

# Point ghostty at it, in whichever config file it actually reads. This machine
# uses config.ghostty; a stock install uses config.
ghostty_dir = os.path.join(HOME, '.config', 'ghostty')
cfg = None
for name in ('config.ghostty', 'config'):
    candidate = os.path.join(ghostty_dir, name)
    if os.path.isfile(candidate):
        cfg = candidate
        break
if cfg is None:
    cfg = os.path.join(ghostty_dir, 'config')

try:
    with open(cfg) as f:
        body = f.read()
except OSError:
    body = ''

if re.search(r'(?m)^\s*theme\s*=', body):
    body = re.sub(r'(?m)^\s*theme\s*=.*$', 'theme = lacia', body)
else:
    body = body.rstrip('\n') + '\ntheme = lacia\n'
write(cfg, body)

# --- btop ------------------------------------------------------------------
btop_dir = os.path.join(HOME, '.config', 'btop')
btop_theme = f'''# Generated by quickshell/scripts/palette.sh. Do not edit.
theme[main_bg]="{palette['glass']}"
theme[main_fg]="{palette['ink']}"
theme[title]="{palette['ink']}"
theme[hi_fg]="{palette['accent']}"
theme[selected_bg]="{palette['bodyTop']}"
theme[selected_fg]="{palette['ink']}"
theme[inactive_fg]="{palette['inkFaint']}"
theme[graph_text]="{palette['inkDim']}"
theme[meter_bg]="{palette['bodyLow']}"
theme[proc_misc]="{palette['accentCyan']}"
theme[cpu_box]="{palette['rim']}"
theme[mem_box]="{palette['rim']}"
theme[net_box]="{palette['rim']}"
theme[proc_box]="{palette['rim']}"
theme[div_line]="{palette['rim']}"
theme[temp_start]="{palette['accentCyan']}"
theme[temp_mid]="{palette['_warn']}"
theme[temp_end]="{palette['danger']}"
theme[cpu_start]="{palette['accentDeep']}"
theme[cpu_mid]="{palette['accent']}"
theme[cpu_end]="{palette['accentCyan']}"
theme[free_start]="{palette['accentDeep']}"
theme[free_mid]="{palette['accent']}"
theme[free_end]="{palette['accentCyan']}"
theme[cached_start]="{palette['rim']}"
theme[cached_mid]="{palette['bodyTop']}"
theme[cached_end]="{palette['inkFaint']}"
theme[available_start]="{palette['_warn']}"
theme[available_mid]="{palette['_warn']}"
theme[available_end]="{palette['inkDim']}"
theme[used_start]="{palette['accent']}"
theme[used_mid]="{palette['accentCyan']}"
theme[used_end]="{palette['ice']}"
theme[download_start]="{palette['accentCyan']}"
theme[download_mid]="{palette['accent']}"
theme[download_end]="{palette['accentDeep']}"
theme[upload_start]="{palette['_warn']}"
theme[upload_mid]="{palette['danger']}"
theme[upload_end]="{palette['ice']}"
'''
write(os.path.join(btop_dir, 'themes', 'lacia.theme'), btop_theme)

# Seed a config from btop's own defaults the first time, so a partial file never
# hides the rest of its settings. After that only the theme line is touched, so
# hand edits survive a wallpaper change.
btop_conf = os.path.join(btop_dir, 'btop.conf')
if os.path.isfile(btop_conf):
    with open(btop_conf) as f:
        conf = f.read()
    if re.search(r'(?m)^\s*color_theme\s*=', conf):
        conf = re.sub(r'(?m)^\s*color_theme\s*=.*$', 'color_theme = "lacia"', conf)
    else:
        conf = 'color_theme = "lacia"\n' + conf
    write(btop_conf, conf)
else:
    try:
        conf = subprocess.run(['btop', '--default-config'], capture_output=True, text=True, timeout=10).stdout
    except Exception:
        conf = ''
    if not conf:
        conf = 'color_theme = "lacia"\n'
    elif re.search(r'(?m)^\s*color_theme\s*=', conf):
        conf = re.sub(r'(?m)^\s*color_theme\s*=.*$', 'color_theme = "lacia"', conf)
    else:
        conf = 'color_theme = "lacia"\n' + conf
    write(btop_conf, conf)

# --- GTK -------------------------------------------------------------------
# Two mechanisms, both checked against a real window before being wired in:
#   GTK3 (Breeze)     the theme exposes its colours as @define-color *_breeze in
#                     the user's colors.css, and re-defining those names after
#                     the import wins.
#   GTK4 (libadwaita) reads the standard named colours from gtk-4.0/gtk.css.
def gtk3_value(name, p):
    n = name.lower()
    if n.startswith('insensitive_'):
        if 'fg_color' in n:
            return p['inkFaint']
        if 'base_color' in n:
            return p['bodyMid']
        if 'selected_bg' in n:
            return p['bodyTop']
        return p['bodyLow']
    if n.startswith('theme_unfocused_') or n.startswith('unfocused_'):
        if 'fg' in n or 'text' in n:
            return p['inkDim']
        if 'selected_bg' in n:
            return p['accentDeep']
        if 'base' in n:
            return p['glass']
        return p['glass']
    if n.startswith('error_color'):
        return p['danger']
    if n.startswith('warning_color'):
        return p['_warn']
    if n.startswith('success_color'):
        return p['accentCyan']
    if n.startswith('link_visited'):
        return p['accentCyan']
    if n.startswith('link_color'):
        return p['accent']
    if n.startswith('borders'):
        return p['rim']
    if n.startswith('content_view_bg'):
        return p['glass']
    if n.startswith('tooltip_bg'):
        return p['bodyMid']
    if n.startswith('tooltip_fg'):
        return p['ink']
    if n.startswith('theme_button_background'):
        if 'hover' in n or 'active' in n:
            return p['bodyTop']
        if 'insensitive' in n:
            return p['bodyLow']
        return p['bodyMid']
    if n.startswith('theme_button_decoration'):
        return p['accent'] if 'focus' in n else p['rim']
    if n.startswith('theme_button_foreground'):
        return p['ink']
    if n.startswith('theme_selected_bg_color'):
        return p['accent']
    if n.startswith('theme_selected_fg_color'):
        return p['glass']
    if n.startswith('theme_base_color'):
        return p['glass']
    if n.startswith('theme_bg_color'):
        return p['bodyLow']
    if n.startswith('theme_fg_color') or n.startswith('theme_text_color'):
        return p['ink']
    return None


gtk3_dir = os.path.join(HOME, '.config', 'gtk-3.0')
gtk3_colors = os.path.join(gtk3_dir, 'colors.css')
if os.path.isfile(gtk3_colors):
    # Names are read from the theme's own export rather than hardcoded, so this
    # keeps working if the GTK theme is swapped for one with a different set.
    with open(gtk3_colors) as f:
        names = re.findall(r'@define-color\s+([A-Za-z0-9_]+)', f.read())
    lines = ['/* Generated by quickshell/scripts/palette.sh. Do not edit. */']
    for name in names:
        value = gtk3_value(name, palette)
        if value:
            lines.append('@define-color %s %s;' % (name, value))
    write(os.path.join(gtk3_dir, 'lacia.css'), '\n'.join(lines) + '\n')

gtk4_overrides = [
    ('accent_color', palette['accent']),
    ('accent_bg_color', palette['accent']),
    ('accent_fg_color', palette['glass']),
    ('window_bg_color', palette['glass']),
    ('window_fg_color', palette['ink']),
    ('view_bg_color', palette['bodyLow']),
    ('view_fg_color', palette['ink']),
    ('headerbar_bg_color', palette['bodyLow']),
    ('headerbar_fg_color', palette['ink']),
    ('headerbar_border_color', palette['rim']),
    ('headerbar_backdrop_color', palette['glass']),
    ('headerbar_shade_color', palette['edge']),
    ('card_bg_color', palette['bodyMid']),
    ('card_fg_color', palette['ink']),
    ('card_shade_color', palette['edge']),
    ('dialog_bg_color', palette['bodyMid']),
    ('dialog_fg_color', palette['ink']),
    ('popover_bg_color', palette['bodyMid']),
    ('popover_fg_color', palette['ink']),
    ('sidebar_bg_color', palette['bodyLow']),
    ('sidebar_fg_color', palette['ink']),
    ('sidebar_backdrop_color', palette['glass']),
    ('sidebar_shade_color', palette['edge']),
    ('destructive_bg_color', palette['danger']),
    ('destructive_fg_color', palette['ink']),
    ('destructive_color', palette['danger']),
    ('error_bg_color', palette['danger']),
    ('error_fg_color', palette['ink']),
    ('error_color', palette['danger']),
    ('warning_bg_color', palette['_warn']),
    ('warning_fg_color', palette['glass']),
    ('warning_color', palette['_warn']),
    ('success_bg_color', palette['accentCyan']),
    ('success_fg_color', palette['glass']),
    ('success_color', palette['accentCyan']),
    ('shade_color', palette['edge']),
    ('scrollbar_outline_color', palette['edge']),
    ('thumbnail_bg_color', palette['bodyTop']),
    ('thumbnail_fg_color', palette['ink']),
    ('active_toggle_bg_color', palette['bodyTop']),
    ('active_toggle_fg_color', palette['ink']),
]
gtk4_css = ['/* Generated by quickshell/scripts/palette.sh. Do not edit. */']
gtk4_css += ['@define-color %s %s;' % (n, v) for n, v in gtk4_overrides]
write(os.path.join(HOME, '.config', 'gtk-4.0', 'lacia.css'), '\n'.join(gtk4_css) + '\n')

# Import ours after the theme's own export, so the overrides win.
for sub in ('gtk-3.0', 'gtk-4.0'):
    css = os.path.join(HOME, '.config', sub, 'gtk.css')
    try:
        with open(css) as f:
            body = f.read()
    except OSError:
        body = "@import 'colors.css';\n"
    if 'lacia.css' not in body:
        body = body.rstrip('\n') + "\n@import 'lacia.css';\n"
    write(css, body)

print(json.dumps(shell_palette))
PY

# Hyprland re-reads hyprland.lua on reload, which re-runs the dofile above.
hyprctl reload >/dev/null 2>&1 || true

# ghostty reloads its config on SIGUSR2; windows opened before that keep the old
# theme until they are restarted.
pkill -USR2 -x ghostty 2>/dev/null || true