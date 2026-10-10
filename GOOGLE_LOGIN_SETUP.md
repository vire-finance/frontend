# Mengaktifkan Login Google di Vire (Android)

Kode frontend dan backend sudah terpasang. Client ID Web yang kamu berikan sudah diisi di backend. Pengujian langsung dengan akun Google perlu dilakukan dari aplikasi Android setelah dijalankan ulang.

## 1. Project dan layar izin

Buka https://console.cloud.google.com/, buat project bernama Vire, lalu pilih project tersebut.
Buka Google Auth Platform > Get started (atau APIs & Services > OAuth consent screen).
Isi nama aplikasi Vire, user support email, audience External, dan email kontak.
Jika menggunakan mode Testing, tambahkan email owner dan employee di Audience > Test users.

## 2. Client Android

Buka Clients > Create client > Android.

- Nama: Vire Android Debug
- Package name: `com.example.vire`
- SHA-1 debug laptop ini: `8D:15:14:36:21:B0:7B:89:46:6C:38:56:29:A1:C9:30:8E:26:38:49`

SHA-1 ini untuk build debug di laptop ini. Build release atau komputer lain bisa memakai SHA-1 berbeda.

## 3. Client Web

Di project yang sama, buat client dengan tipe Web application.
Nama: Vire Backend. Untuk alur login Android ini, Authorized JavaScript origins dan Redirect URIs boleh kosong.
Salin Client ID yang berakhiran `.apps.googleusercontent.com`. Client ID Web yang dipakai backend; Client ID Android tidak dimasukkan ke .env.

## 4. Konfigurasi backend

Buka `C:\Users\ASUS\Documents\Hilly\backend\.env`.
Client ID sudah diisi. Untuk mengubahnya di kemudian hari, gunakan baris:

```dotenv
GOOGLE_CLIENT_ID=CLIENT_ID_WEB_MILIKMU.apps.googleusercontent.com
```

Jika kirim Client ID Web ke chat, konfigurasi dapat dibantu. Client ID adalah identifier publik; Client Secret tidak diperlukan untuk alur ini.
Restart backend setelah mengubah .env. Dari folder backend:

```powershell
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

## 5. Menjalankan aplikasi

Plugin Google baru membutuhkan restart penuh. Hentikan flutter run sebelumnya dengan `q` atau Ctrl+C lalu jalankan `flutter run` dari folder frontend.
Pastikan emulator punya Google Play Services dan sudah login akun Google (Settings > Google atau Play Store).
Tekan Login with Google atau Register with Google, lalu pilih akun.

Akun baru akan masuk ke pilihan role Owner/Employee. Untuk employee, gunakan email terpisah dari owner dan invitation code owner. Akun owner lama tidak berubah menjadi employee ketika login Google.
Gmail terverifikasi dengan email yang sama dapat terhubung ke akun yang sudah ada tanpa mengubah password atau role. Untuk email pihak ketiga yang sudah terdaftar, penautan otomatis ditolak.

## Logout dan password

Logout melalui Profile > Logout tidak meminta current password. Salin invitation code owner sebelum logout jika hendak membuat employee.
Pemulihan password yang terlupa belum tersedia. Password lama tersimpan sebagai hash, sehingga tidak bisa ditampilkan kembali.

## Validasi

Build APK debug Android berhasil dan pemeriksaan kode frontend bersih. 14 tes backend lolos, termasuk tanda tangan token, expiry, audience, issuer, email terverifikasi, pembuatan akun, dan proteksi penautan akun. Login Google langsung dengan akun pengguna perlu diuji setelah OAuth di Google Cloud diaktifkan.

Panduan resmi:
- https://codelabs.developers.google.com/sign-in-with-google-android?hl=id
- https://pub.dev/packages/google_sign_in_android
- https://developers.google.com/identity/sign-in/web/backend-auth
