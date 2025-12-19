from __future__ import annotations

from .Image import ImageFile


def exif_transpose(image: ImageFile) -> ImageFile:  # pragma: no cover - compatibility shim
    return image
