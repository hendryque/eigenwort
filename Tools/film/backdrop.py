"""Blurred paragraphs: the icon's one-word-among-many, out of focus, as the
film's ground. One per look, from that theme's paper, ink and accent."""
import random
from PIL import Image, ImageDraw, ImageFilter

# Wide for the film, tall for the portrait film and the README stills.
SIZES = {"wide": (1920, 1080), "tall": (1080, 1920)}
LOOKS = {  # ground, ink, accent
    "light":   ((243, 237, 226), (60, 52, 40), (229, 85, 48)),
    "sepia":   ((232, 220, 194), (61, 47, 29), (196, 66, 30)),
    "dark":    ((20, 20, 22), (232, 232, 234), (255, 133, 86)),
    "debug":   ((221, 217, 208), (28, 27, 25), (201, 0, 107)),
    "gimmick": ((255, 232, 82), (8, 107, 173), (231, 41, 33)),
}

def layer(W, H, rnd, ink, accent, bar, pitch, alpha, accents, tilt):
    big = Image.new("RGBA", (int(W * 1.4), int(H * 1.6)), (0, 0, 0, 0)); d = ImageDraw.Draw(big)
    for row, y in enumerate(range(0, big.height, pitch)):
        if rnd.random() < 0.18:
            continue  # a paragraph break
        x = rnd.randint(-bar * 4, 0) + (bar * 3 if row % 6 == 0 else 0)
        end = big.width - rnd.choice([0, 0, 0, bar * 12])
        while x < end:
            w = rnd.choice([2, 3, 4, 5, 6, 7, 9]) * bar
            is_accent = rnd.random() < accents
            col = accent + (min(255, alpha * 3),) if is_accent else ink + (alpha,)
            d.rounded_rectangle([x, y, x + w, y + bar], radius=bar // 2, fill=col)
            x += w + int(bar * 1.1)
    big = big.rotate(tilt, resample=Image.BICUBIC)
    left, top = (big.width - W) // 2, (big.height - H) // 2
    return big.crop((left, top, left + W, top + H))

def backdrop(look, W, H, seed=7):
    ground, ink, accent = LOOKS[look]
    rnd = random.Random(seed)
    base = Image.new("RGBA", (W, H), ground + (255,))
    far = layer(W, H, rnd, ink, accent, 64, 150, 22, 0.035, -7).filter(ImageFilter.GaussianBlur(34))
    near = layer(W, H, rnd, ink, accent, 30, 84, 16, 0.04, -7).filter(ImageFilter.GaussianBlur(14))
    base.alpha_composite(far); base.alpha_composite(near)
    # A soft lift in the middle, where the phone stands.
    glow = Image.new("L", (W, H), 0); ImageDraw.Draw(glow).ellipse([W * 0.2, H * 0.05, W * 0.8, H * 0.95], fill=255)
    lift = Image.new("RGBA", (W, H), ground + (0,)); lift.putalpha(glow.filter(ImageFilter.GaussianBlur(220)).point(lambda v: v * 0.55))
    base.alpha_composite(lift)
    return base.convert("RGB")

if __name__ == "__main__":
    import pathlib, sys
    out = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    out.mkdir(parents=True, exist_ok=True)
    for shape, (W, H) in SIZES.items():
        for look in LOOKS:
            backdrop(look, W, H).save(out / f"{look}-{shape}.png")
