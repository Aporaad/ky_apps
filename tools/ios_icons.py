"""توليد أيقونات iOS من شعار الشركة — يُشغَّل مرة عند تغيير الشعار فقط.

يهدف السكربت إلى إنتاج مجموعة AppIcon.appiconset كاملة انطلاقاً من ملف واحد
عالٍ الدقة، بدل تعديل خمسة عشر ملفاً يدوياً:

  * iOS يرفض أي أيقونة تحمل قناة شفافية (alpha)، لذلك يُسطَّح الشعار على خلفية
    بيضاء معتمة قبل التصدير.
  * يُوسَّط الشعار مع حشوة بسيطة حتى لا تقصّ iOS زواياه عند تقريب الأيقونة.

الاستعمال:
    python tools/ios_icons.py

المدخل:  assets/logo1.png  (مربّع عالي الدقة بخلفية شفافة)
المخرج: ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png

Generates the full iOS AppIcon set from the single high-resolution company logo.

  * iOS rejects icons that carry an alpha channel, so the logo is flattened onto
    an opaque white background before export.
  * The artwork is centred with a small safety margin so iOS corner rounding
    never clips it.

Usage:
    python tools/ios_icons.py
"""

from pathlib import Path

from PIL import Image

# جذر المشروع = مجلد أعلى مجلد الأدوات مباشرةً
# Project root = the folder directly above this tools/ directory.
PROJECT_ROOT = Path(__file__).resolve().parent.parent

SOURCE_LOGO = PROJECT_ROOT / "assets" / "logo1.png"
ICON_DIR = PROJECT_ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"

# لون الخلفية المعتم (أبيض) — مطابق لأيقونة Android الحالية ic_launcher.png
# Opaque background colour (white) — matches the current Android ic_launcher.png.
BACKGROUND_COLOR = (255, 255, 255)

# نسبة الحشوة حول الشعار من كل جهة: 8% تُبقي الشكل كاملاً تحت تقريب iOS الزوايا.
# Margin around the artwork per side: 8% keeps it whole under iOS corner rounding.
MARGIN_RATIO = 0.08

# أسماء الملفات ومقاسها بالبكسل — مطابقة تماماً لـ Contents.json القائم (لا يُعدَّل).
# File names and pixel sizes — exactly matching the existing Contents.json (untouched).
ICON_SIZES = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}


def build_master(size: int = 1024) -> Image.Image:
    """يبني صورة رئيسية مربّعة معتمة بجودة عالية ثم تُصغَّر لكل مقاس.

    Builds one opaque square master image that every size is downscaled from,
    so all icons share the exact same geometry.
    """
    logo = Image.open(SOURCE_LOGO).convert("RGBA")

    # قصّ الهوامش الشفافة حول الشعار قبل القياس، وإلا اختلّت النسب.
    # Trim the transparent padding first, otherwise the scale would be off.
    bbox = logo.getbbox()
    if bbox:
        logo = logo.crop(bbox)

    # المربّع الأكبر ليحتوي الشعار + الحشوة من الجهتين.
    # The square must hold the artwork plus the margin on both sides.
    inner = int(size * (1 - 2 * MARGIN_RATIO))
    width, height = logo.size
    scale = min(inner / width, inner / height)
    logo = logo.resize(
        (max(1, round(width * scale)), max(1, round(height * scale))),
        Image.LANCZOS,
    )

    canvas = Image.new("RGBA", (size, size), BACKGROUND_COLOR + (255,))
    canvas.alpha_composite(
        logo,
        ((size - logo.width) // 2, (size - logo.height) // 2),
    )

    # التحويل إلى RGB يحذف قناة alpha نهائياً — شرط قبول أيقونة iOS.
    # Dropping to RGB removes the alpha channel entirely — required by iOS.
    return canvas.convert("RGB")


def main() -> None:
    if not SOURCE_LOGO.exists():
        raise SystemExit(f"الشعار غير موجود / Logo not found: {SOURCE_LOGO}")
    if not ICON_DIR.is_dir():
        raise SystemExit(f"مجلد الأيقونات غير موجود / Icon folder not found: {ICON_DIR}")

    master = build_master()
    for filename, size in ICON_SIZES.items():
        icon = master if size == master.width else master.resize((size, size), Image.LANCZOS)
        target = ICON_DIR / filename
        icon.save(target, format="PNG", optimize=True)
        print(f"{filename:<30} {size}x{size}")

    print(f"\nتم توليد {len(ICON_SIZES)} أيقونة في {ICON_DIR}")
    print(f"Generated {len(ICON_SIZES)} icons in {ICON_DIR}")


if __name__ == "__main__":
    main()
