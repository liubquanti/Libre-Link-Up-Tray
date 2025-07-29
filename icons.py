from PIL import Image, ImageDraw, ImageFont
import os

size = (16, 16)
font_size = 12
base_output_dir = "assets/tray"
themes = {
    "black": "black",
    "white": "white",
}
font_path = "arial.ttf"

try:
    font = ImageFont.truetype(font_path, font_size)
except IOError:
    font = ImageFont.load_default()

for theme in themes:
    os.makedirs(os.path.join(base_output_dir, theme), exist_ok=True)

for i in range(1, 501):
    text = str(i)

    for theme, color in themes.items():
        img = Image.new("RGBA", size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)

        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        x = (size[0] - text_width) // 2
        y = (size[1] - text_height) // 2 - 1

        draw.text(
            (x, y),
            text,
            font=font,
            fill=color,
            stroke_width=0.2,
            stroke_fill=color
        )

        output_path = os.path.join(base_output_dir, theme, f"{i}.ico")
        img.save(output_path, format="ICO")
