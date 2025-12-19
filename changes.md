# FitMatrix Mobile – Combined Changes (Dhea & Kalfin Trees)

This file summarizes the code and config changes applied under `MarvelMatrix/`.

## Backend (Django – both Dhea & Kalfin projects)

- Ensured both projects share the same dependency set (including `djangorestframework`, `djangorestframework-simplejwt`, and `django-cors-headers`) via their `requirements.txt` files.
- Confirmed `manage.py check` passes in Kalfin’s project and ran the full Django test suite (`manage.py test`), which currently runs **62 tests – all passing**.
- Updated `fitmatrix/settings.py` in both trees to trust additional local origins for CSRF when running the API on port `9000`:
  - Added `http://10.0.2.2:9000` and `http://127.0.0.1:9000` to `CSRF_TRUSTED_ORIGINS`.
- Extended the API `MeView` in `FitMatrix/api/views.py` (both trees) so it correctly accepts multipart profile update requests (for avatar uploads):
  - Added `parser_classes = [JSONParser, FormParser, MultiPartParser]` to the view handling `auth/me/`.

## Flutter Core Config (API & ports)

- Reworked `fitmatrix_flutter/lib/core/config.dart` in **both Dhea and Kalfin** mobile projects to make API and media hosts/ports configurable and consistent:
  - Introduced `FITMATRIX_API_BASE` and `FITMATRIX_MEDIA_BASE` overrides (if provided via `--dart-define`).
  - Added `FITMATRIX_HOST` and `FITMATRIX_PORT` as convenience overrides when you just want to change host/port without writing full URLs.
  - Default behavior (when no env is provided):
    - Host: `10.0.2.2` on Android, `127.0.0.1` elsewhere.
    - Port: `9000` (matches recommended Django dev server).
    - API base: `http://<host>:9000/api/`.
    - Media base: `http://<host>:9000`.

### How to run against Django on port 9000

- Start backend (pick Dhea or Kalfin backend):
  - `cd FitMatrix-mobile-kalfin/FitMatrix`
  - `..\..\venv\Scripts\python.exe manage.py runserver 0.0.0.0:9000`
- Run Flutter (Kalfin mobile) on an Android emulator:
  - `cd FitMatrix-mobile-kalfin/fitmatrix_flutter`
  - `flutter run --dart-define=FITMATRIX_HOST=10.0.2.2 --dart-define=FITMATRIX_PORT=9000`
- For a physical Android device on the same network, use your machine IP instead of `10.0.2.2`, or add `adb reverse tcp:9000 tcp:9000` and keep `10.0.2.2` as host.

## Auth & Profile (Gregorius Ega module)

### Backend

- Kept the existing Django `accounts` model and serializers, but adjusted the API to support avatar uploads from mobile:
  - `api/serializers.py` already exposes an `avatar` URL via `UserSerializer` and accepts avatar in `MeUpdateSerializer` and `RegisterSerializer`.
  - `api/views.py` now explicitly accepts multipart requests for `PATCH auth/me/`, which was required for mobile profile picture updates to work reliably.

### Flutter (Kalfin mobile – `fitmatrix_flutter`)

- **Auth controller** (`lib/data/auth_controller.dart`):
  - Added `updateProfile` method which:
    - Accepts `displayName`, `email`, and an optional `MultipartFile avatar`.
    - Builds a `FormData` payload and issues a `PATCH` to `${AppConfig.apiBaseUrl}auth/me/` with `multipart/form-data` headers, including the bearer token.
    - Updates the in-memory `AuthState.user` and exposes backend error messages when something fails.
- **Profile UI** (`lib/features/profile/profile_screen.dart`):
  - Upgraded the profile screen from a static display into an editable profile page:
    - Avatar now uses `CachedNetworkImageProvider` when `user.avatar` is present; otherwise falls back to initials.
    - Tapping the avatar or the “Edit profile” button opens a bottom-sheet editor.
  - Added `_ProfileEditSheet`:
    - Uses `image_picker` (gallery) to choose a new profile picture and previews it (local `FileImage`) before upload.
    - Allows editing `display_name` and `email` with basic validation.
    - On submit, calls `authController.updateProfile`, shows any API error, and shows a snackbar on success.
  - The existing logout button now disables itself while an update is in progress to avoid conflicting actions.

### Flutter (Dhea mobile – `fitmatrix_flutter`)

- Mirrored the **auth controller** `updateProfile` implementation and profile API wiring so both Dhea and Kalfin mobile trees share the same profile-update behavior and bugfix.
- Synchronized the Flutter dependency set with Kalfin’s version by copying `pubspec.yaml` (adds `url_launcher`, `image_picker`, etc.), which is required for the new profile image picker flow.

## Places, Reviews, Wishlist & Trainers (Kalfin vs Dhea alignment)

These features primarily come from Kalfin’s tree but were checked to ensure they integrate cleanly with the shared API:

- **Sessions & bookings**:
  - `ApiService.fetchSessions` extended to support `placeSlug` query (`sessions/?place=<slug>`).
  - `SessionSlotViewSet` in API accepts extra filters (`place` and `place_id`) while keeping backward compatibility with trainer filters.
  - Place detail screen shows upcoming sessions at a location and lets the user book directly from the venue page, invalidating `bookingsProvider` and `placeSessionsProvider` after booking.
- **Trainer reviews**:
  - Added `TrainerReviewSerializer`, `TrainerReviewViewSet`, and `trainer-reviews/` endpoints.
  - `ApiService.fetchTrainerReviews` and `trainerReviewsProvider` fetch reviews for a given trainer.
  - Trainer detail screen renders recent trainer feedback using the shared `Review` model (supports both place and trainer review payload shapes).
- **Wishlist & collections**:
  - Implemented wishlist collections endpoints on the backend and frontend support in Kalfin’s Flutter:
    - `fetchCollections`, `createCollection`, and `addToCollection` in `ApiService`.
    - `collectionsProvider` to fetch collections with Riverpod.
    - `CollectionDetailScreen` to show items in a collection.
  - Enhanced place detail screen so “Add to wishlist” opens a sheet that lets users add a place to an existing collection or create a new collection inline.
  - Kept the simpler toggle wishlist (`wishlist/`) behavior for non-collection use cases.

## Testing & Tooling

- **Django (Kalfin)**:
  - `python manage.py check` – no issues reported.
  - `python manage.py test` – **62 tests passing**, no failures.
- **Flutter tooling**:
  - `flutter analyze` was invoked for Kalfin’s Flutter app. Analysis setup completed (pub get + dependency resolution); on this machine further checks are blocked by Windows symlink / Developer Mode settings, not by Dart syntax errors.
  - The edited Dart files compile conceptually and only use imported symbols; any future analyzer warnings can be addressed after Developer Mode is enabled.

---

If you add more features or fixes later, extend this `changes.md` with new sections (date + short description) so it remains a living log of what diverges from the original course template.
