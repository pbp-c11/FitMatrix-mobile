# FitMatrix API (Flutter bridge)

Base URL (dev): `http://127.0.0.1:8000/api/`  
Auth: JWT (Bearer) via `auth/token/` and `auth/token/refresh/`. Supply `identifier` (username or email) + `password`.

## Auth
- `POST auth/register/` — body: `username`, `email`, `password`, optional `display_name`, `avatar`. Returns user.
- `POST auth/token/` — body: `identifier` (or `username`), `password`. Returns `access`, `refresh`.
- `POST auth/token/refresh/` — body: `refresh`.
- `GET auth/me/` — current user profile.  
- `PATCH auth/me/` — update `display_name`, `email`, optional `avatar`.

## Home
- `GET home/` — summary counts + spotlight, newest, trending places.

## Places
- `GET places/` — query: `q`, `city`, `type`, `price`, `amenities` (multi), `sort` (`newest|rating`). Returns active places (admin sees all).
- `GET places/{slug}/` — place detail.
- `POST places/` (admin) — create place (fields: name, tagline, summary, address, city, latitude, longitude, facility_type, amenities[list], highlight_score, accent_color, hero_image, gallery[list], is_free, price, rating_avg, likes, is_active).
- `PATCH places/{slug}/` (admin) — update fields.
- `POST places/{slug}/toggle_active/` (admin) — flip visibility.

## Trainers
- `GET trainers/` — query: `q`, `focus`. Includes `next_available`, `active_slots`.
- `GET trainers/{id}/` — trainer detail.
- `GET trainers/{id}/slots/` — upcoming slots for trainer.
- `POST trainers/`, `PATCH trainers/{id}/`, `POST trainers/{id}/toggle_active/` (admin) — manage trainers.

## Session slots
- `GET sessions/` — query: `q`, `trainer`; returns slots with trainer/place + `seats_left`.
- `POST sessions/` (admin) — fields: `trainer_id`, `place_id`, `start`, `end`, `capacity`, `is_active`.
- `PATCH sessions/{id}/` (admin) — update slot.

## Bookings
- `GET bookings/` — user bookings (admin sees all). Past bookings auto-marked `COMPLETED` when end time passed.
- `POST bookings/` — body: `slot_id` to book/re-activate.
- `POST bookings/{id}/cancel/` — cancel booking (user or admin).
- `POST bookings/{id}/reschedule/` — body: `slot` (new slot id).

## Wishlist
- `GET wishlist/` — list wishlist items with place/trainer info.
- `POST wishlist/` — body: `kind` (`place|trainer`), `target_id`; toggles and returns updated list + status.

## Collections
- `GET collections/` — list collections and items.
- `POST collections/` — body: `name`, optional `description`.
- `DELETE collections/{id}/` — delete collection.
- `POST collections/{id}/add_item/` — body: `place_id`.
- `POST collections/{id}/remove_item/` — body: `item_id`.

## Reviews
- `GET place-reviews/?place={slug}` — place reviews.
- `POST place-reviews/` — body: `place` (slug), `rating`, `body` (auth required).
- `GET trainer-reviews/?trainer={id}` — trainer reviews (only visible ones for non-admin).
- `POST trainer-reviews/` — body: `trainer`, `booking`, `rating`, `comment` (auth, booking owner, booking must be completed & unused).

### Notes
- All POST/PATCH requests use JSON unless uploading avatars (multipart).
- Admin-only endpoints require staff/admin credentials (`is_admin` role or staff).  
- Pagination defaults: 20 items/page via DRF page params (`?page=2`).
