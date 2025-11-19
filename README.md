# README.md Kelompok C11

## Daftar nama anggota kelompok
Dhea Anggrayningsih Syah Rony 2406437262 - Modul `Review`
Gregorius Ega Aditama Sudjali 2406434153 - Modul `Auth & Profile`
kanayra maritza sanika adeeva 2406437880 - Modul `Wishlist`
Kalfin Jefwin Setiawan Gultom 2406360256 - Modul `Trainer Booking`
Fadhil Daffa Putra Irawan 2406438271 - Modul `Places`
Marvel Irawan 2406421346 - Modul `Search`

### Tautan APK (Tidak harus ada pada saat Tahap I. Tautan APK dapat ditambahkan secara menyusul ke README.md setelah selesai mengerjakan Tahap II.)

### Deskripsi aplikasi (nama dan fungsi aplikasi)
Nama Aplikasi : __`FitMatrix`__ Deskripsi Aplikasi: platform yang membantu pengguna menemukan rekomendasi tempat olahraga, baik yang berbayar maupun gratis 
(misalnya track lari, gym, atau lapangan olahraga)di wilayah Jabodetabek. Pengguna dapat memfilter tempat berdasarkan cabang olahraga dan lokasi, menyimpan tempat favorit ke wishlist, serta melihat tempat populer (Hot Places).
Tujuan aplikasi ini adalah mempermudah masyarakat untuk menemukan sarana olahraga sesuai kebutuhan dan preferensi mereka serta mencari dan melakukan appointment personal trainer/coach yang sesuai dengan kebutuhan user masing-masing di tempat-tempat yang berbeda.


# Daftar modul yang diimplementasikan beserta pembagian kerja per anggota

### 1. `Auth & Profile` (Modul Autentikasi dan Profil Pengguna)
Dikerjakan oleh Gregorius Ega Aditama Sudjali
Modul ini mengelola registrasi, login, dan profil pengguna. Pengguna dapat mengelola data pribadi mereka, serta mengakses fitur-fitur lain seperti wishlist dan review.
Fitur Utama:
*  Registrasi, login, dan pengelolaan akun.
*  Mengelola profile pengguna (nama, foto profile, password)
*   enyimpan riwayat aktivitas pengguna (seperti appointment saat itu, histori appointments, wishlist, rating).

Integrasi: Terkoneksi dengan modul `Wishlist`, `Review`, dan `Appointment`.

### 2. `Search` (Modul Pencarian) 
Dikerjakan oleh Marvel Irawan
Menyediakan fitur pencarian untuk menemukan tempat olahraga berdasarkan kategori olahraga, lokasi, berbayar/gratis.
Fitur Utama:
* Pencarian berdasarkan kata kunci.
* Filter berdasarkan olahraga, lokasi, dan harga (berbayar atau gratis).

Integrasi: Terkoneksi dengan modul `Place` dan `Hot Deals`.

### 3. `Place` (Modul Tempat Olahraga) Fungsi: Mengelola data tempat olahraga seperti gym, lapangan futsal, atau track lari, dan menampilkan rincian informasi tempat.
Dikerjakan oleh Fadhil Daffa

Fitur Utama:
* Menyimpan data tempat olahraga (lokasi, isFree(tempat ini berbayar atau gratis), fasilitas, deskripsi, harga jika berbayar).
* Menyediakan peta lokasi dan jam operasional (range waktu dari buka sampe tutup).
* Menampilkan tempat olahraga yang paling populer berdasarkan rating rata-rata.
* Tempat dengan rating tertinggi ditampilkan sebagai Hot Places.

Integrasi: Terkoneksi dengan `Search`, `Wishlist`, dan `Review`, `Place`, `Search`, dan `Hot Deals`.

### 4. `Wishlist` (Modul Daftar Favorit)  Mengizinkan pengguna untuk menyimpan tempat olahraga favorit mereka agar dapat dengan mudah diakses di kemudian hari.
Dikerjakan oleh Kanayra Maritza

Fitur Utama:
* Menyimpan dan menghapus tempat dari wishlist.
* Menampilkan daftar tempat yang telah disimpan oleh pengguna.

Integrasi: Terkoneksi dengan `Place` dan `Auth & Profile`.

### 5. `Review` (Modul Ulasan dan Rating) Pengguna dapat memberikan rating dan review pada tempat olahraga yang mereka kunjungi untuk membantu pengguna lain dalam memilih tempat terbaik.
Dikerjakan oleh Dhea Anggrayningsih

Fitur Utama:
* Memberikan rating (1-5) dan komentar untuk tempat olahraga.
* Menampilkan review dan rating dari pengguna lain.
* Admin dapat mengelola review yang tidak sesuai.

Integrasi: Terkoneksi dengan  `Place` dan `Auth & Profile`.

### 6. `Trainer Booking` (Modul Pemesanan Trainer)
Dikerjakan oleh Kalfin Jefwin
Fungsi: 
* Memungkinkan pengguna untuk melihat daftar trainer.
* Melakukan booking sesi olahraga, dan mengelola jadwal sesi.
* Admin dapat memonitor dan mengatur booking serta jadwal trainer.


# Peran atau aktor pengguna aplikasi
### Jenis pengguna:
`User` (biasa) – ditargetkan pada sebagian besar Sport Enthusiast. User ini adalah individu yang tertarik dengan aktivitas olahraga dan ingin menemukan tempat olahraga di sekitar wilayah mereka.
Mereka butuh referensi tempat yang bervariasi, baik yang berbayar maupun gratis, serta memanfaatkan fitur-fitur berikut untuk memilih lokasi olahraga yang sesuai dengan preferensi mereka, antara lain adalah:

### User biasa
* Filter berdasarkan cabang olahraga dan lokasi
* Menyimpan tempat favorit ke wishlist
* Memberikan review pada tempat olahraga
* Melihat tempat populer (Trending Coordinates)
* Melakukan appointment personal trainer/coach

### Admin
* Menambah daftar lokasi spot olahraga dan personal trainer/coach di Jabodetabek
* Bisa mengedit dan mendelete lokasi spot olahraga dan personal trainer/coach
* Cancel appointment PT/coach



* Penjelasan alur pengintegrasian data di aplikasi dengan aplikasi web (PWS) yang sudah dibuat saat Proyek Tengah Semester berbasis web service.
* Mengimplementasikan sebuah wrapper class dengan menggunakan library http dan map untuk mendukung penggunaan cookie-based authentication pada aplikasi.
* Mengimplementasikan REST API pada Django (views.py) dengan menggunakan JsonResponse atau Django JSON Serializer.
* Mengimplementasikan desain front-end untuk aplikasi berdasarkan desain website yang sudah ada sebelumnya.

⦁Melakukan integrasi antara front-end dengan back-end dengan menggunakan konsep asynchronous HTTP.



- Link Design Figma
https://www.figma.com/design/nkK1yFNK66zuQtAnYOGL51/PBP-C11-Mobile-Design?node-id=0-1&t=M48Aoct9gydR8JfQ-1
