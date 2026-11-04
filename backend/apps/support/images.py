"""Chat photos: checked, resized and saved again as JPEG.

Saving again drops the EXIF data, so a phone photo never leaks where it was taken.
"""

from io import BytesIO

from django.conf import settings
from django.core.files.base import ContentFile
from PIL import Image, ImageOps, UnidentifiedImageError

from apps.core.exceptions import ApiError
from apps.core.i18n import t

ALLOWED_FORMATS = {"JPEG", "PNG", "WEBP", "GIF", "MPO"}


def process_image(upload) -> ContentFile:
    max_bytes = settings.SUPPORT_IMAGE_MAX_MB * 1024 * 1024
    if upload.size > max_bytes:
        raise ApiError(
            t(
                f"الصورة أكبر من {settings.SUPPORT_IMAGE_MAX_MB} ميجا.",
                f"The photo is larger than {settings.SUPPORT_IMAGE_MAX_MB} MB.",
            ),
            code="image_too_large",
            field="image",
        )
    try:
        image = Image.open(upload)
        if image.format not in ALLOWED_FORMATS:
            raise UnidentifiedImageError(image.format)
        image.load()
    except (UnidentifiedImageError, OSError, Image.DecompressionBombError, ValueError):
        raise ApiError(
            t("ابعت صورة JPG أو PNG.", "Send a JPG or PNG photo."), code="invalid_image", field="image"
        ) from None

    image = ImageOps.exif_transpose(image)
    if image.mode in ("RGBA", "LA", "P"):
        image = image.convert("RGBA")
        background = Image.new("RGB", image.size, "white")
        background.paste(image, mask=image.getchannel("A"))
        image = background
    elif image.mode != "RGB":
        image = image.convert("RGB")
    side = settings.SUPPORT_IMAGE_MAX_SIDE
    image.thumbnail((side, side))

    out = BytesIO()
    image.save(out, "JPEG", quality=85, optimize=True)
    return ContentFile(out.getvalue(), name="photo.jpg")
