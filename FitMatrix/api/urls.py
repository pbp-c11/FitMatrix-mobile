from django.urls import include, path
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    BookingViewSet,
    HomeSummaryView,
    IdentifierTokenObtainPairView,
    MeView,
    PlaceReviewViewSet,
    PlaceViewSet,
    RegisterView,
    SessionSlotViewSet,
    TrainerViewSet,
    WishlistCollectionViewSet,
    WishlistViewSet,
)

router = DefaultRouter()
router.register("places", PlaceViewSet, basename="places")
router.register("trainers", TrainerViewSet, basename="trainers")
router.register("sessions", SessionSlotViewSet, basename="sessions")
router.register("bookings", BookingViewSet, basename="bookings")
router.register("wishlist", WishlistViewSet, basename="wishlist")
router.register("collections", WishlistCollectionViewSet, basename="collections")
router.register("place-reviews", PlaceReviewViewSet, basename="place-reviews")

urlpatterns = [
    path("auth/register/", RegisterView.as_view(), name="api-register"),
    path("auth/token/", IdentifierTokenObtainPairView.as_view(), name="api-token"),
    path("auth/token/refresh/", TokenRefreshView.as_view(), name="api-token-refresh"),
    path("auth/me/", MeView.as_view(), name="api-me"),
    path("home/", HomeSummaryView.as_view(), name="api-home"),
    path("", include(router.urls)),
]
