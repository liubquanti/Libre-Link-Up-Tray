from __future__ import annotations

import io
import re
import sys
from pathlib import Path
from typing import Iterable

_SCRIPT_DIR = Path(__file__).parent.resolve()
sys.path = [p for p in sys.path if Path(p).resolve() != _SCRIPT_DIR]
sys.path.append(str(_SCRIPT_DIR))

from PIL import Image

try:
	import cairosvg
except ImportError as exc:  
	raise SystemExit(
		"cairosvg is required: pip install cairosvg"
	) from exc

BASE_OUTPUT_DIR = Path("assets/tray")
THEMES = {
	"black": (0, 0, 0, 255),
	"white": (255, 255, 255, 255),
}

SVG_INPUT_FILE = Path(__file__).with_name("svg.txt")

DEFAULT_SVGS = [
	'<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">\n'
	'  <path d="M2 8h12" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>\n'
	'  <path d="M8 2v12" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>\n'
	'</svg>',
]

def load_svg_lines() -> list[str]:
	if SVG_INPUT_FILE.exists():
		with SVG_INPUT_FILE.open("r", encoding="utf-8") as f:
			return [line.strip() for line in f.readlines() if line.strip()]
	return DEFAULT_SVGS

def infer_name(svg_text: str, fallback: str) -> str:
	
	match = re.search(r"icon-tabler-([a-z0-9_-]+)", svg_text)
	if match:
		return match.group(1)
	return fallback

def svg_to_image(svg_text: str, size: tuple[int, int] = (16, 16)) -> Image.Image:
	png_bytes = cairosvg.svg2png(bytestring=svg_text.encode("utf-8"),
								 output_width=size[0],
								 output_height=size[1])
	return Image.open(io.BytesIO(png_bytes)).convert("RGBA")

def recolor(img: Image.Image, color: tuple[int, int, int, int]) -> Image.Image:
	base = Image.new("RGBA", img.size, color)
	alpha = img.getchannel("A")
	base.putalpha(alpha)
	return base

def save_icon(img: Image.Image, theme: str, name: str) -> None:
	out_dir = BASE_OUTPUT_DIR / theme
	out_dir.mkdir(parents=True, exist_ok=True)
	out_path = out_dir / f"{name}.ico"
	img.save(out_path, format="ICO")
	print(f"Saved {out_path}")

def generate_icons(svg_lines: Iterable[str]) -> None:
	for idx, svg_text in enumerate(svg_lines, start=1):
		icon_name = infer_name(svg_text, f"custom_{idx}")
		base_img = svg_to_image(svg_text)

		for theme, color in THEMES.items():
			themed_img = recolor(base_img, color)
			save_icon(themed_img, theme, icon_name)

if __name__ == "__main__":
	svgs = load_svg_lines()
	if not svgs:
		raise SystemExit("No SVG lines provided")
	generate_icons(svgs)
