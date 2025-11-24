from __future__ import annotations

from django.contrib.auth.decorators import login_required
from django.core.paginator import Paginator
from django.http import HttpRequest, HttpResponse, JsonResponse
from django.shortcuts import get_object_or_404, render
from django.views.decorators.http import require_GET, require_POST

from accounts.models import ActivityLog, WishlistItem
from places.models import Place
from scheduling.models import Trainer


@login_required
@require_GET
def list_view(request: HttpRequest) -> HttpResponse:
    items = (
        WishlistItem.objects.filter(user=request.user)
        .select_related("place", "trainer")
        .order_by("-created_at")
    )
    page_obj = Paginator(items, 12).get_page(request.GET.get("page"))
    return render(request, "wishlist/list.html", {"page_obj": page_obj})


@login_required
@require_POST
def toggle_view(request: HttpRequest, kind: str, pk: int) -> HttpResponse:
    if kind not in {"place", "trainer"}:
        return JsonResponse({"error": "Invalid kind"}, status=400)

    model = Place if kind == "place" else Trainer
    target = get_object_or_404(model, pk=pk)

    filters: dict[str, object] = {"user": request.user}
    if kind == "place":
        filters["place"] = target
    else:
        filters["trainer"] = target

    item = WishlistItem.objects.filter(**filters).first()
    if item:
        item.delete()
        ActivityLog.objects.create(
            user=request.user,
            type=ActivityLog.Types.WISHLIST_REMOVED,
            meta={"kind": kind, "id": pk},
        )
        state = "removed"
    else:
        item = WishlistItem(user=request.user)
        if kind == "place":
            item.place = target
        else:
            item.trainer = target
        item.save()
        ActivityLog.objects.create(
            user=request.user,
            type=ActivityLog.Types.WISHLIST_ADDED,
            meta={"kind": kind, "id": pk},
        )
        state = "added"

    return JsonResponse({"status": state})
