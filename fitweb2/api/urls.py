from django.urls import include, path
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    AdminAdminsView,
    AdminSummaryView,
    BookingViewSet,
    HomeSummaryView,
    IdentifierTokenObtainPairView,
    MeView,
    PlaceReviewViewSet,
    PlaceViewSet,
    RegisterView,
    SessionSlotViewSet,
    TrainerReviewViewSet,
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
router.register("trainer-reviews", TrainerReviewViewSet, basename="trainer-reviews")

urlpatterns = [
    path("auth/register/", RegisterView.as_view(), name="api-register"),
    path("auth/token/", IdentifierTokenObtainPairView.as_view(), name="api-token"),
    path("auth/token/refresh/", TokenRefreshView.as_view(), name="api-token-refresh"),
    path("auth/me/", MeView.as_view(), name="api-me"),
    path("home/", HomeSummaryView.as_view(), name="api-home"),
    path("admin/summary/", AdminSummaryView.as_view(), name="api-admin-summary"),
    path("admin/admins/", AdminAdminsView.as_view(), name="api-admin-admins"),
    path("", include(router.urls)),
]
