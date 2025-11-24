from __future__ import annotations
from django.urls import path
from .views import (
    wishlist_page,
    DashboardPasswordChangeView,
    activity_history_view,
    add_to_collection_view,
    admin_booking_cancel,
    admin_bookings_list,
    admin_console_view,
    admin_place_create,
    admin_place_delete,
    admin_place_edit,
    admin_place_toggle,
    admin_places_list,
    admin_trainer_create,
    admin_trainer_edit,
    admin_trainer_toggle,
    admin_trainers_list,
    admin_review_toggle,
    admin_reviews_list,
    admin_slot_create,
    admin_slot_edit,
    admin_slot_toggle,
    admin_slots_list,
    admin_users_list,
    create_collection_view,
    delete_collection_view,
    delete_collection_item_view,
    get_user_collections,
    login_view,
    logout_view,
    profile_edit_view,
    profile_view,
    register_view,
    wishlist_collection_detail,
)

app_name = "accounts"

urlpatterns = [
    # Auth
    path("register/", register_view, name="register"),
    path("login/", login_view, name="login"),
    path("logout/", logout_view, name="logout"),

    # Profile
    path("profile/", profile_view, name="profile"),
    path("profile/edit/", profile_edit_view, name="profile-edit"),
    path("password/", DashboardPasswordChangeView.as_view(), name="password"),
    path("history/", activity_history_view, name="history"),

    # Admin
    path("admin/console/", admin_console_view, name="admin-console"),
    path("admin/users/", admin_users_list, name="admin-users"),
    path("admin/places/", admin_places_list, name="admin-places"),
    path("admin/places/new/", admin_place_create, name="admin-place-create"),
    path("admin/places/<int:pk>/edit/", admin_place_edit, name="admin-place-edit"),
    path("admin/places/<int:pk>/delete/", admin_place_delete, name="admin-place-delete"),
    path("admin/places/<int:pk>/toggle/", admin_place_toggle, name="admin-place-toggle"),
    path("admin/trainers/", admin_trainers_list, name="admin-trainers"),
    path("admin/trainers/new/", admin_trainer_create, name="admin-trainer-create"),
    path("admin/trainers/<int:pk>/edit/", admin_trainer_edit, name="admin-trainer-edit"),
    path("admin/trainers/<int:pk>/toggle/", admin_trainer_toggle, name="admin-trainer-toggle"),
    path("admin/slots/", admin_slots_list, name="admin-slots"),
    path("admin/slots/new/", admin_slot_create, name="admin-slot-create"),
    path("admin/slots/<int:pk>/edit/", admin_slot_edit, name="admin-slot-edit"),
    path("admin/slots/<int:pk>/toggle/", admin_slot_toggle, name="admin-slot-toggle"),
    path("admin/bookings/", admin_bookings_list, name="admin-bookings"),
    path("admin/bookings/<int:pk>/cancel/", admin_booking_cancel, name="admin-booking-cancel"),
    path("admin/reviews/", admin_reviews_list, name="admin-reviews"),
    path("admin/reviews/<int:pk>/toggle/", admin_review_toggle, name="admin-review-toggle"),

    # Wishlist & Collections
    path("wishlist/", wishlist_page, name="wishlist_page"),
    path("wishlist/collection/<int:pk>/", wishlist_collection_detail, name="wishlist_collection_detail"),

    # AJAX endpoints
    path("collections/create/", create_collection_view, name="create-collection"),
    path("collections/add/", add_to_collection_view, name="add-to-collection"),
    path("collections/list/", get_user_collections, name="get-user-collections"),
    path("collections/<int:pk>/delete/", delete_collection_view, name="delete_collection"),
    path("collections/items/<int:pk>/delete/", delete_collection_item_view, name="delete_collection_item"),
]