# tanamanku — n8n di laptop, diakses aman dari iPad

Setup untuk menjalankan **n8n di Docker** pada laptop Linux, lalu mengaksesnya
**dari mana saja** (termasuk iPad lewat data seluler) secara **aman** menggunakan
**Tailscale** — tanpa perlu membuka port di router.

## Kenapa Tailscale (bukan buka port router)?

- **Aman**: n8n tidak terbuka ke internet publik. Hanya perangkat di "tailnet"
  (jaringan privatmu) yang bisa mengakses.
- **Mudah**: tidak perlu port forwarding, IP statis, atau domain.
- **HTTPS otomatis**: lewat `tailscale serve` kamu dapat URL `https://...ts.net`.
  Ini penting karena **Safari di iPad** mewajibkan HTTPS agar login n8n
  (secure cookie) berfungsi.

```
 iPad (app Tailscale)  ──HTTPS──►  Tailscale Serve  ──http──►  n8n (127.0.0.1:5678)
        \________________ tailnet privat (terenkripsi) ________________/
```

## Yang dibutuhkan

- Laptop Linux dengan Docker + Docker Compose terpasang.
- Akun Tailscale (gratis untuk personal) — daftar di https://login.tailscale.com.
- iPad dengan app **Tailscale** dari App Store.

## Langkah-langkah

### 1. Siapkan Tailscale di laptop

```bash
chmod +x setup-tailscale.sh
./setup-tailscale.sh
```

Script ini akan:
1. Install Tailscale (jika belum ada).
2. Login (`tailscale up`) — buka link, login dengan akunmu.
3. Mengingatkan untuk mengaktifkan **MagicDNS** & **HTTPS** di
   [admin console → DNS](https://login.tailscale.com/admin/dns).
4. Menjalankan `tailscale serve --bg 5678` agar n8n tampil sebagai HTTPS.

Setelah selesai, cek nama host laptopmu di tailnet:

```bash
tailscale status
```

Cari baris milik laptop ini, namanya seperti `tanamanku.tailabcd.ts.net`.

### 2. Konfigurasi n8n

```bash
cp .env.example .env
```

Edit `.env`, ganti `N8N_HOST` dan `WEBHOOK_URL` dengan nama host dari langkah 1:

```env
N8N_HOST=tanamanku.tailabcd.ts.net
N8N_PROTOCOL=https
WEBHOOK_URL=https://tanamanku.tailabcd.ts.net/
```

### 3. Jalankan n8n

```bash
docker compose up -d
```

> Sudah punya container n8n lama? Hentikan dulu (`docker rm -f n8n`) supaya tidak
> bentrok port/nama, lalu jalankan perintah di atas. Data lamamu aman selama
> masih di volume yang sama; lihat catatan migrasi di bawah.

Cek log:

```bash
docker compose logs -f n8n
```

### 4. Akses dari iPad

1. Install app **Tailscale** di iPad → login akun yang **sama**.
2. Aktifkan Tailscale (toggle VPN-nya ON).
3. Buka Safari: `https://tanamanku.tailabcd.ts.net`

Selesai. n8n bisa diakses dari iPad di mana saja selama Tailscale aktif.

## Catatan

- **Sertifikat HTTPS error / "not secure"**: pastikan **HTTPS Certificates** &
  **MagicDNS** sudah ON di admin console Tailscale, lalu jalankan ulang
  `sudo tailscale serve --bg 5678`.
- **Tetap bisa diakses lokal**: dari laptop sendiri, `http://localhost:5678`
  tetap jalan.
- **Keamanan**: port n8n di-bind ke `127.0.0.1` saja, jadi perangkat lain di
  WiFi yang sama pun tidak bisa mengaksesnya langsung — hanya lewat tailnet.
- **Migrasi data dari container lama**: jika sebelumnya kamu pakai volume/nama
  berbeda, pindahkan/rename volume agar menunjuk ke `n8n_data` (atau sesuaikan
  nama volume di `docker-compose.yml`) supaya workflow & kredensial tetap ada.
- **Matikan akses publik sementara**: `sudo tailscale serve --bg --https=443 off`
  atau `sudo tailscale serve reset`.

## File di repo ini

| File                 | Fungsi                                                  |
| -------------------- | ------------------------------------------------------- |
| `docker-compose.yml` | Definisi service n8n (persisten, restart otomatis).     |
| `.env.example`       | Template konfigurasi — salin jadi `.env`.               |
| `setup-tailscale.sh` | Script setup Tailscale + expose n8n via HTTPS.          |
