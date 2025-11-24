# README.md TK PBP C11

# Daftar Anggota Kelompok TK-PBP C11
- Dhea Anggrayningsih Syah Rony 2406437262 - Modul Review
- Gregorius Ega Aditama Sudjali 2406434153 - Modul Authentication
- kanayra maritza sanika adeeva 2406437880 - Modul Wishlist
- Kalfin Jefwin Setiawan Gultom 2406360256 - Modul Trainer Booking
- Fadhil Daffa Putra Irawan 2406438271 - Modul Places
- Marvel Irawan 2406421346 - Modul Search

## Deskripsi Aplikasi 📱
🏋️‍♂️ FitMatrix adalah aplikasi yang membantu khalayak untuk menemukan rekomendasi tempat olahraga 🏟️ di wilayah Jabodetabek, baik yang berbayar maupun gratis dan memungkinkan mereka untuk menyimpan tempat favorit sesuai preferensi mereka dari rekomendasi
yang ada ke dalam wishlist serta memberi review setelah merasakan pengalaman berolahraga langsung di tempat. Selain itu, FitMatrix juga membantu user untuk menemukan rekomendasi personal trainer/ coach dan membooking sesi bersama mereka.

👥 Jenis Pengguna
1. User(biasa) – ditargetkan pada sebagian besar Sport Enthusiast.
User ini ditargetkan pada sebagian besar Sport Enthusiast yang butuh referensi tempat yang bervariasi, baik yang berbayar maupun gratis. Mereka bisa memanfaatkan fitur-fitur di aplikasi kami:
- 🎯 Filter berdasarkan cabang olahraga
- 📍 Filter berdasarkan lokasi
- ⭐ Menyimpan tempat olahraga ke wishlist
- 👍 Melakukan review tempat olahraga
- 🔥 Mendapatkan rekomendsi Trending Coordinates
- 🤝 Melakukan booking appointment Personal trainer/Coach

2. Admin -  bertugas mengelola data di aplikasi:
- ➕ Menambah lokasi spot olahraga & personal trainer/coach di Jabodetabek
- ✏️ Mengedit dan menghapus data spot olahraga & trainer
- ❌ Cancel appointment PT/Coach

## Daftar Modul 🗂️
# 👥 Auth & Profile (Modul Autentikasi dan Profil Pengguna)
-> Modul ini mengelola registrasi, login, dan profil pengguna. Pengguna yang sudah login dapat mengelola data pribadi mereka, serta mengakses fitur-fitur lain seperti add tempat ke wishlist dan memberikan review suatu tempat.

Fitur Utama:
- Registrasi, login, dan pengelolaan akun.
- Mengelola profile pengguna (nama, foto profile, password)
- Menyimpan riwayat aktivitas booking apppointment dengan PT/ trainer (baik appointment ongoing maupun yang sudah selesai).

Integrasi -> Terkoneksi dengan modul Wishlist, Review, dan Appointment.


# 🔍 Search (Modul Pencarian)
-> Memudahkan pengguna mencari tempat olahraga berdasarkan kata kunci dan filter.

Fitur Utama:
- Pencarian berdasarkan kata kunci.
- Filter berdasarkan olahraga, lokasi, dan harga (berbayar atau gratis).
- Menyortir hasil pencarian berdasarkan likes terbanyak.
  
Integrasi: Terkoneksi dengan modul Place dan Hot Deals.



# 🏟️ Place (Modul Tempat Olahraga)
-> Mengelola data tempat olahraga dan menampilkan rincian informasi tempat seperti fasilitas, deskripsi, lokasi, dan mengintegrasikannya dengan google maps.

Fitur Utama:
- Menyimpan data tempat olahraga (lokasi, fasilitas, deskripsi, harga jika berbayar).
- Menyediakan peta lokasi google maps.
- Menampilkan tempat olahraga yang paling populer berdasarkan rating rata-rata.
- Tempat dengan rating tertinggi akan ditampilkan sebagai Trending Coordinates.

Integrasi: Terkoneksi dengan Search, Wishlist, dan Review, Place, Search, dan Hot Deals.



# ⭐ Wishlist (Modul Daftar Favorit)
-> Mengizinkan pengguna untuk menyimpan tempat olahraga favorit mereka agar dapat dengan mudah diakses di kemudian hari.

Fitur Utama:
- Menyimpan tempat pada card wishlist yang dimana card tersebut bisa diberikan keterangan sesuai preferensi mereka.
- Meremove daftar tempat yang telah disimpan oleh di card wishlist.
  
Integrasi: Terkoneksi dengan Place dan Auth & Profile.


# 👍 Review (Modul Ulasan dan Rating)
-> Pengguna dapat memberikan rating dan review pada tempat olahraga yang mereka kunjungi untuk membantu pengguna lain dalam memilih tempat terbaik namun dengan
syarat pengguna tersebut harus sudah login. 

Fitur Utama:
- Memberikan rating (1-5) dan komentar untuk tempat olahraga.
- Menampilkan review dan rating dari pengguna lain.
- Dapat mengelola review yang tidak sesuai (role admin)

Integrasi: Terkoneksi dengan Place dan Auth & Profile.



# 🏋️‍♂️Trainer Booking (Modul Pemesanan Trainer)
-> Memungkinkan pengguna untuk melihat daftar trainer yang available di suatu tempat beserta specialities mereka dan melakukan booking sesi olahraga dengan mereka.
Pengguna juga bisa melihat trainer yang available di jam tertentu. 

Fitur utama: 
- Melihat daftar trainer beserta spesialisasi, rating, dan jadwal tersedia.
- Memilih tanggal, jam, durasi, dan jenis latihan untuk sesi training.
- Membuat, mengubah, atau membatalkan booking sesi mereka sendiri.
- Memberikan review dan rating untuk trainer setelah sesi selesai.
- Melihat seluruh booking yang dibuat oleh user (admin)
- Mengatur jadwal trainer (menambah slot baru, mengubah atau menonaktifkan slot) (admin)
- Membatalkan booking jika ada konflik atau masalah.
- Memantau dan mengelola review yang diberikan user.

Integrasi Terkoneksi dengan Auth & Profile, Review, Place, dan Search


# 🎨 Link Figma: 
https://www.figma.com/design/vXSH1mwzy0O4ozmXNNKxCT/FitMatrix?node-id=0-1&t=0LneyTAaBzi1ylCE-1
password: olahega

# 🌐 Link deployment PWS:
https://fadhil-daffa-fitmatrix.pbp.cs.ui.ac.id/

# 🗃️ Initial dataset: 
https://huggingface.co/datasets/Shiowo2/Initial-Data-FitMatrix
https://commons.wikimedia.org/w/index.php?search=lapangan+indonesia&title=Special%3AMediaSearch&type=image WikiMedia, keyword: lapangan Indonesia
https://commons.wikimedia.org/w/index.php?search=headshot&title=Special%3AMediaSearch&type=image WikiMedia, keyword: headshot (profile trainer)
