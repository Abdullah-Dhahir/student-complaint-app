from PIL import Image, ImageDraw, ImageFont
import math

FONT_PATH = r"C:\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf"
PRIMARY   = (30, 58, 138)   # dark blue matching the app
ACCENT    = (251, 191, 36)  # amber/gold matching the app accent
WHITE     = (255, 255, 255)

# School icon unicode character in Material Icons font
SCHOOL_ICON = ""

# ── App Icon 512×512 ──────────────────────────────────────────────────────────
W, H = 512, 512
icon = Image.new("RGBA", (W, H), (0, 0, 0, 0))
draw = ImageDraw.Draw(icon)

# Rounded background circle
margin = 20
draw.ellipse([margin, margin, W - margin, H - margin], fill=PRIMARY)

# School icon centered
icon_font = ImageFont.truetype(FONT_PATH, 260)
bbox = draw.textbbox((0, 0), SCHOOL_ICON, font=icon_font)
iw, ih = bbox[2] - bbox[0], bbox[3] - bbox[1]
x = (W - iw) // 2 - bbox[0]
y = (H - ih) // 2 - bbox[1] - 20
draw.text((x, y), SCHOOL_ICON, font=icon_font, fill=ACCENT)

icon.save("icon_512.png")
print("icon_512.png saved")

# ── Feature Graphic 1024×500 ──────────────────────────────────────────────────
FW, FH = 1024, 500
feat = Image.new("RGB", (FW, FH), PRIMARY)
draw = ImageDraw.Draw(feat)

# Small school icon on the left
small_icon_font = ImageFont.truetype(FONT_PATH, 180)
bbox = draw.textbbox((0, 0), SCHOOL_ICON, font=small_icon_font)
iw, ih = bbox[2] - bbox[0], bbox[3] - bbox[1]
draw.text((80 - bbox[0], (FH - ih) // 2 - bbox[1] - 20),
          SCHOOL_ICON, font=small_icon_font, fill=ACCENT)

# App name text
try:
    text_font  = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 72)
    small_font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 36)
except:
    text_font  = ImageFont.load_default()
    small_font = ImageFont.load_default()

title = "TIU Complaint System"
sub   = "Tishk International University"

tbbox = draw.textbbox((0, 0), title, font=text_font)
tw = tbbox[2] - tbbox[0]
tx = 320
ty = 140
draw.text((tx, ty), title, font=text_font, fill=WHITE)

sbbox = draw.textbbox((0, 0), sub, font=small_font)
draw.text((tx, ty + 100), sub, font=small_font, fill=(180, 200, 255))

# Accent line
draw.rectangle([tx, ty + 90, tx + tw, ty + 94], fill=ACCENT)

feat.save("feature_graphic_1024x500.png")
print("feature_graphic_1024x500.png saved")
