from __future__ import annotations

import ipaddress
import mimetypes
from pathlib import Path
from urllib.parse import urlparse

from django.conf import settings
from django.contrib.staticfiles import finders
from django.http import FileResponse
from django.http import HttpResponse, JsonResponse, StreamingHttpResponse
from django.shortcuts import get_object_or_404, redirect, render
from django.views.decorators.http import require_GET

import requests

from reviews.models import Review

from .models import Place

# Halaman daftar tempat
def place_list(request):
    places = Place.objects.all()
    return render(request, "places/list.html", {"places": places})

# Halaman detail tempat
def place_detail(request, slug):
    place = get_object_or_404(Place, slug=slug)
    reviews = Review.objects.filter(place=place).order_by("-created_at")
    return render(request, "places/detail.html", {"place": place, "reviews": reviews})


@require_GET
def reviews_partial(request, slug):
    place = get_object_or_404(Place, slug=slug)
    reviews = Review.objects.filter(place=place).order_by("-created_at")
    return render(request, "places/_reviews.html", {"place": place, "reviews": reviews})


def place_review_create(request, slug):
    if request.method != "POST":
        return JsonResponse(
            {"success": False, "error": "Invalid request method."},
            status=400,
        )

    place = get_object_or_404(Place, slug=slug)
    ajax = request.headers.get("x-requested-with") == "XMLHttpRequest"

    if not request.user.is_authenticated:
        return JsonResponse(
            {"success": False, "error": "You must be logged in."},
            status=403,
        )

    body = (request.POST.get("body") or "").strip()
    rating_raw = (request.POST.get("rating") or "").strip()

    if not body or not rating_raw:
        if ajax:
            return JsonResponse(
                {"success": False, "error": "Please fill in all fields."},
                status=400,
            )
        return redirect("places:detail", slug=place.slug)

    try:
        rating = int(rating_raw)
    except (TypeError, ValueError):
        return JsonResponse(
            {"success": False, "error": "Invalid rating value."},
            status=400,
        )

    if rating < 1 or rating > 5:
        return JsonResponse(
            {"success": False, "error": "Invalid rating value."},
            status=400,
        )

    Review.objects.create(place=place, user=request.user, rating=rating, body=body)
    if ajax:
        return JsonResponse({"success": True})
    return redirect("places:detail", slug=place.slug)


@require_GET
def proxy_image(request):
    image_url = (request.GET.get("url") or "").strip()
    if not image_url:
        return HttpResponse("No URL provided", status=400)

    if image_url.startswith("/"):
        image_url = request.build_absolute_uri(image_url)

    parsed = urlparse(image_url)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        return HttpResponse("Invalid URL", status=400)

    hostname = (parsed.hostname or "").lower()
    request_host = (request.get_host() or "").split(":", 1)[0].lower()

    # Avoid proxying back into ourselves (can deadlock under limited workers).
    if hostname == request_host:
        if parsed.path.startswith(settings.STATIC_URL):
            relative_path = parsed.path[len(settings.STATIC_URL) :].lstrip("/")
            disk_path = finders.find(relative_path)
            if not disk_path:
                return HttpResponse("Not found", status=404)
            return _serve_local_file(disk_path)

        if parsed.path.startswith(settings.MEDIA_URL):
            relative_path = parsed.path[len(settings.MEDIA_URL) :].lstrip("/")
            disk_path = Path(settings.MEDIA_ROOT) / relative_path
            if not disk_path.exists():
                return HttpResponse("Not found", status=404)
            return _serve_local_file(disk_path)

        return HttpResponse("Blocked host", status=400)

    if hostname in {"localhost"}:
        return HttpResponse("Blocked host", status=400)

    try:
        ip = ipaddress.ip_address(hostname)
        if ip.is_private or ip.is_loopback or ip.is_link_local:
            return HttpResponse("Blocked host", status=400)
    except ValueError:
        # hostname is not an IP address
        pass

    try:
        upstream = requests.get(
            image_url,
            stream=True,
            timeout=(3, 10),
            headers={
                "User-Agent": "FitMatrixImageProxy/1.0",
                "Accept": "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
            },
        )
    except requests.RequestException as exc:
        return HttpResponse(f"Error fetching image: {exc}", status=502)

    if upstream.status_code >= 400:
        status_code = upstream.status_code
        upstream.close()
        return HttpResponse(f"Upstream returned {status_code}", status=status_code)

    content_type = upstream.headers.get("Content-Type") or "image/jpeg"

    def stream():
        try:
            for chunk in upstream.iter_content(chunk_size=64 * 1024):
                if chunk:
                    yield chunk
        finally:
            upstream.close()

    response = StreamingHttpResponse(stream(), content_type=content_type)
    response["Access-Control-Allow-Origin"] = "*"
    response["Cache-Control"] = "public, max-age=86400"
    response["Cross-Origin-Resource-Policy"] = "cross-origin"
    return response


def _serve_local_file(path: str | Path) -> FileResponse:
    file_path = Path(path)
    content_type, _ = mimetypes.guess_type(str(file_path))
    response = FileResponse(
        file_path.open("rb"),
        content_type=content_type or "application/octet-stream",
    )
    response["Access-Control-Allow-Origin"] = "*"
    response["Cache-Control"] = "public, max-age=86400"
    response["Cross-Origin-Resource-Policy"] = "cross-origin"
    return response
