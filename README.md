# README.md TK PBP C11

# Daftar Anggota Kelompok TK-PBP C11
- Dhea Anggrayningsih Syah Rony 2406437262 - Modul Review
- Gregorius Ega Aditama Sudjali 2406434153 - Modul Authentication
- kanayra maritza sanika adeeva 2406437880 - Modul Wishlist
- Kalfin Jefwin Setiawan Gultom 2406360256 - Modul Trainer Booking
- Fadhil Daffa Putra Irawan 2406438271 - Modul Places
- Marvel Irawan 2406421346 - Modul Search

## Deskripsi Aplikasi 📱
🏋️‍♂️ FitMatrix adalah aplikasi yang membantu masyarakat dalam menemukan rekomendasi tempat olahraga di wilayah Jabodetabek, baik yang berbayar maupun gratis. Aplikasi ini memungkinkan pengguna untuk menyimpan tempat olahraga favorit sesuai dengan preferensi mereka ke dalam fitur wishlist, serta memberikan ulasan setelah merasakan pengalaman berolahraga secara langsung di tempat tersebut. Selain itu, FitMatrix juga membantu pengguna dalam menemukan rekomendasi personal trainer atau coach dan mem-_booking_ pemesanan sesi latihan bersama mereka.

## 👥 Peran atau aktor pengguna aplikasi
1. _User_
Ditargetkan untuk sebagian besar sport enthusiast yang membutuhkan referensi tempat olahraga yang bervariasi, baik berbayar maupun gratis serta mencari pelatih sesuai cabang olahraga yang mereka sukai. Pengguna dapat memanfaaatkan berbagai fitur yang tersedia di aplikasi, antara lain:
- 🎯 Filter berdasarkan cabang olahraga
- 📍 Filter berdasarkan lokasi
- ⭐ Menyimpan tempat olahraga ke wishlist
- 👍 Melakukan review tempat olahraga
- 🤝 Melakukan booking sesi latihan bersama _personal trainer/ coach_

2. Admin
Bertugas mengelola data yang terdapat pada aplikasi, meliputi:
- ⭐ Melihat seluruh _booking_ sesi olahraga bersama _trainer_ yang dibuat oleh user.
- 🏟️ Melihat seluruh tempat yang terdaftar dari seed_demo.  
- ➕ Menambah lokasi _spot_ olahraga serta_ personal trainer/coach_
- ✏️ Mengedit, menonaktifkan, dan menghapus data _spot_ olahraga serta _trainer_.
- ❌ Membatalkan _appointment_ _personal trainer_ atau _coach_ yang sudah dipesan user.

## Daftar modul yang diimplementasikan beserta pembagian kerja per anggota 🗂️
## 👥 Modul Autentikasi dan Profil Pengguna -> Dikerjakan oleh Gregorius Ega
-> Modul ini mengelola registrasi, _login_, dan profil pengguna. Pengguna yang sudah _login_ dapat mengelola data pribadi mereka serta mengakses fitur-fitur lain seperti menambah tempat ke _wishlist_ dan memberikan _review_. 

Fitur Utama:
- Registrasi, _login_, dan pengelolaan akun.
- Mengelola profil pengguna (_username_, foto profil, _password_)
- Menyimpan riwayat aktivitas _booking apppointment_ dengan PT/ trainer.


## 🔍 Modul Pencarian -> Dikerjakan oleh Marvel Irawan
Fitur Utama:
- Pencarian tempat dan personal/trainer berdasarkan nama atau kata kunci.
- Filter tempat berdasarkan jenis olahraga, lokasi, dan harga (berbayar atau gratis).


## 🏟️ Modul _Places_ -> Dikerjakan oleh Fadhil Daffa
-> Mengelola data tempat olahraga dan menampilkan rincian informasi tempat seperti fasilitas, deskripsi, lokasi, dan mengintegrasikannya dengan google maps. 

Fitur Utama:
- Menyimpan data tempat olahraga (lokasi, fasilitas, deskripsi, harga jika berbayar).
- Menyediakan peta lokasi melalui Google Maps untuk masing-masing tempat olahraga.
- Menampilkan tempat olahraga yang paling populer pada halaman _home_ bagian _Trending Coordinates_.


## ⭐ Modul _Wishlist_ -> Dikerjakan oleh Kanayra Maritza
-> Mengizinkan pengguna untuk menyimpan tempat olahraga favorit mereka agar dapat dengan mudah diakses di kemudian hari. 

Fitur Utama:
- Menyimpan tempat pada _card wishlist_ yang dimana _card_ tersebut bisa diberikan keterangan sesuai preferensi mereka.
- Meremove daftar tempat yang telah disimpan di_ card wishlist_.

  
## 👍 Modul _Review_ -> Dikerjakan oleh Dhea Anggrayningsih
-> Pengguna yang sudah memiliki akun dan sedang _login_ dapat memberikan _rating_ dan _review_ pada tempat olahraga yang mereka kunjungi untuk membantu pengguna lain dalam memilih tempat terbaik.  

Fitur Utama:
- Memberikan rating (1-5) dan komentar untuk tempat olahraga.
- Menampilkan review dan rating dari pengguna lain.


# 🏋️‍♂️Modul _Booking Trainer_ -> Dikerjakan oleh Kalfin Jefwin
-> Memungkinkan pengguna untuk melihat daftar _trainer_ yang tersedia di suatu tempat olahraga yang terdaftar, beserta spesialisasi masing-masing, serta melakukan pemesanan sesi olahraga dengan _trainer_ tersebut.

Fitur utama: 
- Memungkinkan pengguna untuk melihat daftar trainer beserta spesialisasi, jadwal tersedia, dan harga per sesi.
- Membuat, mengubah, atau membatalkan sesi olahraga bersama _trainer_.


#  🧩 Integrasi dengan Situs Web 
- Mengimplementasikan sebuah wrapper class dengan menggunakan library http dan map untuk mendukung penggunaan cookie-based authentication pada aplikasi.
- Mengimplementasikan REST API pada Django (views.py) dengan menggunakan JsonResponse atau Django JSON Serializer.
- Mengimplementasikan desain front-end untuk aplikasi berdasarkan desain website yang sudah ada sebelumnya.
- Melakukan integrasi antara front-end dengan back-end dengan menggunakan konsep asynchronous HTTP.

# 🎨 Link Figma: 
https://www.figma.com/design/nkK1yFNK66zuQtAnYOGL51/PBP-C11-Mobile-Design?node-id=0-1&t=M48Aoct9gydR8JfQ-1


# 🗃️ Initial dataset: 
https://huggingface.co/datasets/Shiowo2/Initial-Data-FitMatrix
https://commons.wikimedia.org/w/index.php?search=lapangan+indonesia&title=Special%3AMediaSearch&type=image WikiMedia, keyword: lapangan Indonesia
https://commons.wikimedia.org/w/index.php?search=headshot&title=Special%3AMediaSearch&type=image WikiMedia, keyword: headshot (profile trainer)